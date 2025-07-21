import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:medicalmanager/models/settings_model.dart';
import 'package:medicalmanager/tools/tcp_data_transfer.dart';
import 'package:medicalmanager/models/udp_discovery_state.dart';

class UdpDiscoveryService {
  static final int broadcastPort = 54321;
  late RawDatagramSocket _socket;
  final SettingsModel settings;
  final DiscoveryState onDeviceDiscovered ;
  int id = 0;

  UdpDiscoveryService({
    required this.settings,
    required this.onDeviceDiscovered,
  });

  Future<void> init() async {
    try {
      onDeviceDiscovered.setInitializing(true);
      // 绑定到所有IPv4接口
      _socket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        broadcastPort,
      );

      _socket.broadcastEnabled = true;
      _socket.multicastHops = 32;

      print('UDP服务已启动，监听端口: $broadcastPort');

      _socket.listen((RawSocketEvent event) {
        if (event == RawSocketEvent.read) {
          final datagram = _socket.receive();
          if (datagram != null) {
            _handleIncomingPacket(datagram);
          }
        }
      });
      onDeviceDiscovered.setInitializing(false);
    } catch (e) {
      print('UDP初始化失败: $e');
      rethrow;
    }
  }

  void _handleIncomingPacket(Datagram datagram) {
    try {
      final data = jsonDecode(utf8.decode(datagram.data));
      if (data['uuid'] != settings.uuid) {
        if(id != (data['id'] is int?data['id']:int.parse(data['id']))){
          id = (data['id'] is int?data['id']:int.parse(data['id']));
          onDeviceDiscovered.clearDevices();
        }
        final Map<String, dynamic> deviceInfo = {
          ...data,
          'ip': datagram.address.address,
          'port': datagram.port,
        };
        onDeviceDiscovered.addDevice(deviceInfo);

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
    _socket.send(utf8.encode(response), InternetAddress('255.255.255.255'), port);
  }

  void broadcastDiscovery() {
    id =  Random().nextInt(100);
    onDeviceDiscovered.clearDevices();
    final msg = jsonEncode({
      'status': 'discover',
      'name': settings.name,
      'uuid': settings.uuid,
      'id': id,
      'tcp_port': TcpFileTransfer.defaultPort,
    });
    _socket.send(utf8.encode(msg), InternetAddress('255.255.255.255'), broadcastPort);
  }

  void dispose() {
    _socket.close();
  }
}
