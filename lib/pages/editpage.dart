// ignore_for_file: prefer_if_null_operators

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:medicalmanager/pages/MedicalRecord.dart';
import 'package:medicalmanager/tools/JsonParse.dart';
import 'package:medicalmanager/tools/JsonChange.dart';
import 'package:medicalmanager/tools/asyncBuildWidget.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/services.dart' show FilteringTextInputFormatter;
import 'package:crypto/crypto.dart';

class EditPage extends StatefulWidget {
  final Map<String, dynamic>? item;
  final Function(Map<String, dynamic>) onSave;
  final VoidCallback onDelete;
  final Map<String, dynamic> medicalRecord1;

  const EditPage({
    required this.medicalRecord1,
    super.key,
    this.item,
    required this.onSave,
    required this.onDelete,
  });

  @override
  State<EditPage> createState() => _EditPageState();
}

class _EditPageState extends State<EditPage> {
  late int now;
  late String uuid;
  Map<dynamic, List<dynamic>> array = {};
  Map<dynamic, List<dynamic>> array1 = {};
  late Map<String, dynamic> MedicalRecord;
  TextEditingController name = TextEditingController();
  TextEditingController age = TextEditingController();
  TextEditingController zhusu = TextEditingController();
  TextEditingController dabian = TextEditingController();
  TextEditingController xiaobian = TextEditingController();
  TextEditingController tizhong = TextEditingController();
  TextEditingController shuimian = TextEditingController();
  List<dynamic> Zhengzhuang = [];
  late List<Widget> jiwangshi;
  late List<Widget> gerenshi;
  late List<bool> _switch;
  late List<Widget> hunyushi;
  late List<Widget> jiazushi;
  late List<Widget> fucha;
  late bool zzremovemode, fcremovemode;
  @override
  void initState() {
    super.initState();
    MedicalRecord = widget.medicalRecord1;
    now = DateTime.now().millisecondsSinceEpoch;
    if (widget.item != null && widget.item!['uuid'] != null) {
      uuid = widget.item!['uuid'];
    } else {
      uuid = sha256.convert([now]).toString();
    }
    name.text = MedicalRecord['name'];
    age.text = MedicalRecord['age'];
    zhusu.text = MedicalRecord['主诉'];
    zzremovemode = false;
    buildZhengzhuang();
    jiwangshi = [];
    buildjiwangshi();
    gerenshi = [];
    _switch = [];
    buildgerenshi();
    hunyushi = [];
    buildhunyushi();
    jiazushi = [];
    buildjiazushi();
    fcremovemode = false;
    fucha = [];
    buildfucha();
  }

  @override
  void dispose() {
    name.dispose();
    age.dispose();
    zhusu.dispose();
    dabian.dispose();
    xiaobian.dispose();
    tizhong.dispose();
    shuimian.dispose();
    for (var controllers in array.entries) {
      controllers.key.dispose();
    }
    for (var controllers in array1.entries) {
      controllers.key.dispose();
    }
    super.dispose();
  }

