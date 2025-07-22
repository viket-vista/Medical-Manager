import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';
import 'package:flutter/material.dart';
import 'package:medicalmanager/models/global.dart' as globals;
import 'package:medicalmanager/models/settings_model.dart';
import 'package:medicalmanager/tools/json_parse.dart';
import 'package:medicalmanager/tools/zip_tools.dart';
import 'package:path/path.dart' show path;
import 'package:provider/provider.dart';

enum ReadPhase { header, json, content, done }

enum RecordState { header, record, archive, done }

class TcpFileTransfer with ChangeNotifier {
  static const int defaultPort = 54322;
  ServerSocket? _server;
  final _connections = <Socket>[];
  bool _isIncomingConnection = false;
  bool get isIncomingConnection => _isIncomingConnection;
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  late SettingsModel settings;
  Future<ServerSocket> startServer() async {
    try {
      _server = await ServerSocket.bind(InternetAddress.anyIPv4, defaultPort);
      _server!.listen((Socket socket) async {
        _isIncomingConnection = true;
        notifyListeners();
        if (globals.navigatorKey.currentState?.mounted ?? false) {
          // 在这里可以弹出对话框
          _showIncomingConnectionDialog(socket);
        }

        _connections.add(socket);
        socket.done.then((_) => _connections.remove(socket));
      });
    } catch (e) {
      Logger().e(e);
    }
    return _server!;
  }

  void initializeSettings(BuildContext context) {
    settings = Provider.of<SettingsModel>(context, listen: false);
  }

