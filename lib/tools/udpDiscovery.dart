import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:medicalmanager/models/settings_model.dart';
import 'package:medicalmanager/tools/tcpDataTransfer.dart';

class UdpDiscoveryService {
  static final int broadcastPort = 54321;
  static final InternetAddress multicastAddr = InternetAddress('224.0.0.114');
  late RawDatagramSocket _socket;
  final SettingsModel settings;
  final Function(Map<String, dynamic>) onDeviceDiscovered;

  UdpDiscoveryService({
    required this.settings,
    required this.onDeviceDiscovered,
  });

  Future<void> init() async {
    try {
      // 绑定到所有IPv4接口
      _socket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        broadcastPort,
      );

      _socket.broadcastEnabled = true;
      _socket.multicastHops = 32;
      _socket.joinMulticast(multicastAddr);

      print('UDP服务已启动，监听端口: $broadcastPort');

      _socket.listen((RawSocketEvent event) {
        if (event == RawSocketEvent.read) {
          final datagram = _socket.receive();
          if (datagram != null) {
            _handleIncomingPacket(datagram);
          }
        }
      });
    } catch (e) {
      print('UDP初始化失败: $e');
      rethrow;
    }
  }

  void _handleIncomingPacket(Datagram datagram) {
    try {
      final data = jsonDecode(utf8.decode(datagram.data));
      if (data['uuid'] != settings.uuid) {
        final Map<String, dynamic> deviceInfo = {
          ...data,
          'ip': datagram.address.address,
          'port': datagram.port,
        };
        onDeviceDiscovered(deviceInfo);

        // 自动响应发现请求
        if (data['status'] == 'discover') {
          _sendResponse(datagram.address, datagram.port, data['id']);
        }
      }
    } catch (e) {
      print('数据包解析错误: $e');
    }
  }

  void _sendResponse(InternetAddress address, int port, int id) {
    final response = jsonEncode({
      'status': 'response',
      'name': settings.name,
      'uuid': settings.uuid,
      'id': id,
      'tcp_port': TcpFileTransfer.defaultPort,
    });
    _socket.send(utf8.encode(response), address, port);
  }

  void broadcastDiscovery() {
    final msg = jsonEncode({
      'status': 'discover',
      'name': settings.name,
      'uuid': settings.uuid,
      'id': Random().nextInt(100),
      'tcp_port': TcpFileTransfer.defaultPort,
    });
    _socket.send(utf8.encode(msg), multicastAddr, broadcastPort);
  }

  void dispose() {
    _socket.close();
  }
}