  void saveData() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/data/$uuid.json');
    final jsonStr = jsonEncode(MedicalRecord);
    Map<String, dynamic> returnjson = {};
    returnjson["name"] = MedicalRecord["name"];
    returnjson["age"] = MedicalRecord["age"];
    returnjson["created_at"] = MedicalRecord["created_at"];
    returnjson["last_edit_at"] = DateTime.now().millisecondsSinceEpoch;
    returnjson["uuid"] = uuid;
    await file.writeAsString(jsonStr);
    widget.onSave(returnjson);
    Navigator.pop(context);
  }

  Widget buildExpandTextEdit(var controller, String text, var onChanged) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(labelText: text),
      onChanged: onChanged,
    );
  }

  Widget buildBasicInfo() {
    Widget NAME = buildExpandTextEdit(
      name,
      '姓名',
      (value) => MedicalRecord['name'] = value,
    );
    final List<String> items = ['男', '女', '其他', '未知'];
    DropdownButton dp = DropdownButton<String>(
      style: TextStyle(fontSize: 16, color: Colors.black),
      value: MedicalRecord["sex"] == "" ? "未知" : MedicalRecord["sex"],
      icon: Icon(Icons.arrow_drop_down),
      onChanged: (String? newValue) {
        setState(() {
          MedicalRecord["sex"] = newValue!;
          hunyushi.clear();
          buildhunyushi();
        });
      },
      items: items.map<DropdownMenuItem<String>>((String value) {
        return DropdownMenuItem<String>(value: value, child: Text(value));
      }).toList(),
    );
    Widget AGE = buildExpandTextEdit(
      age,
      '年龄',
      (value) => MedicalRecord['age'] = value,
    );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Flexible(child: NAME),
            SizedBox(width: 16),
            SizedBox(
              width: 100,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("性别", style: TextStyle(fontSize: 12)),
                  dp,
                ],
              ),
            ),
            SizedBox(width: 16),
            Flexible(child: AGE),
          ],
        ),
      ),
    );
  }

  Widget buildZhusu() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: buildExpandTextEdit(
                zhusu,
                '主诉',
                (value) => MedicalRecord['主诉'] = value,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildXianbingshi() {
    dabian.text = MedicalRecord['现病史']['一般情况']['大便'];
    xiaobian.text = MedicalRecord['现病史']['一般情况']['小便'];
    shuimian.text = MedicalRecord['现病史']['一般情况']['精神'];
    tizhong.text = MedicalRecord['现病史']['一般情况']['体重'];

    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        SizedBox(height: 16),
        Text("现病史"),
        SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                ExpansionTile(
                  title: Row(
                    children: [
                      Text('症状'),
                      Spacer(),
                      IconButton(
                        onPressed: () {
                          addzz();
                        },
                        icon: Icon(Icons.add),
                      ),
                      IconButton(
                        onPressed: () {
                          setState(() {
                            zzremovemode = !zzremovemode;
                            Zhengzhuang.clear();
                            buildZhengzhuang();
                          });
                        },
                        icon: Icon(Icons.remove),
                      ),
                    ],
                  ),
                  children: [...Zhengzhuang],
                ),
                Divider(),
                SizedBox(height: 4),
                Padding(
                  padding: EdgeInsets.all(16),
                  child: buildExpandTextEdit(dabian, '大便', (value) {
                    MedicalRecord = JsonChange(
                      ["现病史", '一般情况', '大便'],
                      MedicalRecord,
                      value == '' ? '无异常' : value,
                    );
                  }),
                ),
                Padding(
                  padding: EdgeInsets.all(16),
                  child: buildExpandTextEdit(xiaobian, '小便', (value) {
                    MedicalRecord = JsonChange(
                      ["现病史", '一般情况', '小便'],
                      MedicalRecord,
                      value == '' ? '无异常' : value,
                    );
                  }),
                ),
                Padding(
                  padding: EdgeInsets.all(16),
                  child: buildExpandTextEdit(shuimian, '精神', (value) {
                    MedicalRecord = JsonChange(
                      ["现病史", '一般情况', '精神'],
                      MedicalRecord,
                      value == '' ? '无异常' : value,
                    );
                  }),
                ),
                Padding(
                  padding: EdgeInsets.all(16),
                  child: buildExpandTextEdit(tizhong, '体重', (value) {
                    MedicalRecord = JsonChange(
                      ["现病史", '一般情况', '体重'],
                      MedicalRecord,
                      value == '' ? '无异常' : value,
                    );
                  }),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void addzz() {
    setState(() {
      int number = Zhengzhuang.length;
      List<TextEditingController> zz = List.generate(
        8,
        (_) => TextEditingController(),
      );
      List<String> menu = [
        '名字',
        '开始时间',
        '持续时间',
        '频率',
        '程度',
        '类型',
        '伴随症状',
        '其他',
      ];
      for (int j = 0; j <= 7; j++) {
        array[zz[j]] = ['现病史', '症状', number, menu[j]];
        MedicalRecord = JsonAdd(
          ['现病史', '症状', number, menu[j]],
          MedicalRecord,
          '',
        );
        zz[j].text = '';
      }
      Zhengzhuang.add(
        ExpansionTile(
          title: Row(
            children: [
              Text('症状'),
              Spacer(),
              if (zzremovemode)
                IconButton(
                  onPressed: () {
                    MedicalRecord = JsonDel([
                      '现病史',
                      '症状',
                      number,
                    ], MedicalRecord);
                    setState(() {
                      Zhengzhuang.clear();
                      buildZhengzhuang();
                    });
                  },
                  icon: Icon(Icons.remove),
                ),
            ],
          ),
          children: [
            for (int j = 0; j <= 7; j++)
              Padding(
                padding: EdgeInsets.all(20),
                child: TextField(
                  controller: zz[j],
                  decoration: InputDecoration(labelText: menu[j]),
                  onChanged: (value) {
                    MedicalRecord = JsonChange(
                      ['现病史', '症状', number, menu[j]],
                      MedicalRecord,
                      value,
                    );
                  },
                ),
              ),
          ],
        ),
      );
    });
  }

  void buildZhengzhuang() {
    for (int i = 0; i < MedicalRecord["现病史"]['症状'].length; i++) {
      List<TextEditingController> zz = List.generate(
        8,
        (_) => TextEditingController(),
      );
      List<String> menu = [
        '名字',
        '开始时间',
        '持续时间',
        '频率',
        '程度',
        '类型',
        '伴随症状',
        '其他',
      ];
      for (int j = 0; j <= 6; j++) {
        zz[j].text = MedicalRecord['现病史']['症状'][i][menu[j]];
        array[zz[j]] = ['现病史', '症状', i, menu[j]];
      }
      zz[7].text = MedicalRecord["现病史"]['症状'][i]['其他'] == null
          ? ''
          : MedicalRecord["现病史"]['症状'][i]['其他'];
      array[zz[7]] = ['现病史', '症状', i, '其他'];
      Zhengzhuang.add(
        ExpansionTile(
          title: Row(
            children: [
              Text('症状'),
              Spacer(),
              if (zzremovemode)
                IconButton(
                  onPressed: () {
                    MedicalRecord = JsonDel(['现病史', '症状', i], MedicalRecord);
                    setState(() {
                      Zhengzhuang.clear();
                      buildZhengzhuang();
                    });
                  },
                  icon: Icon(Icons.remove),
                ),
            ],
          ),
          children: [
            for (int j = 0; j <= 7; j++)
              Padding(
                padding: EdgeInsets.all(20),
                child: TextField(
                  controller: zz[j],
                  decoration: InputDecoration(labelText: menu[j]),
                  onChanged: (value) {
                    MedicalRecord = JsonChange(
                      ['现病史', '症状', i, menu[j]],
                      MedicalRecord,
                      value,
                    );
                  },
                ),
              ),
          ],
        ),
      );
    }
  }

  void addjws(String key) {
    Map<String, dynamic> menu = {
      '慢性病': ['病名', '确诊时间', '确诊地址', '服用药物', '控制情况', '发病情况', '其他'],
      '传染病': ['病名', '确诊时间', '确诊地址', '服用药物', '控制情况', '发病情况', '其他'],
      '手术': ['手术时间', '病名', '手术名称'],
      '外伤': ['外伤时间', '外伤部位'],
      '输血': 'list',
      '过敏史': 'list',
    };
    if (!menu.containsKey(key)) return;
    int len = MedicalRecord['既往史'][key].length;
    if (menu[key] is List) {
      final List<String> fields = menu[key];
      for (var field in fields) {
        JsonAdd(['既往史', key, len, field], MedicalRecord, '');
      }
    } else if (menu[key] is String) {
      JsonAdd(['既往史', key, len], MedicalRecord, '');
    }

    setState(() {
      jiwangshi.clear();
      buildjiwangshi();
    });
  }

  void buildjiwangshi() {
    Map<String, dynamic> menu = MedicalRecord['既往史'];
    List<dynamic> temp1 = [];
    for (var entry in menu.entries) {
      List<dynamic> temp = [];
      if (entry.value is List) {
        if (entry.value.isEmpty) {
        } else if (entry.value[0] is Map) {
          for (int j = 0; j < entry.value.length; j++) {
            late List<TextEditingController> any = [];
            if (entry.value[j] is Map) {
              for (var k in entry.value[j].entries) {
                TextEditingController text = TextEditingController();
                text.text = k.value;
                any.add(text);
              }
            }
            temp.add(
              ExpansionTile(
                title: Row(
                  children: [
                    Text(MedicalRecord['既往史'][entry.key][j].values.toList()[0]),
                    Spacer(),
                    IconButton(
                      onPressed: () {
                        MedicalRecord['既往史'][entry.key].removeAt(j);
                        setState(() {
                          jiwangshi.clear();
                          buildjiwangshi();
                        });
                      },
                      icon: Icon(Icons.remove),
                    ),
                  ],
                ),
                children: [
                  for (int k = 0; k < entry.value[j].length; k++)
                    Padding(
                      padding: EdgeInsets.all(20),
                      child: TextField(
                        controller: any[k],
                        decoration: InputDecoration(
                          labelText: MedicalRecord['既往史'][entry.key][j].keys
                              .toList()[k],
                        ),
                        onChanged: (value) {
                          MedicalRecord = JsonChange(
                            [
                              '既往史',
                              entry.key,
                              j,
                              MedicalRecord['既往史'][entry.key][j].keys
                                  .toList()[k],
                            ],
                            MedicalRecord,
                            value,
                          );
                        },
                      ),
                    ),
                ],
              ),
            );
          }
        } else if (entry.value[0] is String) {
          for (int k = 0; k < entry.value.length; k++) {
            TextEditingController text = TextEditingController();
            text.text = entry.value[k];
            temp.add(
              Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: TextField(
                        controller: text,
                        onChanged: (value) {
                          MedicalRecord = JsonChange(
                            ['既往史', entry.key, k],
                            MedicalRecord,
                            value,
                          );
                        },
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      MedicalRecord['既往史'][entry.key].removeAt(k);
                      setState(() {
                        jiwangshi.clear();
                        buildjiwangshi();
                      });
                    },
                    icon: Icon(Icons.remove),
                  ),
                ],
              ),
            );
          }
        }
        temp1.add(
          ExpansionTile(
            title: Row(
              children: [
                Text(entry.key),
                Spacer(),
                IconButton(
                  onPressed: () {
                    addjws(entry.key);
                  },
                  icon: Icon(Icons.add),
                ),
              ],
            ),
            children: [...temp],
          ),
        );
      } else if (entry.value is String) {
        var text = TextEditingController();
        temp1.add(
          Padding(
            padding: EdgeInsets.all(10),
            child: TextField(
              controller: text,
              decoration: InputDecoration(labelText: entry.key),
              onChanged: (value) {
                MedicalRecord = JsonChange(
                  ['既往史', entry.key],
                  MedicalRecord,
                  value,
                );
              },
            ),
          ),
        );
      }
    }
    jiwangshi.add(
      Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          SizedBox(height: 16),
          Text("既往史"),
          SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [...temp1, Divider()],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void buildgerenshi() {
    Map<String, dynamic> gerenshi1 = MedicalRecord['个人史'];
    _switch.add(gerenshi1['吸烟']['enabled']);
    _switch.add(gerenshi1['饮酒']['enabled']);
    _switch.add(gerenshi1['成瘾物']['enabled']);
    Map<String, dynamic> text = {};
    if (_switch[0]) {
      if (gerenshi1['吸烟'].length <= 1) {
        text['吸烟'] = [
          TextEditingController(text: ''),
          TextEditingController(text: ''),
          false,
          TextEditingController(text: ''),
        ];
        JsonAdd(['个人史', '吸烟', '时长'], MedicalRecord, '');
        JsonAdd(['个人史', '吸烟', '频率'], MedicalRecord, '');
        JsonAdd(['个人史', '吸烟', '戒烟'], MedicalRecord, false);
        JsonAdd(['个人史', '吸烟', '戒烟时长'], MedicalRecord, '');
      } else {
        text['吸烟'] = [
          TextEditingController(text: gerenshi1['吸烟']['时长']),
          TextEditingController(text: gerenshi1['吸烟']['频率']),
          gerenshi1['吸烟']['戒烟'],
          TextEditingController(text: gerenshi1['吸烟']['戒烟时长']),
        ];
      }
    }
    if (_switch[1]) {
      if (gerenshi1['饮酒'].length <= 1) {
        text['饮酒'] = [
          TextEditingController(text: ''),
          TextEditingController(text: ''),
        ];
        JsonAdd(['个人史', '饮酒', '时长'], MedicalRecord, '');
        JsonAdd(['个人史', '饮酒', '频率'], MedicalRecord, '');
      } else {
        text['饮酒'] = [
          TextEditingController(text: gerenshi1['饮酒']['时长']),
          TextEditingController(text: gerenshi1['饮酒']['频率']),
        ];
      }
    }
    if (_switch[2]) {
      if (gerenshi1['成瘾物'].length <= 1) {
        text['成瘾物'] = [TextEditingController(text: '')];
        JsonAdd(['个人史', '成瘾物', '种类'], MedicalRecord, '');
      } else {
        text['成瘾物'] = [TextEditingController(text: gerenshi1['成瘾物']['种类'])];
      }
    }
    gerenshi.add(
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('吸烟'),
                  Spacer(),
                  Switch(
                    value: _switch[0],
                    onChanged: (bool newValue) {
                      setState(() {
                        _switch[0] = newValue;
                        MedicalRecord['个人史']['吸烟']['enabled'] = newValue;
                        gerenshi.clear();
                        buildgerenshi();
                      });
                    },
                  ),
                ],
              ),
              if (_switch[0])
                Container(
                  margin: EdgeInsets.only(top: 20),
                  padding: EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: TextField(
                            controller: text['吸烟'][0],
                            decoration: InputDecoration(labelText: '吸烟时长'),
                            onChanged: (value) {
                              MedicalRecord = JsonChange(
                                ['个人史', '吸烟', '时长'],
                                MedicalRecord,
                                value,
                              );
                            },
                          ),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: TextField(
                            controller: text['吸烟'][1],
                            decoration: InputDecoration(labelText: '吸烟频率'),
                            onChanged: (value) {
                              MedicalRecord = JsonChange(
                                ['个人史', '吸烟', '频率'],
                                MedicalRecord,
                                value,
                              );
                            },
                          ),
                        ),
                      ),
                      Checkbox(
                        value: text['吸烟'][2],
                        onChanged: (bool? val) {
                          setState(() {
                            MedicalRecord['个人史']['吸烟']['戒烟'] = val!;
                            gerenshi.clear();
                            buildgerenshi();
                          });
                        },
                      ),
                      Text('已戒烟'),
                      if (text['吸烟'][2])
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: TextField(
                              controller: text['吸烟'][3],
                              decoration: InputDecoration(labelText: '戒除时间'),
                              onChanged: (value) {
                                MedicalRecord = JsonChange(
                                  ['个人史', '吸烟', '戒烟时长'],
                                  MedicalRecord,
                                  value,
                                );
                              },
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              Row(
                children: [
                  Text('饮酒'),
                  Spacer(),
                  Switch(
                    value: _switch[1],
                    onChanged: (bool newValue) {
                      setState(() {
                        _switch[1] = newValue;
                        MedicalRecord['个人史']['饮酒']['enabled'] = newValue;
                        gerenshi.clear();
                        buildgerenshi();
                      });
                    },
                  ),
                ],
              ),
              if (_switch[1])
                Container(
                  margin: EdgeInsets.only(top: 20),
                  padding: EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: TextField(
                            controller: text['饮酒'][0],
                            decoration: InputDecoration(labelText: '饮酒时长'),
                            onChanged: (value) {
                              MedicalRecord = JsonChange(
                                ['个人史', '饮酒', '时长'],
                                MedicalRecord,
                                value,
                              );
                            },
                          ),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: TextField(
                            controller: text['饮酒'][1],
                            decoration: InputDecoration(labelText: '饮酒频率'),
                            onChanged: (value) {
                              MedicalRecord = JsonChange(
                                ['个人史', '饮酒', '频率'],
                                MedicalRecord,
                                value,
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              Row(
                children: [
                  Text('成瘾物'),
                  Spacer(),
                  if (_switch[2])
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: TextField(
                          controller: text['成瘾物'][0],
                          decoration: InputDecoration(labelText: '种类'),
                          onChanged: (value) {
                            MedicalRecord = JsonChange(
                              ['个人史', '成瘾物', '种类'],
                              MedicalRecord,
                              value,
                            );
                          },
                        ),
                      ),
                    ),
                  Spacer(),
                  Switch(
                    value: _switch[2],
                    onChanged: (bool newValue) {
                      setState(() {
                        _switch[2] = newValue;
                        MedicalRecord['个人史']['成瘾物']['enabled'] = newValue;
                        gerenshi.clear();
                        buildgerenshi();
                      });
                    },
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(top: 16, bottom: 16),
                child: TextField(
                  controller: TextEditingController(
                    text: MedicalRecord['个人史']['生活史'],
                  ),
                  decoration: InputDecoration(labelText: '生活史'),
                  onChanged: (value) {
                    MedicalRecord = JsonChange(
                      ['个人史', '生活史'],
                      MedicalRecord,
                      value,
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 16, bottom: 16),
                child: TextField(
                  controller: TextEditingController(
                    text: MedicalRecord['个人史']['职业'],
                  ),
                  decoration: InputDecoration(labelText: '职业'),
                  onChanged: (value) {
                    MedicalRecord = JsonChange(
                      ['个人史', '职业'],
                      MedicalRecord,
                      value,
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 16, bottom: 16),
                child: TextField(
                  controller: TextEditingController(
                    text: MedicalRecord['个人史']['其他'],
                  ),
                  decoration: InputDecoration(labelText: '其他'),
                  onChanged: (value) {
                    MedicalRecord = JsonChange(
                      ['个人史', '其他'],
                      MedicalRecord,
                      value,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void buildhunyushi() {
    if (MedicalRecord['婚育史']['结婚']['statue'] != '未婚' &&
        MedicalRecord['婚育史']['结婚']['statue'] != '' &&
        MedicalRecord['婚育史']['结婚']['详情'] == null) {
      MedicalRecord['婚育史']['结婚']['详情'] = '';
    }
    if (MedicalRecord['婚育史']['生育']['enabled'] &&
        MedicalRecord['婚育史']['生育'].length <= 1) {
      MedicalRecord['婚育史']['生育']['生育儿子数'] = 0;
      MedicalRecord['婚育史']['生育']['生育女儿数'] = 0;
      MedicalRecord['婚育史']['生育']['子女健康情况'];
    }
    if (MedicalRecord['婚育史']['生育']['enabled'] &&
        MedicalRecord['sex'] != "男" &&
        MedicalRecord['婚育史']['生育']['孕'] == null) {
      MedicalRecord['婚育史']['生育']['孕'] = 0;
      MedicalRecord['婚育史']['生育']['产'] = 0;
    }
    if (MedicalRecord['sex'] == "男" &&
        MedicalRecord['婚育史']['生育']['孕'] != null) {
      MedicalRecord['婚育史']['生育'].remove('孕');
      MedicalRecord['婚育史']['生育'].remove('产');
    }
    final List<String> items = ['未婚', '已婚', '离异', '丧偶'];
    DropdownButton hy = DropdownButton<String>(
      style: TextStyle(fontSize: 16, color: Colors.black),
      value: MedicalRecord['婚育史']['结婚']['statue'] == ""
          ? "未婚"
          : MedicalRecord['婚育史']['结婚']['statue'],
      icon: Icon(Icons.arrow_drop_down),
      onChanged: (String? newValue) {
        setState(() {
          MedicalRecord['婚育史']['结婚']['statue'] = newValue!;
          hunyushi.clear();
          buildhunyushi();
        });
      },
      items: items.map<DropdownMenuItem<String>>((String value) {
        return DropdownMenuItem<String>(value: value, child: Text(value));
      }).toList(),
    );
    hunyushi.add(
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('婚育史'),
              Row(children: [Text('结婚'), Spacer(), hy]),
              if (MedicalRecord['婚育史']['结婚']['statue'] != '未婚' &&
                  MedicalRecord['婚育史']['结婚']['statue'] != '')
                Container(
                  margin: EdgeInsets.only(top: 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: TextField(
                            controller: TextEditingController(
                              text: MedicalRecord['婚育史']['结婚']['详情'],
                            ),
                            decoration: InputDecoration(labelText: '详情'),
                            onChanged: (value) {
                              MedicalRecord = JsonChange(
                                ['婚育史', '结婚', '详情'],
                                MedicalRecord,
                                value,
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              Row(
                children: [
                  Text('生育'),
                  Spacer(),
                  Switch(
                    value: MedicalRecord['婚育史']['生育']['enabled'],
                    onChanged: (bool newValue) {
                      setState(() {
                        MedicalRecord['婚育史']['生育']['enabled'] = newValue;
                        hunyushi.clear();
                        buildhunyushi();
                      });
                    },
                  ),
                ],
              ),
              if (MedicalRecord['婚育史']['生育']['enabled'])
                Row(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: TextField(
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'^[0-9]*$'),
                            ),
                          ],
                          controller: TextEditingController(
                            text: MedicalRecord['婚育史']['生育']['生育儿子数']
                                .toString(),
                          ),
                          decoration: InputDecoration(labelText: '儿子数'),
                          onChanged: (value) {
                            MedicalRecord = JsonChange(
                              ['婚育史', '生育', '生育儿子数'],
                              MedicalRecord,
                              int.parse(value),
                            );
                          },
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: TextField(
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'^[0-9]*$'),
                            ),
                          ],
                          controller: TextEditingController(
                            text: MedicalRecord['婚育史']['生育']['生育女儿数']
                                .toString(),
                          ),
                          decoration: InputDecoration(labelText: '女儿数'),
                          onChanged: (value) {
                            MedicalRecord = JsonChange(
                              ['婚育史', '生育', '生育女儿数'],
                              MedicalRecord,
                              int.parse(value),
                            );
                          },
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: TextField(
                          controller: TextEditingController(
                            text: MedicalRecord['婚育史']['生育']['子女健康情况'],
                          ),
                          decoration: InputDecoration(labelText: '子女健康情况'),
                          onChanged: (value) {
                            MedicalRecord = JsonChange(
                              ['婚育史', '生育', '子女健康情况'],
                              MedicalRecord,
                              value,
                            );
                          },
                        ),
                      ),
                    ),
                    if (MedicalRecord['sex'] != "男")
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: TextField(
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'^[0-9]*$'),
                              ),
                            ],
                            controller: TextEditingController(
                              text: MedicalRecord['婚育史']['生育']['孕'].toString(),
                            ),
                            decoration: InputDecoration(labelText: '孕'),
                            onChanged: (value) {
                              MedicalRecord = JsonChange(
                                ['婚育史', '生育', '孕'],
                                MedicalRecord,
                                int.parse(value),
                              );
                            },
                          ),
                        ),
                      ),
                    if (MedicalRecord['sex'] != "男")
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: TextField(
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'^[0-9]*$'),
                              ),
                            ],
                            controller: TextEditingController(
                              text: MedicalRecord['婚育史']['生育']['产'].toString(),
                            ),
                            decoration: InputDecoration(labelText: '产'),
                            onChanged: (value) {
                              MedicalRecord = JsonChange(
                                ['婚育史', '生育', '产'],
                                MedicalRecord,
                                int.parse(value),
                              );
                            },
                          ),
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  void buildjiazushi() {
    hunyushi.add(
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('家族史'),
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: TextEditingController(
                    text: MedicalRecord['家族史']['父母、兄弟姐妹'],
                  ),
                  decoration: InputDecoration(labelText: '父母、兄弟姐妹'),
                  onChanged: (value) {
                    MedicalRecord = JsonChange(
                      ['婚育史', '父母、兄弟姐妹'],
                      MedicalRecord,
                      value,
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: TextEditingController(
                    text: MedicalRecord['家族史']['遗传病'],
                  ),
                  decoration: InputDecoration(labelText: '遗传病'),
                  onChanged: (value) {
                    MedicalRecord = JsonChange(
                      ['婚育史', '遗传病'],
                      MedicalRecord,
                      value,
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: TextEditingController(
                    text: MedicalRecord['家族史']['慢性病'],
                  ),
                  decoration: InputDecoration(labelText: '慢性病'),
                  onChanged: (value) {
                    MedicalRecord = JsonChange(
                      ['婚育史', '慢性病'],
                      MedicalRecord,
                      value,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void addfc() {
    setState(() {
      int number = fucha.length - 1;
      List<TextEditingController> zz = List.generate(
        4,
        (_) => TextEditingController(),
      );
      List<String> menu = ['时间', '医院', '项目', '结果'];
      for (int j = 0; j <= 3; j++) {
        array1[zz[j]] = ['外院辅助检查', number, menu[j]];
        MedicalRecord = JsonAdd(['外院辅助检查', number, menu[j]], MedicalRecord, '');
        zz[j].text = '';
      }
      fucha.add(
        ExpansionTile(
          title: Row(
            children: [
              Text('辅查'),
              Spacer(),
              if (fcremovemode)
                IconButton(
                  onPressed: () {
                    MedicalRecord = JsonDel(['外院辅助检查', number], MedicalRecord);
                    setState(() {
                      fucha.clear();
                      buildfucha();
                    });
                  },
                  icon: Icon(Icons.remove),
                ),
            ],
          ),
          children: [
            for (int j = 0; j <= 3; j++)
              Padding(
                padding: EdgeInsets.all(20),
                child: TextField(
                  controller: zz[j],
                  decoration: InputDecoration(labelText: menu[j]),
                  onChanged: (value) {
                    MedicalRecord = JsonChange(
                      ['外院辅助检查', number, menu[j]],
                      MedicalRecord,
                      value,
                    );
                  },
                ),
              ),
          ],
        ),
      );
    });
  }

  void buildfucha() {
    fucha.add(
      Row(
        children: [
          Text('辅助检查'),
          Spacer(),
          IconButton(
            onPressed: () {
              addfc();
            },
            icon: Icon(Icons.add),
          ),
          IconButton(
            onPressed: () {
              fcremovemode = !fcremovemode;
              setState(() {
                fucha.clear();
                buildfucha();
              });
            },
            icon: Icon(Icons.remove),
          ),
        ],
      ),
    );
    for (int i = 0; i < MedicalRecord['外院辅助检查'].length; i++) {
      List<TextEditingController> fc = List.generate(
        4,
        (_) => TextEditingController(),
      );
      List<String> menu = ['时间', '医院', '项目', '结果'];
      for (int j = 0; j <= 3; j++) {
        fc[j].text = MedicalRecord['外院辅助检查'][i][menu[j]];
        array1[fc[j]] = ['外院辅助检查', i, menu[j]];
      }
      fucha.add(
        ExpansionTile(
          title: Row(
            children: [
              Text('辅查'),
              Spacer(),
              if (fcremovemode)
                IconButton(
                  onPressed: () {
                    MedicalRecord = JsonDel(['外院辅助检查', i], MedicalRecord);
                    setState(() {
                      fucha.clear();
                      buildfucha();
                    });
                  },
                  icon: Icon(Icons.remove),
                ),
            ],
          ),
          children: [
            for (int j = 0; j <= 3; j++)
              Padding(
                padding: EdgeInsets.all(20),
                child: TextField(
                  controller: fc[j],
                  decoration: InputDecoration(labelText: menu[j]),
                  onChanged: (value) {
                    MedicalRecord = JsonChange(
                      ['外院辅助检查', i, menu[j]],
                      MedicalRecord,
                      value,
                    );
                  },
                ),
              ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.item == null ? '新建病历' : '编辑病历:${MedicalRecord['name']}',
        ),
        actions: [
          IconButton(icon: Icon(Icons.save), onPressed: saveData),
          if (widget.item != null)
            IconButton(
              icon: Icon(Icons.delete),
              onPressed: () {
                widget.onDelete;
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            buildBasicInfo(),
            buildZhusu(),
            buildXianbingshi(),
            ...jiwangshi,
            ...gerenshi,
            ...hunyushi,
            ...jiazushi,
            ...fucha,
          ],
        ),
      ),
    );
  }
}
