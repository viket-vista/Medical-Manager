// ignore: file_names
// ignore_for_file: avoid_print


import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:medicalmanager/models/settings_model.dart';
import 'package:medicalmanager/modules/network_transfer.dart';
import 'package:medicalmanager/tools/json_parse.dart';
import 'dart:convert';

import 'package:medicalmanager/pages/editpage.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:medicalmanager/pages/routine_record.dart';
import 'package:medicalmanager/pages/search.dart';
import 'package:medicalmanager/tools/zip_tools.dart';

class MedicalRecordPage extends StatefulWidget {
  const MedicalRecordPage({super.key});

  @override
  State<StatefulWidget> createState() {
    return PageState();
  }
}

class PageState extends State<MedicalRecordPage> {
  List<Map<String, dynamic>> allMHEntry = [];
  late bool deletemode;
  late final SettingsModel settings;
  @override
  void initState() {
    super.initState();
    settings = Provider.of<SettingsModel>(context, listen: false);
    loaddata();
    deletemode = false;
  }

  Future<void> loaddata() async {
    try {
      final file = await _localFile;
      if (await file.exists()) {
        String contents = await file.readAsString();
        JsonParse mhjson = JsonParse(contents);
        setState(() {
          allMHEntry = List.from(mhjson.parse());
        });
      } else {
        await file.create(recursive: true);
        await file.writeAsString(json.encode([]));
        setState(() {
          allMHEntry = [];
        });
      }
    } catch (e) {
      print("Error loading data: $e");
    }
  }

  Future<Map<String, dynamic>> loaddata1([String? uuid]) async {
    if (uuid != null) {
      final directory = await getApplicationDocumentsDirectory();
      final patientMHFile = File('${directory.path}/data/$uuid.json');
      if (await patientMHFile.exists()) {
        final str = await patientMHFile.readAsString();
        return JsonParse(str).parse();
      }
    }
    // 默认初始化为空数据
    final str = await rootBundle.loadString("assets/All_MH_Entry.json");
    final js = JsonParse(str).parse();
    js["created_at"] = DateTime.now().millisecondsSinceEpoch;
    return js;
  }

  Future<File> get _localFile async {
    final directory = settings.docPath;
    return File('$directory/All_MH_Entry.json');
  }

  Future<void> writeData(List<Map<String, dynamic>> newData) async {
    final file = await _localFile;
    await file.writeAsString(json.encode(newData));
  }

  void updatedata(int index, var updatedItem) {
    setState(() {
      allMHEntry[index] = updatedItem;
    });
    writeData(allMHEntry);
  }

  void addData(dynamic newitem) {
    setState(() {
      allMHEntry.add(newitem);
    });
    writeData(allMHEntry);
  }

