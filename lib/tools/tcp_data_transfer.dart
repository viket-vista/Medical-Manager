import 'dart:convert';
import 'dart:io';

class TcpFileTransfer {
  static const int defaultPort = 54322;
  ServerSocket? _server;
  final _connections = <Socket>[];

  Future<ServerSocket> startServer() async {
    return await ServerSocket.bind(InternetAddress.anyIPv4, defaultPort);
  }

  // 连接到对端
  Future<Socket> connect(String ip, ) async {
    return await Socket.connect(ip, defaultPort, timeout: Duration(seconds: 5));
  }

  Future<void> sendFile(Socket socket, File file) async {
    final fileSize = await file.length();
    final stream = file.openRead();

    // 发送文件头信息
    socket.add(
      utf8.encode(
        jsonEncode({
          'filename': file.path.split('/').last,
          'size': fileSize,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        }),
      ),
    );
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

}
