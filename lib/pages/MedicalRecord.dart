// ignore: file_names
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:medicalmanager/models/settings_model.dart';
import 'package:medicalmanager/tools/JsonParse.dart';
import 'dart:convert';

import 'package:medicalmanager/pages/editpage.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:medicalmanager/pages/record.dart';

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
  @override
  void initState() {
    super.initState();
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
    final settings = Provider.of<SettingsModel>(context, listen: false);
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

  void addData(var newitem) {
    setState(() {
      allMHEntry.add(newitem);
    });
    writeData(allMHEntry);
  }

  Future<void> deleteItem(int index) async {
    final settings = Provider.of<SettingsModel>(context, listen: false);
    final directory = settings.docPath;
    File("$directory/data/${allMHEntry[index]["uuid"]}.json").delete();
    Directory('$directory/data/${allMHEntry[index]['uuid']}/').delete();
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
      body: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: allMHEntry.isEmpty ? 1 : allMHEntry.length,
        itemBuilder: (BuildContext context, int index) {
          dynamic item;
          if (allMHEntry.isNotEmpty) {
            item = allMHEntry[index];
            return GestureDetector(
              onTap: () async {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RecordPage(uuid: item['uuid'],name: item['name'],),
                  ),
                );
              },
              child: Card(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Text(
                          "姓名:${item['name']} 年龄:${item['age']} 创建时间:${DateTime.fromMillisecondsSinceEpoch(item['created_at'])}",
                          style: TextStyle(
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
                        onPressed: () {
                          deleteItem(index);
                        },
                        icon: Icon(Icons.delete_rounded),
                      ),
                    if (!deletemode)
                      IconButton(
                        onPressed: () async {
                          Map<String, dynamic> mr = await loaddata1(
                            item['uuid'],
                          );
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EditPage(
                                medicalRecord1: mr,
                                item: item,
                                onSave: (updatedItem) {
                                  updatedata(index, updatedItem);
                                },
                                onDelete: () {
                                  deleteItem(index);
                                },
                              ),
                            ),
                          );
                        },
                        icon: Icon(Icons.info),
                      ),
                  ],
                ),
              ),
            );
          } else {
            return Center(
              child: Text(
                "暂无记录",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            );
          }
        },
      ),
    );
  }
}