  Future<void> deleteItem(int index) async {
    final directory = settings.docPath;
    File("$directory/data/${allMHEntry[index]["uuid"]}.json").delete();
    Directory(
      '$directory/data/${allMHEntry[index]['uuid']}/',
    ).delete(recursive: true);
    setState(() {
      allMHEntry.removeAt(index);
    });
    writeData(allMHEntry);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("病历列表"),
        actions: [
          FutureBuilder(
            future: loaddata1(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return Row(
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.search),
                          onPressed: () {
                            showSearch(
                              context: context,
                              delegate: MedicalRecordSearchDelegate(
                                allMHEntry,
                                context,
                                (con, item) {
                                  _navigateToRecord(con, item);
                                },
                                (con, item) {
                                  _navigateToEdit(
                                    con,
                                    item,
                                    allMHEntry.indexWhere(
                                      ((element) =>
                                          element['uuid'] == item['uuid']),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    IconButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EditPage(
                              medicalRecord1: snapshot.data!,
                              onSave: (newitem) {
                                addData(newitem);
                              },
                              onDelete: () {},
                            ),
                          ),
                        );
                      },
                      icon: Icon(Icons.add),
                    ),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          deletemode = !deletemode;
                        });
                      },
                      icon: Icon(Icons.delete),
                    ),
                  ],
                );
              } else {
                return Icon(Icons.info);
              }
            },
          ),
        ],
      ),
      body: allMHEntry.isEmpty
          ? const Center(
              child: Text(
                "暂无记录",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: allMHEntry.length,
              itemBuilder: (BuildContext context, int index) {
                final item = allMHEntry[index];
                return MedicalRecordCard(
                  item: item,
                  deletemode: deletemode,
                  onTap: () => _navigateToRecord(context, item),
                  onLongPress: () => _showOptionsMenu(context, item, index),
                  onEdit: () => _navigateToEdit(context, item, index),
                  onDelete: () => deleteItem(index),
                );
              },
            ),
    );
  }

  void _navigateToRecord(BuildContext context, dynamic item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            RecordPage(uuid: item['uuid'], name: item['name']),
      ),
    );
  }

  void _showOptionsMenu(BuildContext context, dynamic item, int index) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text('详情'),
              onTap: () {
                Navigator.pop(context); // 关闭底部菜单
                _showDetailDialog(context, item);
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('编辑'),
              onTap: () {
                Navigator.pop(context); // 关闭底部菜单
                _navigateToEdit(context, item, index);
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('编辑元数据'),
              onTap: () {
                Navigator.pop(context); // 关闭底部菜单
                _navigateToEditOrigin(context, item, index);
              },
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('分享'),
              onTap: () {
                Navigator.pop(context); // 关闭底部菜单
                _shareData(item);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete),
              title: const Text('删除'),
              onTap: () {
                Navigator.pop(context); // 关闭底部菜单
                deleteItem(index);
              },
            ),
          ],
        ),
      ),
    );
  }

  // 显示详情对话框
  void _showDetailDialog(BuildContext context, dynamic item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("详情"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("标识符: ${item['uuid']}"),
              Text("姓名: ${item['name']}"),
              Text("年龄: ${item['age']}"),
              Text(
                "创建时间: ${DateTime.fromMillisecondsSinceEpoch(item['created_at']).toLocal().toString().substring(0, 23)}",
              ),
              Text(
                '最后修改时间: ${DateTime.fromMillisecondsSinceEpoch(item['last_edit_at']).toLocal().toString().substring(0, 23)}',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("关闭"),
          ),
        ],
      ),
    );
  }

  // 导航到编辑页面
  Future<void> _navigateToEdit(
    BuildContext context,
    dynamic item,
    int index,
  ) async {
    try {
      final mr = await loaddata1(item['uuid']);
      if (!context.mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EditPage(
            medicalRecord1: mr,
            item: item,
            onSave: (updatedItem) => updatedata(index, updatedItem),
            onDelete: () => deleteItem(index),
          ),
        ),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('加载数据失败: $e')));
      }
    }
  }

  Future<void> _navigateToEditOrigin(
    BuildContext context,
    dynamic item,
    int index,
  ) async {
    try {
      final mr = await loaddata1(item['uuid']);
      TextEditingController controller = TextEditingController(
        text: json.encode(mr),
      );
      if (!context.mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) {
            return Scaffold(
              appBar: AppBar(
                title: Text('编辑元数据${item["name"]}'),
                actions: [
                  IconButton(
                    onPressed: () {
                      final settings = Provider.of<SettingsModel>(
                        context,
                        listen: false,
                      );
                      final directory = settings.docPath;
                      final file = File('$directory/data/${item['uuid']}.json');
                      final jsonStr = controller.text;
                      file.writeAsString(jsonStr);
                    },
                    icon: Icon(Icons.save),
                  ),
                ],
              ),
              body: LayoutBuilder(
                builder: (context, constraints) {
                  return ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                      maxHeight: constraints.maxHeight,
                    ),
                    child: SingleChildScrollView(
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: TextField(
                            controller: controller,
                            textAlignVertical: TextAlignVertical.top,
                            maxLines: null,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('加载数据失败: $e')));
      }
    }
  }

  void _shareData(dynamic item) async {
    await compressDirectoryToZip(
      sourceDir: Directory('${settings.docPath}/data/${item['uuid']}'),
      zipFile: File('${settings.docPath}/data/${item['uuid']}.zip'),
    );
    showModalBottomSheet(
      context: context,
      builder: (context) =>
          CommunicationPage(data: {'type': 'record', 'data': jsonEncode(item)}),
    );
  }

  
}

class MedicalRecordCard extends StatelessWidget {
  final dynamic item;
  final bool deletemode;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const MedicalRecordCard({
    super.key,
    required this.item,
    required this.deletemode,
    required this.onTap,
    required this.onLongPress,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      onSecondaryTap: onLongPress,
      child: Card(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Text(
                  "姓名:${item['name'] == '' ? '无' : item['name']}\t年龄:${item['age']}",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ),
            if (deletemode)
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_rounded),
              )
            else
              IconButton(onPressed: onEdit, icon: const Icon(Icons.info)),
          ],
        ),
      ),
    );
  }
}
