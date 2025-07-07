import 'package:flutter/material.dart';
import 'package:medicalmanager/tools/JsonChange.dart';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/services.dart' show FilteringTextInputFormatter;
import 'package:crypto/crypto.dart';
import 'package:provider/provider.dart';
import 'package:medicalmanager/models/settings_model.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'ShowPhotos.dart';

const double _sectionSpacing = 24.0;
const double _cardPadding = 16.0;
const double _inputPadding = 12.0;
const double _titleFontSize = 18.0;

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
  // 家族史相关 controller 缓存
  late TextEditingController _jiashuFumuController;
  late TextEditingController _jiashuYichuanController;
  late TextEditingController _jiashuManxingController;
  List<dynamic> Zhengzhuang = [];
  static const String FC_KEY = '外院辅助检查';
  static const List<String> FC_MENU_ITEMS = [
    '时间',
    '医院',
    '项目',
    '结果',
    '其他',
    '图片',
  ];
  late List<Widget> jiwangshi;
  late List<Widget> gerenshi;
  late List<bool> _switch;
  late List<Widget> hunyushi;
  late List<Widget> jiazushi;
  late List<Widget> fucha;
  late bool zzremovemode, fcremovemode;
  final FlutterSoundRecorder _audioRecorder = FlutterSoundRecorder();
  final FlutterSoundPlayer _audioPlayer = FlutterSoundPlayer();
  late bool isRecording;
  String? currentRecordingPath;
  late List<FileSystemEntity> audioFiles;
  late int playingIndex;
  late bool isPlaying;
  late bool ispausing;
  late Duration currentPosition;
  late Duration totalDuration;
  late Duration recordingDuration;

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
    // 初始化家族史 controller
    _jiashuFumuController = TextEditingController(
      text: MedicalRecord['家族史']?['父母、兄弟姐妹'] ?? '',
    );
    _jiashuYichuanController = TextEditingController(
      text: MedicalRecord['家族史']?['遗传病'] ?? '',
    );
    _jiashuManxingController = TextEditingController(
      text: MedicalRecord['家族史']?['慢性病'] ?? '',
    );
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
    buildFucha();
    isRecording = false;
    _audioRecorder.openRecorder(isBGService: true);
    audioFiles = [];
    _audioPlayer.openPlayer();
    playingIndex = -1;
    isPlaying = false;
    currentPosition = Duration.zero;
    totalDuration = Duration.zero;
    recordingDuration = Duration.zero;
    ispausing = false;
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
    _jiashuFumuController.dispose();
    _jiashuYichuanController.dispose();
    _jiashuManxingController.dispose();
    for (var controllers in array.entries) {
      controllers.key.dispose();
    }
    for (var controllers in array1.entries) {
      controllers.key.dispose();
    }
    super.dispose();
  }

  void saveData() async {
    final settings = Provider.of<SettingsModel>(context, listen: false);
    final directory = settings.docPath;
    final file = File('$directory/data/$uuid.json');
    final jsonStr = jsonEncode(MedicalRecord);
    Map<String, dynamic> returnjson = {};
    returnjson["name"] = MedicalRecord["name"];
    returnjson["age"] = MedicalRecord["age"];
    returnjson["created_at"] = MedicalRecord["created_at"];
    returnjson["last_edit_at"] = DateTime.now().millisecondsSinceEpoch;
    returnjson["uuid"] = uuid;
    if (!await file.parent.exists()) {
      file.parent.create(recursive: true);
    }
    if (!await file.exists()) {
      file.create();
    }
    await file.writeAsString(jsonStr);
  }

  void quit() {
    Map<String, dynamic> returnjson = {};
    returnjson["name"] = MedicalRecord["name"];
    returnjson["age"] = MedicalRecord["age"];
    returnjson["created_at"] = MedicalRecord["created_at"];
    returnjson["last_edit_at"] = DateTime.now().millisecondsSinceEpoch;
    returnjson["uuid"] = uuid;
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
        padding: const EdgeInsets.all(_cardPadding),
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
        padding: const EdgeInsets.all(_cardPadding),
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
        Card(
          child: Padding(
            padding: const EdgeInsets.all(_cardPadding),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("现病史"),
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
                Padding(
                  padding: EdgeInsets.all(_inputPadding),
                  child: buildExpandTextEdit(dabian, '大便', (value) {
                    MedicalRecord = JsonChange(
                      ["现病史", '一般情况', '大便'],
                      MedicalRecord,
                      value == '' ? '无异常' : value,
                    );
                  }),
                ),
                Padding(
                  padding: EdgeInsets.all(_inputPadding),
                  child: buildExpandTextEdit(xiaobian, '小便', (value) {
                    MedicalRecord = JsonChange(
                      ["现病史", '一般情况', '小便'],
                      MedicalRecord,
                      value == '' ? '无异常' : value,
                    );
                  }),
                ),
                Padding(
                  padding: EdgeInsets.all(_inputPadding),
                  child: buildExpandTextEdit(shuimian, '精神', (value) {
                    MedicalRecord = JsonChange(
                      ["现病史", '一般情况', '精神'],
                      MedicalRecord,
                      value == '' ? '无异常' : value,
                    );
                  }),
                ),
                Padding(
                  padding: EdgeInsets.all(_inputPadding),
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
                padding: EdgeInsets.all(_inputPadding),
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
                padding: EdgeInsets.all(_inputPadding),
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
                      padding: EdgeInsets.all(_inputPadding),
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
                      padding: EdgeInsets.all(_inputPadding),
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
            padding: EdgeInsets.all(_inputPadding),
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
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text("既往史"),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(_cardPadding),
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
    gerenshi.add(Text('个人史'));
    gerenshi.add(
      Card(
        child: Padding(
          padding: const EdgeInsets.all(_cardPadding),
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
                  margin: EdgeInsets.only(top: _inputPadding),
                  padding: EdgeInsets.all(_inputPadding),
                  child: Row(
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(6),
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
                          padding: const EdgeInsets.all(_inputPadding),
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
                            padding: const EdgeInsets.all(_inputPadding),
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
                  padding: EdgeInsets.all(_inputPadding),
                  child: Row(
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(_inputPadding),
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
                          padding: const EdgeInsets.all(_inputPadding),
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
                        padding: const EdgeInsets.all(_inputPadding),
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
                padding: const EdgeInsets.only(
                  top: _inputPadding,
                  bottom: _inputPadding,
                ),
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
                padding: const EdgeInsets.only(
                  top: _inputPadding,
                  bottom: _inputPadding,
                ),
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
                padding: const EdgeInsets.only(
                  top: _inputPadding,
                  bottom: _inputPadding,
                ),
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
    hunyushi.add(Text('婚育史'));
    hunyushi.add(
      Card(
        child: Padding(
          padding: const EdgeInsets.all(_cardPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [Text('结婚'), Spacer(), hy]),
              if (MedicalRecord['婚育史']['结婚']['statue'] != '未婚' &&
                  MedicalRecord['婚育史']['结婚']['statue'] != '')
                Container(
                  margin: EdgeInsets.only(top: 6),
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
                    activeColor: Colors.green, // 明确区分开关状态
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
    jiazushi.add(Text('家族史'));
    jiazushi.add(
      Card(
        child: Padding(
          padding: const EdgeInsets.all(_cardPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _jiashuFumuController,
                  decoration: InputDecoration(labelText: '父母、兄弟姐妹'),
                  onChanged: (value) {
                    MedicalRecord = JsonChange(
                      ['家族史', '父母、兄弟姐妹'],
                      MedicalRecord,
                      value,
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _jiashuYichuanController,
                  decoration: InputDecoration(labelText: '遗传病'),
                  onChanged: (value) {
                    MedicalRecord = JsonChange(
                      ['家族史', '遗传病'],
                      MedicalRecord,
                      value,
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _jiashuManxingController,
                  decoration: InputDecoration(labelText: '慢性病'),
                  onChanged: (value) {
                    MedicalRecord = JsonChange(
                      ['家族史', '慢性病'],
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

  // 在State类顶部定义常量

  // 改进后的函数
  void addFcItem() {
    setState(() {
      // 获取新项目的索引
      final number = MedicalRecord[FC_KEY]?.length ?? 0;

      // 初始化新项目数据结构
      if (!MedicalRecord.containsKey(FC_KEY)) {
        MedicalRecord[FC_KEY] = [];
      }
      MedicalRecord[FC_KEY].add({for (var item in FC_MENU_ITEMS) item: ''});

      // 创建UI项
      final newItem = _buildFcItem(
        index: number,
        data: MedicalRecord[FC_KEY][number],
        onRemove: () => _removeFcItem(number),
      );

      // 添加到UI列表
      fucha.add(newItem);
    });
  }

  void buildFucha() {
    // 清空现有列表
    fucha.clear();

    // 添加标题行
    fucha.add(
      Row(
        children: [
          const Text('辅助检查', style: TextStyle(fontWeight: FontWeight.bold)),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: addFcItem,
            tooltip: '添加辅查',
          ),
          IconButton(
            icon: Icon(fcremovemode ? Icons.done : Icons.delete),
            onPressed: () {
              setState(() {
                fcremovemode = !fcremovemode;
                // 重新构建列表以更新删除按钮状态
                buildFucha();
              });
            },
            tooltip: fcremovemode ? '退出删除模式' : '删除模式',
            color: fcremovemode ? Colors.red : null,
          ),
        ],
      ),
    );

    // 添加现有项目
    if (MedicalRecord[FC_KEY] != null) {
      for (int i = 0; i < MedicalRecord[FC_KEY].length; i++) {
        fucha.add(
          _buildFcItem(
            index: i,
            data: MedicalRecord[FC_KEY][i],
            onRemove: () => _removeFcItem(i),
          ),
        );
      }
    }
  }

  // 辅助函数：构建单个辅查项目
  Widget _buildFcItem({
    required int index,
    required Map<String, dynamic> data,
    required VoidCallback onRemove,
  }) {
    // 为每个字段创建控制器
    final controllers = List<TextEditingController>.generate(
      FC_MENU_ITEMS.length - 1, // 减去图片字段
      (j) {
        final controller = TextEditingController(
          text: data[FC_MENU_ITEMS[j]]?.toString() ?? '',
        );

        // 设置控制器关联的数据路径
        array1[controller] = [FC_KEY, index, FC_MENU_ITEMS[j]];

        return controller;
      },
    );

    return ExpansionTile(
      key: ValueKey('fc_$index'), // 添加key以优化性能
      title: Row(
        children: [
          Text('辅查 ${index + 1}'), // 添加序号
          const Spacer(),

          if (fcremovemode)
            IconButton(
              icon: const Icon(Icons.delete, size: 20),
              onPressed: onRemove,
              tooltip: '删除此项',
              color: Colors.red,
            )
          else
            IconButton(
              onPressed: () {
                try {
                  MedicalRecord[FC_KEY][index][FC_MENU_ITEMS[5]] =
                      MedicalRecord[FC_KEY][index][FC_MENU_ITEMS[5]] is List
                      ? MedicalRecord[FC_KEY][index][FC_MENU_ITEMS[5]]
                      : [];
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ImageGalleryPage(
                        imageData:
                            MedicalRecord[FC_KEY][index][FC_MENU_ITEMS[5]],
                        uuid: widget.item?['uuid'],
                        name: MedicalRecord['name'],
                        onreturn: (newitem) {
                          setState(() {
                            MedicalRecord[FC_KEY][index][FC_MENU_ITEMS[5]] =
                                newitem;
                          });
                          saveData();
                        },
                      ),
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('图片库加载失败: $e')));
                }
              },
              icon: Icon(Icons.photo_library),
            ),
        ],
      ),
      children: [
        for (int j = 0; j < FC_MENU_ITEMS.length - 1; j++)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: controllers[j],
              decoration: InputDecoration(
                labelText: FC_MENU_ITEMS[j],
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              onChanged: (value) {
                // 更新数据结构
                MedicalRecord[FC_KEY][index][FC_MENU_ITEMS[j]] = value;

                // 更新全局映射
                array1[controllers[j]] = [FC_KEY, index, FC_MENU_ITEMS[j]];
              },
            ),
          ),
      ],
    );
  }

  // 辅助函数：删除项目
  void _removeFcItem(int index) {
    setState(() {
      // 从数据结构中移除
      MedicalRecord[FC_KEY].removeAt(index);

      // 清理关联的控制器
      _cleanupFcControllers(index);

      // 重建UI
      buildFucha();
    });
  }

  // 辅助函数：清理控制器
  void _cleanupFcControllers(int removedIndex) {
    // 移除被删除项的控制器
    array1.removeWhere((controller, path) {
      return path[0] == FC_KEY && path[1] == removedIndex;
    });

    // 更新剩余项的索引
    array1.forEach((controller, path) {
      if (path[0] == FC_KEY && path[1] > removedIndex) {
        array1[controller] = [FC_KEY, path[1] - 1, path[2]];
      }
    });
  }

  Future<void> play(FileSystemEntity file, int index) async {
    await _audioPlayer.setSubscriptionDuration(Duration(milliseconds: 100));
    await _audioPlayer.startPlayer(
      fromURI: file.path,
      codec: Codec.aacADTS,
      whenFinished: () {
        setState(() {
          isPlaying = false;
          playingIndex = -1;
          currentPosition = Duration.zero;
          ispausing = false;
        });
      },
    );
    _audioPlayer.onProgress!.listen((duration) {
      totalDuration = duration.duration;
      setState(() {
        currentPosition = duration.position;
      });
    });
    setState(() {
      isPlaying = true;
      playingIndex = index;
      ispausing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(6),
        child: Column(
          children: [
            _buildRecordButtonSection(context),
            buildBasicInfo(),
            buildZhusu(),
            buildXianbingshi(),
            ...jiwangshi,
            ...gerenshi,
            ...hunyushi,
            ...jiazushi,
            Card(
              child: Padding(
                padding: const EdgeInsets.all(_cardPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: fucha,
                ),
              ),
            ),
            _buildAudioFileList(context),
            SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(
        widget.item == null ? '新建病历' : '编辑病历:${MedicalRecord['name']}',
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.save),
          onPressed: () {
            saveData();
            quit();
          },
        ),
        if (widget.item != null)
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: () {
              widget.onDelete();
              Navigator.pop(context);
            },
          ),
      ],
    );
  }

  Widget _buildRecordButtonSection(BuildContext context) {
    final String recordDir =
        '${Provider.of<SettingsModel>(context, listen: false).docPath}/data/$uuid/record/入院记录/';
    Future<void> openTheRecorder(String tofile) async {
      await Permission.microphone.request();
      final parentDir = File(tofile).parent;
      if (parentDir != null && !parentDir.existsSync()) {
        await parentDir.create(recursive: true);
      }
      await _audioRecorder.startRecorder(toFile: tofile);
    }

    Future<void> onRecordPressed() async {
      if (!isRecording) {
        _audioRecorder.setSubscriptionDuration(Duration(milliseconds: 1000));
        int idx = 1;
        while (File(
          '$recordDir${idx.toString().padLeft(4, '0')}.aac',
        ).existsSync()) {
          idx++;
        }
        currentRecordingPath =
            '$recordDir${idx.toString().padLeft(4, '0')}.aac';
        await openTheRecorder(currentRecordingPath!);
        setState(() {
          isRecording = true;
        });
        _audioRecorder.onProgress!.listen((event) {
          if (mounted) {
            setState(() {
              recordingDuration = event.duration;
            });
          }
        });
      } else {
        var a = await _audioRecorder.stopRecorder();
        if (a == null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('录音失败')));
        }
        setState(() {
          isRecording = false;
          currentRecordingPath = null;
          recordingDuration = Duration.zero;
        });
        await _loadAudioFiles(recordDir);
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAudioFiles(recordDir);
    });

    return Row(
      children: [
        ElevatedButton.icon(
          icon: AnimatedSwitcher(
            duration: Duration(milliseconds: 200),
            transitionBuilder: (child, animation) {
              return ScaleTransition(
                scale: animation,
                child: FadeTransition(opacity: animation, child: child),
              );
            },
            child: Icon(
              key: ValueKey<bool>(isRecording),
              isRecording ? Icons.stop : Icons.mic,
              color: isRecording ? Colors.white : Colors.deepPurple,
            ),
          ),
          label: AnimatedDefaultTextStyle(
            duration: Duration(milliseconds: 150),
            style: TextStyle(
              fontWeight: isRecording ? FontWeight.bold : FontWeight.normal,
              color: isRecording ? Colors.white : Colors.deepPurple,
            ),
            child: Text(
              isRecording
                  ? '  ${recordingDuration.inMinutes.toString().padLeft(2, '0')}:${(recordingDuration.inSeconds % 60).toString().padLeft(2, '0')}   '
                  : '点击开始',
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: isRecording ? Colors.red[400] : Colors.grey[200],
            foregroundColor: isRecording ? Colors.white : Colors.deepPurple,
            animationDuration: Duration(milliseconds: 200),
          ),
          onPressed: onRecordPressed,
        ),
      ],
    );
  }

  Future<void> _loadAudioFiles(String recordDir) async {
    final dir = Directory(recordDir);
    if (isRecording) {
      return;
    }
    if (await dir.exists()) {
      final files =
          dir.listSync().where((f) => f.path.endsWith('.aac')).toList()
            ..sort((a, b) => a.path.compareTo(b.path));
      setState(() {
        audioFiles = files;
      });
    } else {
      await dir.create(recursive: true);
    }
  }

  Widget _buildAudioFileList(BuildContext context) {
    Future<void> deleteAudio(int index) async {
      await _audioPlayer.stopPlayer();
      await File(audioFiles[index].path).delete();
      setState(() {
        isPlaying = false;
        playingIndex = -1;
        currentPosition = Duration.zero;
      });
      final String recordDir =
          '${Provider.of<SettingsModel>(context, listen: false).docPath}/data/$uuid/record/入院记录/';
      await _loadAudioFiles(recordDir);
    }

    if (audioFiles.isEmpty) return SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('录音列表', style: TextStyle(fontWeight: FontWeight.bold)),
          ...List.generate(audioFiles.length, (index) {
            final file = audioFiles[index];
            final fileName = file.path.split(Platform.pathSeparator).last;
            final isThisPlaying = playingIndex == index && isPlaying;
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(_cardPadding),
                child: Column(
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            isThisPlaying && !ispausing
                                ? Icons.pause
                                : Icons.play_arrow,
                          ),
                          onPressed: () {
                            if (isThisPlaying) {
                              if (ispausing) {
                                _audioPlayer.resumePlayer();
                                setState(() {
                                  ispausing = false;
                                });
                              } else {
                                _audioPlayer.pausePlayer();
                                setState(() {
                                  ispausing = true;
                                });
                              }
                            } else {
                              play(file, index);
                            }
                          },
                        ),
                        if (isThisPlaying)
                          IconButton(
                            onPressed: () {
                              _audioPlayer.stopPlayer();
                              setState(() {
                                ispausing = false;
                                isPlaying = false;
                                currentPosition = Duration.zero;
                                totalDuration = Duration.zero;
                              });
                            },
                            icon: Icon(Icons.stop),
                          ),
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text(fileName),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete),
                          onPressed: () => deleteAudio(index),
                        ),
                      ],
                    ),
                    if (isThisPlaying)
                      Row(
                        children: [
                          Expanded(
                            child: Slider(
                              value: currentPosition.inMilliseconds.toDouble(),
                              max: totalDuration.inMilliseconds.toDouble() > 0
                                  ? totalDuration.inMilliseconds.toDouble()
                                  : 1,
                              onChanged: (v) {
                                final newPosition = Duration(
                                  milliseconds: v.toInt(),
                                );
                                _audioPlayer.seekToPlayer(newPosition);
                                setState(() {
                                  currentPosition = newPosition;
                                });
                              },
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(
                              left: 8.0,
                              right: 8.0,
                            ),
                            child: Text(
                              "${currentPosition.inMinutes.toString().padLeft(2, '0')}:${(currentPosition.inSeconds % 60).toString().padLeft(2, '0')} / ${totalDuration.inMinutes.toString().padLeft(2, '0')}:${(totalDuration.inSeconds % 60).toString().padLeft(2, '0')}",
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
