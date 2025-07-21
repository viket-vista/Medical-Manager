import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:medicalmanager/models/settings_model.dart';
import 'package:flutter_multicast_lock/flutter_multicast_lock.dart';

class CommunicationPage extends StatefulWidget {
  const CommunicationPage({super.key});

  @override
  State<CommunicationPage> createState() => _CommunicationPageState();
}

class _CommunicationPageState extends State<CommunicationPage> {
  final int broadcastPort = 54321; // 广播端口
  late Map<String, RawDatagramSocket> _broadcastSocket;
  late List<Map<String, dynamic>> otherDevices;
  final multicastAddr = InternetAddress('224.0.0.114');
  int id = 0;
  late final settings;
  final flutterMulticastLock = FlutterMulticastLock();
  @override
  void initState() {
    super.initState();
    settings = Provider.of<SettingsModel>(context, listen: false);
    _broadcastSocket = {};
    otherDevices = [];
    _initSockets();
  }

  @override
  void dispose() {
    _broadcastSocket.forEach((key, socket) {
      socket.close();
    });
    flutterMulticastLock.releaseMulticastLock();
    super.dispose();
  }

  Future<void> _initSockets() async {
    if (Platform.isAndroid &&
        !await flutterMulticastLock.isMulticastLockHeld()) {
      print(1);
      await flutterMulticastLock.acquireMulticastLock(lockName: 'mr');
    }
    print(await flutterMulticastLock.isMulticastLockHeld());
    try {
      // 初始化广播socket
      print('正在初始化Socket...');
      try {
        final ips = await _getLocalIP();
        await Future.wait(
          ips.entries.map((ip) async {
            _broadcastSocket[ip.key] = await RawDatagramSocket.bind(
              ip.key,
              broadcastPort,
            );
            _broadcastSocket[ip.key]!.broadcastEnabled = true;
            _broadcastSocket[ip.key]!.multicastHops = 32;
            print(
              '广播Socket已绑定到: ${_broadcastSocket[ip.key]!.address.address}:${_broadcastSocket[ip.key]!.port}',
            );
            _broadcastSocket[ip.key]!.joinMulticast(multicastAddr, ip.value);

            print('Socket初始化完成');
            _broadcastSocket[ip.key]!.listen((RawSocketEvent event) {
              if (event == RawSocketEvent.read) {
                Datagram? datagram = _broadcastSocket[ip.key]!.receive();
                if (datagram != null) {
                  String response = utf8.decode(datagram.data);

                  Map<String, dynamic> data = jsonDecode(response);
                  // 如果是B设备，收到广播后发送自己的IP和端口
                  if (data['uuid'] != '${settings.uuid}') {
                    setState(() {
                      var json = jsonDecode(response);
                      json['IP'] = datagram.address.address;
                      json['port'] = datagram.port;
                      json.remove('status');
                      otherDevices.add(json);
                    });
                    print(
                      '收到来自 ${datagram.address.address}:${datagram.port} 的信息: $response',
                    );
                    if (data['id'].toString() != id.toString()) {
                      _sendResponse(
                        ip.key,
                        datagram.address,
                        datagram.port,
                        data['id'] is int ? data['id'] : int.parse(data['id']),
                      );
                    }
                  }
                }
              }
            });
          }),
        );
      } catch (e) {
        print('Socket初始化失败: $e');
      }

      // 初始化响应socket

      print('监听就绪');
    } catch (e) {
      print('初始化失败: $e');
    }
  }

  void _sendResponse(
    String localIP,
    InternetAddress address,
    int port,
    int? id,
  ) async {
    try {
      final response = jsonEncode({
        'status': 'response',
        'name': '${settings.name}',
        'uuid': '${settings.uuid}',
        id == null ? null : 'id': id,
      });
      ;
      _broadcastSocket[localIP]!.send(utf8.encode(response), address, port);
      print('已发送响应: $response');
    } catch (e) {
      print('发送响应失败: $e');
    }
  }

  void _sendBroadcast() async {
    setState(() {
      otherDevices.clear();
    });
    try {
      id = Random().nextInt(100);
      // 发送广播消息
      var msg = {
        'status': 'discover',
        'name': '${settings.name}',
        'uuid': '${settings.uuid}',
        'id': id.toString(),
      };
      _broadcastSocket.forEach((key, socket) {
        msg['localip'] = socket.address.address;
        socket.send(utf8.encode(jsonEncode(msg)), multicastAddr, broadcastPort);
        print('已发送广播消息$key,$broadcastPort');
      });

      // 监听响应
    } catch (e) {
      print('发送广播失败: $e');
    }
  }

  Future<Map<String, dynamic>> _getLocalIP() async {
    Map<String, dynamic> ip = {};
    try {
      for (var interface in await NetworkInterface.list()) {
        for (var addr in interface.addresses) {
          if (addr.type == InternetAddressType.IPv4) {
            ip[addr.address] = interface;
          }
        }
      }
      if (ip.isNotEmpty) {
        return ip;
      }
    } catch (e) {
      return {'127.0.0.1': 'null'};
    }
    return {'127.0.0.1': 'null'};
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('局域网通信示例')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            otherDevices.isNotEmpty
                ? ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: otherDevices.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                        child: Card(
                          child: ListTile(
                            title: Text('${otherDevices[index]['name']}'),
                            subtitle: Text(
                              '${otherDevices[index]['IP']}:${otherDevices[index]['port']}',
                            ),
                          ),
                        ),
                      );
                    },
                  )
                : const Text('未发现设备'),
            Center(
              child: ElevatedButton(
                onPressed: _sendBroadcast,
                child: const Text('探测设备'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
