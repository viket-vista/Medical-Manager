import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:medicalmanager/models/settings_model.dart';
import 'package:medicalmanager/models/udp_discovery_state.dart';
import 'package:medicalmanager/tools/udp_discovery.dart';

class CommunicationPage extends StatefulWidget {
  const CommunicationPage({super.key});

  @override
  State<CommunicationPage> createState() => _CommunicationPageState();
}

class _CommunicationPageState extends State<CommunicationPage> {
  final int broadcastPort = 54321; // 广播端口
  late UdpDiscoveryService udpService;
  late DiscoveryState state;
  int id = 0;
  late final settings;
  @override
  void initState() {
    super.initState();
    udpService = Provider.of<UdpDiscoveryService>(context, listen: false);
    settings = Provider.of<SettingsModel>(context, listen: false);
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    state = Provider.of<DiscoveryState>(context, listen: true);
    return AlertDialog(
      title: const Text('选择设备'),
      content: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SizedBox(
          height: 316,
          width: 316,
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
                  : GridView.builder(
                      shrinkWrap: true,
                      itemCount: state.devices.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3, // 3列，形成九宫格
                            childAspectRatio: 1, // 正方形格子
                            mainAxisSpacing: 8, // 垂直间距
                            crossAxisSpacing: 8, // 水平间距
                          ),
                      itemBuilder: (context, index) {
                        return InkWell(
                          child: Card(
                            child: SizedBox(
                              height: 100,
                              width: 100,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Icon(Icons.router, size: 40),
                                  Text('${state.devices[index]['name']}'),
                                  Text(
                                    '${state.devices[index]['ip']}:${state.devices[index]['port']}',
                                    style: TextStyle(fontSize: 8),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          onTap: () {
                            print(state.devices[index]['name']);
                          },
                        );
                      },
                    );
            },
          ),
        ),
      ),
      actions: [
        ElevatedButton(
          onPressed: udpService.broadcastDiscovery,
          child: const Text('探测设备'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: Text('取消'),
        ),
      ],
    );
    // return Scaffold(
    //   appBar: AppBar(title: const Text('局域网通信示例')),
    //   body: Padding(
    //     padding: const EdgeInsets.all(16.0),
    //     child: Column(
    //       crossAxisAlignment: CrossAxisAlignment.start,
    //       children: [
    //         Consumer<DiscoveryState>(
    //           builder: (context, state, child) {
    //             if (state.isInitializing) {
    //               return Center(child: CircularProgressIndicator());
    //             }

    //             if (state.error != null) {
    //               return Center(child: Text('错误: ${state.error}'));
    //             }

    //             return state.devices.isEmpty
    //                 ? Center(child: Text('未发现设备'))
    //                 : ListView.builder(
    //                     shrinkWrap: true,
    //                     itemCount: state.devices.length,
    //                     itemBuilder: (context, index) {
    //                       return Padding(
    //                         padding: const EdgeInsets.only(
    //                           top: 8.0,
    //                           bottom: 8.0,
    //                         ),
    //                         child: Card(
    //                           child: ListTile(
    //                             leading: Icon(Icons.router),
    //                             title: Text('${state.devices[index]['name']}'),
    //                             subtitle: Text(
    //                               '${state.devices[index]['ip']}:${state.devices[index]['port']}',
    //                             ),
    //                           ),
    //                         ),
    //                       );
    //                     },
    //                   );
    //           },
    //         ),
    //       ],
    //     ),
    //   ),
    //   floatingActionButton: ElevatedButton(
    //     onPressed: udpService.broadcastDiscovery,
    //     child: const Text('探测设备'),
    //   ),
    //   floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    // );
  }
}
