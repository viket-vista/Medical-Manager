import 'dart:io';
import 'package:flutter/material.dart';
import 'package:logger/web.dart';
import 'package:provider/provider.dart';
import 'package:medicalmanager/models/settings_model.dart';
import 'package:medicalmanager/models/udp_discovery_state.dart';
import 'package:medicalmanager/tools/udp_discovery.dart';
import 'package:medicalmanager/tools/tcp_data_transfer.dart';

class CommunicationPage extends StatefulWidget {
  final dynamic data;
  const CommunicationPage({super.key, required this.data});

  @override
  State<CommunicationPage> createState() => _CommunicationPageState();
}

class _CommunicationPageState extends State<CommunicationPage> {
  final int broadcastPort = 54321; // 广播端口
  late UdpDiscoveryService udpService;
  late DiscoveryState state;
  late TcpFileTransfer tcpFileTransfer;
  int id = 0;
  late final SettingsModel settings;
  @override
  void initState() {
    super.initState();
    udpService = Provider.of<UdpDiscoveryService>(context, listen: false);
    tcpFileTransfer = Provider.of<TcpFileTransfer>(context, listen: false);
    settings = Provider.of<SettingsModel>(context, listen: false);
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    state = Provider.of<DiscoveryState>(context, listen: true);
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.8,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '选择设备',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        TextEditingController textController =
                            TextEditingController();
                        showDialog(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              title: Text('输入IP地址'),
                              content: TextField(
                                decoration: InputDecoration(
                                  hintText: 'xxx.xxx.xxx.xxx',
                                  border: OutlineInputBorder(),
                                ),
                                controller: textController,
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                  child: Text('取消'),
                                ),
                                TextButton(
                                  onPressed: () async {
                                    try {
                                      final socket = await tcpFileTransfer
                                          .connect(textController.text);
                                      if (widget.data['type'] == 'file') {
                                        Logger().i('send file');
                                        await tcpFileTransfer.sendFile(
                                          socket,
                                          widget.data,
                                        );
                                      } else if (widget.data['type'] ==
                                          'text') {
                                        Logger().i('send text');
                                        await tcpFileTransfer.sendString(
                                          socket,
                                          widget.data['str'],
                                        );
                                      } else if (widget.data['type'] ==
                                          'record') {
                                        Logger().i('send record');
                                        await tcpFileTransfer.sendRecord(
                                          socket,
                                          widget.data,
                                        );
                                      } else {
                                        Logger().e(
                                          'error type, please check, type: ${widget.data['type']}',
                                        );
                                      }
                                      tcpFileTransfer.disconnect(socket);
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text('success'),
                                          duration: const Duration(seconds: 2),
                                        ),
                                      );
                                    } catch (e) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(content: Text('error:$e')),
                                      );
                                    }
                                    Navigator.pop(context);
                                  },
                                  child: Text('确定'),
                                ),
                              ],
                            );
                          },
                        );
                      },
                      icon: const Icon(Icons.search),
                    ),
                    IconButton(
                      onPressed: udpService.broadcastDiscovery,
                      icon: const Icon(Icons.refresh),
                    ),
                    IconButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Consumer<DiscoveryState>(
                builder: (context, state, child) {
                  if (state.isInitializing) {
                    return Center(child: CircularProgressIndicator());
                  }

                  if (state.error != null) {
                    return Center(child: Text('错误: ${state.error}'));
                  }

                  return state.devices.isEmpty
                      ? Center(child: Text('未发现设备'))
                      : ListView.builder(
                          shrinkWrap: true,
                          itemCount: state.devices.length,
                          itemBuilder: (context, index) {
                            return ListTile(
                              leading: Icon(Icons.router),
                              title: Text('${state.devices[index]['name']}'),
                              subtitle: Text('${state.devices[index]['ip']}'),
                              onTap: () async {
                                try {
                                  final socket = await tcpFileTransfer.connect(
                                    state.devices[index]['ip'],
                                  );
                                  if (widget.data['type'] == 'file') {
                                    Logger().i('send file');
                                    await tcpFileTransfer.sendFile(
                                      socket,
                                      widget.data,
                                    );
                                  } else if (widget.data['type'] == 'text') {
                                    Logger().i('send text');
                                    await tcpFileTransfer.sendString(
                                      socket,
                                      widget.data['data'],
                                    );
                                  } else if (widget.data['type'] == 'record') {
                                    Logger().i('send record');
                                    await tcpFileTransfer.sendRecord(
                                      socket,
                                      widget.data,
                                    );
                                  } else {
                                    Logger().e(
                                      'error type, please check, type: ${widget.data['type']}',
                                    );
                                  }
                                  tcpFileTransfer.disconnect(socket);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('success'),
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('error:$e')),
                                  );
                                }
                              },
                            );
                          },
                        );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
