// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:medicalmanager/models/settings_model.dart';
import 'package:medicalmanager/tools/tcp_data_transfer.dart';
import 'package:medicalmanager/models/udp_discovery_state.dart';
import 'package:logger/logger.dart';

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
      _socket.joinMulticast(InternetAddress('226.123.112.23'));

      Logger().i('UDP服务已启动,监听端口: $broadcastPort');

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
      Logger().e('UDP服务启动失败: $e');
    }
  }

  void _handleIncomingPacket(Datagram datagram) {
    try {
      final data = jsonDecode(utf8.decode(datagram.data));
      if (data['uuid'] != settings.uuid&&onDeviceDiscovered.devices.indexWhere((element) => element['uuid'] == data['uuid']) == -1) {
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
      Logger().e('处理UDP数据包失败: $e');
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
    _socket.send(utf8.encode(response), InternetAddress('255.255.255.255'), broadcastPort);
    _socket.send(utf8.encode(response), address, port);
    Logger().i('发送响应到${address.address}:$port: $response');
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
    Logger().i('发送广播: $msg');
  }

  void dispose() {
    _socket.close();
  }
}