  void _showIncomingConnectionDialog(Socket socket) {
    notifyListeners();

    showDialog(
      context: globals.navigatorKey.currentContext!,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('新的连接请求'),
        content: Text('检测到来自 ${socket.remoteAddress.address} 的连接请求'),
        actions: [
          TextButton(
            child: Text('拒绝'),
            onPressed: () {
              socket.close();
              Navigator.of(context).pop();
            },
          ),
          TextButton(
            child: Text('接受'),
            onPressed: () async {
              Navigator.of(context).pop();
              handleSocketData(socket);
            },
          ),
        ],
      ),
    );
  }

  Future<void> disconnect(Socket socket) async {
    try {
      await socket.flush(); // 确保所有数据已发送
      await socket.close(); // 关闭连接
      _connections.remove(socket); // 从连接列表中移除
      Logger().i('已成功断开连接');
    } catch (e) {
      Logger().e('断开连接时出错: $e');
      rethrow;
    } finally {
      notifyListeners();
    }
  }

  Future<void> sendString(Socket socket, String message) async {
    try {
      final msgByteCode = utf8.encode(message);
      // 添加消息头标识这是字符串类型
      final header = jsonEncode({
        'type': 'text', // 标识数据类型
        'length': msgByteCode.length,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
      final bytes = utf8.encode(header);
      final headerLenth = Uint8List(4);
      ByteData.view(headerLenth.buffer).setUint32(0, bytes.length, Endian.big);
      // 先发送消息头
      socket.add(headerLenth);
      socket.add(utf8.encode(header));
      await socket.flush();

      // 发送实际字符串内容
      socket.add(msgByteCode);
      await socket.flush();
      socket.add(utf8.encode('EOF'));

      Logger().i('字符串发送成功: ${message.length}字节');
    } catch (e) {
      Logger().e('发送字符串失败: $e');
      rethrow;
    }
  }

  // 连接到对端
  Future<Socket> connect(String ip) async {
    try {
      return await Socket.connect(
        ip,
        defaultPort,
        timeout: Duration(seconds: 5),
      );
    } catch (e) {
      Logger().e('连接失败: $e');
      rethrow;
    }
  }

  Future<void> sendFile(Socket socket, dynamic data) async {
    File file = File(data['data']);
    final stream = file.openRead();
    final bytes = utf8.encode(jsonEncode(data));
    final headerLength = Uint8List(4);
    ByteData.view(headerLength.buffer).setUint32(0, bytes.length, Endian.big);
    socket.add(headerLength);
    await socket.flush();
    // 发送文件头信息
    socket.add(bytes);
    await socket.flush();

    // 分块传输
    await for (final chunk in stream) {
      socket.add(chunk);
      await socket.flush(); // 确保每块都发送完成
    }
  }

  void dispose() {
    _connections.forEach((c) => c.close());
    _server?.close();
  }

  Future<void> sendRecord(Socket socket, dynamic data) async {
    String header = data['data'];
    dynamic headerData = jsonDecode(header);
    final headerBytes = utf8.encode(header);

    String recordFile = await File(
      '${settings.docPath}/data/${headerData['uuid']}.json',
    ).readAsString();
    final recordBytes = utf8.encode(recordFile);

    File recordArchiveFile = File(
      '${settings.docPath}/data/${headerData['uuid']}.zip',
    );
    final stream = recordArchiveFile.openRead();
    final recordArchiveLength = recordArchiveFile.statSync().size;
    final allHeader = jsonEncode({
      'type': 'record',
      'header': headerBytes.length,
      'record': recordBytes.length,
      'recordArchive': recordArchiveLength,
      'uuid': headerData['uuid'],
    });
    final allHeaderBytes = utf8.encode(allHeader);
    final allHeaderLength = Uint8List(4);
    ByteData.view(
      allHeaderLength.buffer,
    ).setUint32(0, allHeaderBytes.length, Endian.big);
    Logger().i('发送记录: ${headerData['uuid']}');
    socket.add(allHeaderLength);
    await socket.flush();
    // 发送文件头信息
    socket.add(allHeaderBytes);
    await socket.flush();
    socket.add(headerBytes);
    await socket.flush();
    socket.add(recordBytes);
    await socket.flush();
    // 分块传输
    await for (final chunk in stream) {
      socket.add(chunk);
      await socket.flush(); // 确保每块都发送完成
    }
    Logger().i('发送完成');
  }

  Future<void> receiveFile(Socket socket, String savePath) async {
    final data = await socket.first; // 读取文件头
    final header = jsonDecode(utf8.decode(data));
    final file = File('$savePath/${header['filename']}');
    final sink = file.openWrite();

    // 接收数据块
    await socket
        .listen((chunk) => sink.add(chunk), onDone: () => sink.close())
        .asFuture();
  }

  Future<void> handleSocketData(Socket socket) async {
    var phase = ReadPhase.header;
    var state = RecordState.header;
    var expectedLength = 0;
    final buffer = <int>[];
    late StreamSubscription<List<int>> subscription;
    late final dynamic json;
    bool saparatly = false;

    Logger().i('开始处理数据');
    subscription = socket.listen(
      (data) async {
        try {
          buffer.addAll(data);
          while ((buffer.length >= expectedLength ||
                  (phase == ReadPhase.header && buffer.length >= 4)) &&
              phase != ReadPhase.done) {
            switch (phase) {
              case ReadPhase.header:
                if (buffer.length >= 4) {
                  final header = Uint8List.fromList(buffer.sublist(0, 4));
                  buffer.removeRange(0, 4);
                  expectedLength = ByteData.sublistView(
                    header,
                  ).getUint32(0, Endian.big);
                  phase = ReadPhase.json;
                  Logger().i('header length: $expectedLength');
                }
                break;
              case ReadPhase.json:
                if (buffer.length >= expectedLength) {
                  final jsonBytes = Uint8List.fromList(
                    buffer.sublist(0, expectedLength),
                  );
                  buffer.removeRange(0, expectedLength);
                  json = jsonDecode(utf8.decode(jsonBytes));
                  Logger().i('header: ${jsonEncode(json)}');
                  if (json['type'] == 'record') {
                    expectedLength = json['header'] as int;
                  } else {
                    expectedLength = json['length'] as int;
                  }
                  phase = ReadPhase.content;
                  // 这里可以提前处理json元数据
                }
                break;

              case ReadPhase.content:
                if (buffer.length >= expectedLength) {
                  final contentBytes = Uint8List.fromList(
                    buffer.sublist(0, expectedLength),
                  );
                  buffer.removeRange(0, expectedLength);

                  // 根据json['type']处理内容
                  if (json['type'] == 'text') {
                    final content = utf8.decode(
                      contentBytes,
                      allowMalformed: true,
                    );
                    showMessageDialog(
                      globals.navigatorKey.currentState!.context,
                      content,
                    );
                  } else if (json['type'] == 'file') {
                    final file = File('${settings.docPath}/${json['topath']}');
                    file.writeAsBytesSync(contentBytes);
                    Logger().i('Received file (${contentBytes.length} bytes)');
                  } else if (json['type'] == 'record') {
                    Logger().i('Receiving record');
                    saparatly = true;
                    switch (state) {
                      case RecordState.header:
                        final header = jsonDecode(utf8.decode(contentBytes));
                        List<Map<String, dynamic>> allMHEntry = [];
                        final file = File(
                          '${settings.docPath}/All_MH_Entry.json',
                        );
                        if (file.existsSync()) {
                          String contents = file.readAsStringSync();
                          JsonParse mhjson = JsonParse(contents);
                          allMHEntry = List.from(mhjson.parse());
                        } else {
                          file.createSync(recursive: true);
                          allMHEntry = [];
                        }
                        allMHEntry.removeWhere(
                          (item) => item['uuid'] == header['uuid'],
                        );
                        allMHEntry.add(header);
                        file.writeAsStringSync(jsonEncode(allMHEntry));
                        expectedLength = json['record'] as int;
                        state = RecordState.record;
                        Logger().i('received header');
                        break;
                      case RecordState.record:
                        final record = utf8.decode(contentBytes);
                        File rFile = File(
                          '${settings.docPath}/${json['uuid']}.json',
                        );
                        rFile.writeAsStringSync(record);
                        expectedLength = json['recordArchive'] as int;
                        state = RecordState.archive;
                        Logger().i('received record');
                        break;
                      case RecordState.archive:
                        state = RecordState.done;
                        decompressZipToDirectory(
                          contentBytes: contentBytes,
                          desDir: Directory(
                            '${settings.docPath}/data/${json['uuid']}/',
                          ),
                        );
                        Logger().i('received archive');
                        break;
                      case RecordState.done:
                        break;
                    }
                  }
                  if (buffer.length > 1024) {
                    // 适当阈值
                    await Future.delayed(Duration.zero);
                  }
                  // 重置状态，准备读取下一条消息
                  if (state == RecordState.done || !saparatly) {
                    phase = ReadPhase.done;
                    expectedLength = 0;
                  }
                }
                break;
              default:
                break;
            }
          }
        } catch (e) {
          subscription.cancel();
          subscription.cancel();
          Logger().e('Error processing data: $e');
        }
      },
      onError: (error) {
        Logger().e('Socket error: $error');
        subscription.cancel();
        subscription.cancel();
      },
      onDone: () {
        Logger().i('Socket closed');
        subscription.cancel();
        disconnect(socket);
      },
      cancelOnError: true,
    );
  }

  void showMessageDialog(BuildContext context, String text) {
    final TextEditingController _controller = TextEditingController(text: text);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('收到一个消息'),
          content: TextField(
            controller: _controller,
            decoration: const InputDecoration(border: OutlineInputBorder()),
            maxLines: null,
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('复制'),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: _controller.text));
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('已复制到剪贴板')));
              },
            ),
            TextButton(
              child: const Text('关闭'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
