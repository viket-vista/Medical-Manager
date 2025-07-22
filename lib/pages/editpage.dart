// ignore_for_file: non_constant_identifier_names

import 'package:flutter/material.dart';
import 'package:medicalmanager/modules/network_transfer.dart';
import 'package:medicalmanager/tools/json_change.dart';
import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:flutter/services.dart'
    show FilteringTextInputFormatter, Clipboard, ClipboardData;
import 'package:provider/provider.dart';
import 'package:medicalmanager/models/settings_model.dart';
import 'show_photos.dart';
import 'package:medicalmanager/tools/aitool.dart';
import 'package:uuid/uuid.dart';
import 'package:medicalmanager/tools/recorder.dart';
import 'package:medicalmanager/tools/player.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;

const double _cardPadding = 16.0;
const double _inputPadding = 6.0;

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

class _EditPageState extends State<EditPage> with WidgetsBindingObserver {
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
  List<Widget> Zhengzhuang = [];
  List<Widget> jiuzhenjilu = [];
  late List<Widget> jiwangshi;
  late List<Widget> gerenshi;
  late List<bool> _switch;
  late List<Widget> hunyushi;
  late List<Widget> jiazushi;
  late List<Widget> fucha;
  bool freazeIsPlaying = false;
  String? currentRecordingPath;
  late List<FileSystemEntity> audioFiles;
  late int playingIndex;
  late bool isPlaying;
  late Duration recordingDuration;
  late SettingsModel settings;
  List<String> streamResponses = [];
  final ScrollController _scrollController = ScrollController();
  late final Recorder recorder;
  String filName = '';
  Player player = Player();
  @override
  void initState() {
    super.initState();
    MedicalRecord = widget.medicalRecord1;
    now = DateTime.now().millisecondsSinceEpoch;
    if (widget.item != null && widget.item!['uuid'] != null) {
      uuid = widget.item!['uuid'];
    } else {
      final Uuid uuidGenerator = Uuid();
      uuid = uuidGenerator.v1();
    }
    name.text = MedicalRecord['name'];
    age.text = MedicalRecord['age'];
    zhusu.text = MedicalRecord['主诉'];

    _loadAudioFiles(
      '${Provider.of<SettingsModel>(context, listen: false).docPath}/data/$uuid/record/入院记录/',
    );
    player.init(() {
      setState(() {
        isPlaying = false;
        filName = '';
      });
      double newPosition = _scrollController.offset - 100;
      _scrollController.animateTo(
        newPosition,
        duration: Duration(milliseconds: 200),
        curve: Curves.ease,
      );
    });
    dabian.text = MedicalRecord['现病史']['一般情况']['大便'] == ''
        ? '无异常'
        : MedicalRecord['现病史']['一般情况']['大便'];
    xiaobian.text = MedicalRecord['现病史']['一般情况']['小便'] == ''
        ? '无异常'
        : MedicalRecord['现病史']['一般情况']['小便'];
    shuimian.text = MedicalRecord['现病史']['一般情况']['精神'] == ''
        ? '无异常'
        : MedicalRecord['现病史']['一般情况']['精神'];
    tizhong.text = MedicalRecord['现病史']['一般情况']['体重'] == ''
        ? '无异常'
        : MedicalRecord['现病史']['一般情况']['体重'];
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

    jiuzhenjilu = [];
    _buildJZJL();
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
    fucha = [];
    buildFucha();
    if (Platform.isAndroid || Platform.isIOS) {
      recorder = Recorder(
        onProgress: (duration) {
          setState(() {
            recordingDuration = duration;
          });
        },
      );
      recorder.init();
    }
    audioFiles = [];
    playingIndex = -1;
    isPlaying = false;
    recordingDuration = Duration.zero;
    settings = Provider.of<SettingsModel>(context, listen: false);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (freazeIsPlaying) {
        freazeIsPlaying = false;
        player.resume();
      }
    } else if (state == AppLifecycleState.paused) {
      if (isPlaying) {
        freazeIsPlaying = isPlaying;
        player.pause();
      }
    }
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
    if (Platform.isAndroid || Platform.isIOS) {
      recorder.dispose();
    }
    player.dispose();
    WidgetsBinding.instance.removeObserver(this);
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
    widget.onSave(returnjson);
  }

  Widget buildBasicInfo() {
    Widget NAME = TextField(
      controller: name,
      decoration: InputDecoration(labelText: '姓名'),
      onChanged: (value) => MedicalRecord['name'] = value,
    );
    const List<String> items = ['男', '女', '其他', '未知'];
    const List<String> items1 = ['女', '其他', '未知'];
    DropdownButton dp = DropdownButton<String>(
      value: MedicalRecord["sex"] == "" ? "未知" : MedicalRecord["sex"],
      icon: Icon(Icons.arrow_drop_down),
      onChanged: (String? newValue) {
        setState(() {
          if (items1.contains(newValue!) ^
              items1.contains(MedicalRecord['sex'])) {
            MedicalRecord["sex"] = newValue;
            hunyushi.clear();
            buildhunyushi();
          } else {
            MedicalRecord["sex"] = newValue;
          }
        });
      },
      items: items.map<DropdownMenuItem<String>>((String value) {
        return DropdownMenuItem<String>(value: value, child: Text(value));
      }).toList(),
    );
    Widget AGE = TextField(
      controller: age,
      decoration: InputDecoration(labelText: '年龄'),
      onChanged: (value) => MedicalRecord['age'] = value,
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
              child: TextField(
                controller: zhusu,
                decoration: InputDecoration(label: Text('主诉')),
                onChanged: (value) => MedicalRecord['主诉'] = value,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildXianbingshi() {
    const List<String> items = ['大便', '小便', '精神', '体重'];
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Card(
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.all(_cardPadding),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("现病史"),
                ...Zhengzhuang,
                ...jiuzhenjilu,
                ...List.generate(4, (index) {
                  return Padding(
                    padding: EdgeInsets.all(_inputPadding),
                    child: TextField(
                      controller: TextEditingController(
                        text: MedicalRecord['现病史']['一般情况'][items[index]],
                      ),
                      decoration: InputDecoration(labelText: items[index]),
                      onChanged: (value) {
                        MedicalRecord['现病史']['一般情况'][items[index]] = value;
                      },
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ],
    );
  }

  ValueNotifier<bool> zzremovemode = ValueNotifier(false);
  ValueNotifier<bool> title = ValueNotifier(false);
  void buildZhengzhuang() {
    Widget buildZhengzhuangTile(String id) {
      final symptom = MedicalRecord['现病史']['症状'].firstWhere(
        (item) => item['id'] == id,
      );

      const List<String> menu = [
        '名字',
        '开始时间',
        '持续时间',
        '频率',
        '程度',
        '类型',
        '伴随症状',
        '其他',
      ];

      return Card(
        elevation: 1,
        child: ExpansionTile(
          key: Key(id),
          title: ValueListenableBuilder(
            valueListenable: title,
            builder: (index, value, child) {
              return symptom['名字'] == '' ? Text('症状') : Text(symptom['名字']);
            },
          ),
          trailing: ValueListenableBuilder(
            valueListenable: zzremovemode,
            builder: (context, value, child) {
              return zzremovemode.value
                  ? IconButton(
                      onPressed: () {
                        // 删除数据
                        MedicalRecord['现病史']['症状'].removeWhere(
                          (item) => item['id'] == id,
                        );
                        // 更新 UI 列表
                        setState(() {
                          Zhengzhuang.removeWhere(
                            (widget) =>
                                widget is ExpansionTile &&
                                widget.title is Text &&
                                widget.title.toString().contains(id),
                          );
                        });
                      },
                      icon: Icon(Icons.remove, color: Colors.red),
                    )
                  : SizedBox.shrink();
            },
          ),
          children: [
            ...List.generate(8, (index1) {
              return Padding(
                padding: const EdgeInsets.all(_inputPadding),
                child: TextField(
                  controller: TextEditingController(
                    text: symptom[menu[index1]],
                  ),
                  decoration: InputDecoration(labelText: menu[index1]),
                  onChanged: (value) {
                    symptom[menu[index1]] = value;
                    MedicalRecord['现病史']['症状'][MedicalRecord['现病史']['症状']
                            .indexWhere(
                              (item) => item['id'] == id,
                            )][menu[index1]] =
                        value;
                    if (index1 == 0) {
                      title.value = !title.value;
                    }
                  },
                ),
              );
            }),
          ],
        ),
      );
    }

    // 添加“新建”按钮项
    Zhengzhuang.add(
      ListTile(
        title: Row(
          children: [
            Text('症状'),
            Spacer(),
            IconButton(
              onPressed: () {
                final String newId = Uuid().v4();
                if (MedicalRecord['现病史']['症状'] == null) {
                  MedicalRecord['现病史']['症状'] = [];
                }
                MedicalRecord['现病史']['症状'].add({
                  'id': newId,
                  '名字': '',
                  '开始时间': '',
                  '持续时间': '',
                  '频率': '',
                  '程度': '',
                  '类型': '',
                  '伴随症状': '',
                  '其他': '',
                });
                setState(() {
                  Zhengzhuang.add(buildZhengzhuangTile(newId));
                });
              },
              icon: Icon(Icons.add),
            ),
            ValueListenableBuilder(
              valueListenable: zzremovemode,
              builder: (context, value, child) {
                return IconButton(
                  onPressed: () {
                    setState(() {
                      zzremovemode.value = !value;
                    });
                  },
                  icon: zzremovemode.value
                      ? Icon(Icons.done, color: Colors.red)
                      : Icon(Icons.remove),
                );
              },
            ),
          ],
        ),
      ),
    );

    if (MedicalRecord['现病史']['症状'].isEmpty ||
        MedicalRecord['现病史']['症状'] == null) {
      return;
    }

    Zhengzhuang.addAll(
      MedicalRecord['现病史']['症状']
          .map((symptom) {
            return buildZhengzhuangTile(symptom['id']);
          })
          .toList()
          .cast<Widget>()
          .toList(),
    );
  }

  final ValueNotifier<bool> removeModeNotifier = ValueNotifier(false);
  final ValueNotifier<bool> datetime = ValueNotifier(false);
  late String currentEditingId; // 可选：用于记录当前正在编辑的时间字段
  void _buildJZJL() {
    // 构建单个 ExpansionTile
    Widget buildJZJLtile(String id) {
      final record = MedicalRecord['现病史']['诊疗经过'].firstWhere(
        (item) => item['id'] == id,
      );
      const List<String> zljg = ['地点', '诊断', '治疗', '转归', '备注'];

      return Card(
        elevation: 1,
        child: ExpansionTile(
          key: Key(id),
          title: ValueListenableBuilder(
            valueListenable: datetime,
            builder: (index, value, child) {
              return record['时间'] == '' ? Text('时间') : Text(record['时间']);
            },
          ),
          trailing: ValueListenableBuilder(
            valueListenable: removeModeNotifier,
            builder: (context, value, child) {
              return removeModeNotifier.value
                  ? IconButton(
                      onPressed: () {
                        // 删除数据
                        MedicalRecord['现病史']['诊疗经过'].removeWhere(
                          (item) => item['id'] == id,
                        );
                        // 更新 UI 列表
                        setState(() {
                          jiuzhenjilu.removeWhere(
                            (widget) =>
                                widget is ExpansionTile &&
                                widget.key.toString().contains(id),
                          );
                        });
                      },
                      icon: Icon(Icons.remove, color: Colors.red),
                    )
                  : SizedBox(height: 0, width: 0);
            },
          ),
          children: [
            InkWell(
              child: ListTile(
                title: Text('时间'),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    firstDate: DateTime.fromMillisecondsSinceEpoch(0),
                    lastDate: DateTime.now(),
                    initialDate: record['时间'].isEmpty
                        ? DateTime.now()
                        : DateTime.parse(record['时间']),
                  );
                  if (date != null) {
                    final formattedDate = DateFormat('yyyy-MM-dd').format(date);
                    MedicalRecord['现病史']['诊疗经过'][MedicalRecord['现病史']['诊疗经过']
                            .indexWhere((item) => item['id'] == id)]['时间'] =
                        formattedDate;
                    datetime.value = !datetime.value;
                  }
                },
                trailing: ValueListenableBuilder(
                  valueListenable: datetime,
                  builder: (context, value, child) {
                    return Text(record['时间']);
                  },
                ),
              ),
            ),
            Column(
              children: List.generate(5, (index1) {
                return Padding(
                  padding: const EdgeInsets.all(_inputPadding),
                  child: TextField(
                    controller: TextEditingController(
                      text: record[zljg[index1]],
                    ),
                    decoration: InputDecoration(labelText: zljg[index1]),
                    onChanged: (value) {
                      record[zljg[index1]] = value;
                      MedicalRecord['现病史']['诊疗经过'][MedicalRecord['现病史']['诊疗经过']
                              .indexWhere((item) => item['id'] == id)][index1] =
                          value;
                    },
                  ),
                );
              }),
            ),
          ],
        ),
      );
    }

    // 添加“新建”按钮项
    jiuzhenjilu.add(
      ListTile(
        title: Text('诊疗经过'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: () {
                final newId = Uuid().v4();
                MedicalRecord['现病史']['诊疗经过'].add({
                  'id': newId,
                  '时间': '',
                  '地点': '',
                  '诊断': '',
                  '治疗': '',
                  '转归': '',
                  '备注': '',
                });
                setState(() {
                  jiuzhenjilu.add(buildJZJLtile(newId));
                });
              },
              icon: Icon(Icons.add),
            ),
            ValueListenableBuilder<bool>(
              valueListenable: removeModeNotifier,
              builder: (context, value, child) {
                return IconButton(
                  onPressed: () => removeModeNotifier.value = !value,
                  icon: removeModeNotifier.value
                      ? Icon(Icons.done, color: Colors.red)
                      : Icon(Icons.remove),
                );
              },
            ),
          ],
        ),
      ),
    );

    // 如果没有记录，不显示任何 tile
    if (MedicalRecord['现病史']['诊疗经过'].isEmpty ||
        MedicalRecord['现病史']['诊疗经过'] == null) {
      return;
    }

    // 动态构建所有 tile
    jiuzhenjilu.addAll(
      MedicalRecord['现病史']['诊疗经过']
          .map((record) {
            return buildJZJLtile(record['id']);
          })
          .toList()
          .cast<Widget>()
          .toList(),
    );
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
      JsonAdd(['既往史', key, len, 'id'], MedicalRecord, Uuid().v4());
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
    TextEditingController zn = TextEditingController(
      text: MedicalRecord['婚育史']['生育']['子女健康情况'],
    );
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
                          padding: const EdgeInsets.all(_inputPadding),
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
                      flex: 1,
                      child: Padding(
                        padding: const EdgeInsets.all(_inputPadding),
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
                            if (MedicalRecord['sex'] != "男") {
                              if (MedicalRecord['婚育史']['生育']['孕'] == null ||
                                  MedicalRecord['婚育史']['生育']['产'] == null ||
                                  MedicalRecord['婚育史']['生育']['孕'] == 0 ||
                                  MedicalRecord['婚育史']['生育']['产'] == 0) {
                                setState(() {
                                  MedicalRecord['婚育史']['生育']['孕'] =
                                      int.parse(value) +
                                      MedicalRecord['婚育史']['生育']['生育女儿数'];
                                  MedicalRecord['婚育史']['生育']['产'] =
                                      int.parse(value) +
                                      MedicalRecord['婚育史']['生育']['生育女儿数'];
                                });
                              }
                            }
                          },
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Padding(
                        padding: const EdgeInsets.all(_inputPadding),
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
                            if ((MedicalRecord['婚育史']['生育']['孕'] == null &&
                                    MedicalRecord['婚育史']['生育']['产'] == null) ||
                                (MedicalRecord['婚育史']['生育']['孕'] == 0 &&
                                    MedicalRecord['婚育史']['生育']['产'] == 0)) {
                              setState(() {
                                MedicalRecord['婚育史']['生育']['孕'] =
                                    int.parse(value) +
                                    MedicalRecord['婚育史']['生育']['生育儿子数'];
                                MedicalRecord['婚育史']['生育']['产'] =
                                    int.parse(value) +
                                    MedicalRecord['婚育史']['生育']['生育儿子数'];
                              });
                            }
                          },
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Padding(
                        padding: const EdgeInsets.all(_inputPadding),
                        child: TextField(
                          controller: zn,
                          readOnly: true,
                          decoration: InputDecoration(labelText: '子女健康情况'),
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (context) {
                                return AlertDialog(
                                  title: Text('子女健康情况'),
                                  content: SizedBox(
                                    height: 200, // 设置较大的高度
                                    child: TextField(
                                      textAlignVertical: TextAlignVertical.top,
                                      maxLines: null, // 允许多行
                                      expands: true, // 尽可能扩展空间
                                      controller: zn, // 使用相同的控制器
                                      decoration: InputDecoration(
                                        border: OutlineInputBorder(),
                                        hintText: '请输入内容',
                                      ),
                                      onChanged: (value) {
                                        MedicalRecord['婚育史']['生育']['子女健康情况'] =
                                            value;
                                      },
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: Text('确定'),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              if (MedicalRecord['婚育史']['生育']['enabled'] &&
                  MedicalRecord['sex'] != "男")
                Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: Padding(
                        padding: const EdgeInsets.all(_inputPadding),
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
                    Expanded(
                      flex: 1,
                      child: Padding(
                        padding: const EdgeInsets.all(_inputPadding),
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
                padding: const EdgeInsets.all(_inputPadding),
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
                padding: const EdgeInsets.all(_inputPadding),
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
                padding: const EdgeInsets.all(_inputPadding),
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

  ValueNotifier<bool> fcremovemode = ValueNotifier(false);
  static const List<String> fcMenuItems = ['时间', '医院', '项目', '结果', '其他', '图片'];
  void buildFucha() {
    fucha.clear();
    Widget buildFcItem(String id) {
      final record = MedicalRecord['外院辅助检查'].firstWhere(
        (item) => item['id'] == id,
      );
      return Card(
        child: ExpansionTile(
          key: Key(id), // 添加key以优化性能
          title: ValueListenableBuilder(
            valueListenable: datetime,
            builder: (index, value, child) {
              return Text(
                record[fcMenuItems[0]] == '' ? '辅助检查' : record[fcMenuItems[0]],
              );
            },
          ),

          trailing: ValueListenableBuilder(
            valueListenable: fcremovemode,
            builder: (context, value, child) {
              if (fcremovemode.value) {
                return IconButton(
                  icon: const Icon(Icons.remove, size: 20),
                  onPressed: () {
                    for (String i in record[fcMenuItems[5]]) {
                      final docPath = settings.docPath;
                      final filePath = path.join(
                        docPath,
                        'data',
                        uuid,
                        'pictures',
                        i,
                      );
                      final file = File(filePath);
                      if (file.existsSync()) {
                        file.deleteSync();
                      }
                    }
                    MedicalRecord['外院辅助检查'].removeWhere(
                      (item) => item['id'] == id,
                    );
                    setState(() {
                      fucha.removeWhere(
                        (widget) =>
                            widget is ExpansionTile &&
                            widget.key.toString().contains(id),
                      );
                    });
                  },
                  tooltip: '删除此项',
                  color: Colors.red,
                );
              } else {
                return IconButton(
                  onPressed: () {
                    try {
                      record[fcMenuItems[5]] = record[fcMenuItems[5]] is List
                          ? record[fcMenuItems[5]]
                          : [];
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ImageGalleryPage(
                            imageData: record[fcMenuItems[5]],
                            uuid: widget.item?['uuid'],
                            name: MedicalRecord['name'],
                            onreturn: (newitem) {
                              setState(() {
                                MedicalRecord['外院辅助检查'][MedicalRecord['外院辅助检查']
                                        .indexWhere(
                                          (item) => item['id'] == id,
                                        )][fcMenuItems[5]] =
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
                );
              }
            },
          ),
          children: [
            InkWell(
              child: ListTile(
                title: Text('时间'),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    firstDate: DateTime.fromMillisecondsSinceEpoch(0),
                    lastDate: DateTime.now(),
                    initialDate: record['时间'].isEmpty
                        ? DateTime.now()
                        : DateTime.parse(record['时间']),
                  );
                  if (date != null) {
                    final formattedDate = DateFormat('yyyy-MM-dd').format(date);
                    record['时间'] = formattedDate;
                    datetime.value = !datetime.value;
                  }
                },
                trailing: ValueListenableBuilder(
                  valueListenable: datetime,
                  builder: (context, value, child) {
                    return Text(record['时间']);
                  },
                ),
              ),
            ),
            for (int j = 1; j < fcMenuItems.length - 1; j++)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: TextField(
                  controller: TextEditingController(
                    text: record[fcMenuItems[j]],
                  ),
                  decoration: InputDecoration(
                    labelText: fcMenuItems[j],
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  onChanged: (value) {
                    // 更新数据结构
                    MedicalRecord['外院辅助检查'][[
                          MedicalRecord['外院辅助检查'].indexWhere(
                            (item) => item['id'] == id,
                          ),
                        ]][fcMenuItems[j]] =
                        value;
                  },
                ),
              ),
          ],
        ),
      );
    }

    // 添加标题行
    fucha.add(
      ListTile(
        title: const Text(
          '辅助检查',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),

        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                String id = Uuid().v4();
                MedicalRecord['外院辅助检查'].add({
                  'id': id,
                  '时间': '',
                  '医院': '',
                  '项目': '',
                  '结果': '',
                  '其他': '',
                  '图片': [],
                });
                setState(() {
                  fucha.add(buildFcItem(id));
                });
              },
              tooltip: '添加辅查',
            ),
            ValueListenableBuilder(
              valueListenable: fcremovemode,
              builder: (context, value, child) {
                return IconButton(
                  icon: Icon(fcremovemode.value ? Icons.done : Icons.remove),
                  onPressed: () {
                    fcremovemode.value = !value;
                  },
                  tooltip: fcremovemode.value ? '退出删除模式' : '删除模式',
                  color: fcremovemode.value ? Colors.red : null,
                );
              },
            ),
          ],
        ),
      ),
    );
    if (MedicalRecord['外院辅助检查'] == null || MedicalRecord['外院辅助检查'].isEmpty) {
      return;
    }
    fucha.addAll(
      List.generate(MedicalRecord['外院辅助检查'].length, (index) {
        if (!MedicalRecord['外院辅助检查'][index].containsKey('id')) {
          MedicalRecord['外院辅助检查'][index]['id'] = Uuid().v4();
        }
        return buildFcItem(MedicalRecord['外院辅助检查'][index]['id']);
      }).toList().cast<Widget>().toList(),
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
          },
        ),
        if (widget.item != null)
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: Text('确认删除病历?'),
                  content: Text('删除后无法恢复'),
                  actions: [
                    TextButton(
                      child: Text('取消'),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                    TextButton(
                      child: Text('确认'),
                      onPressed: () {
                        widget.onDelete();
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildRecordButtonSection(BuildContext context) {
    final String recordDir =
        '${Provider.of<SettingsModel>(context, listen: false).docPath}/data/$uuid/record/入院记录/';

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAudioFiles(recordDir);
    });

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            if (Platform.isAndroid || Platform.isIOS)
              recorder.buildRecorderButton(context, recordDir),

            SizedBox(width: 6),
            ElevatedButton.icon(
              icon: Icon(Icons.start),
              onPressed: () {
                _analyseJson();
              },
              label: const Text('根据表单生成入院记录'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadAudioFiles(String recordDir) async {
    final dir = Directory(recordDir);
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
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('确认删除'),
            content: const Text('确定要删除这个录音文件吗？'),
            actions: [
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  final String recordDir =
                      '${Provider.of<SettingsModel>(context, listen: false).docPath}/data/$uuid/record/入院记录/';
                  audioFiles[index].deleteSync();
                  setState(() {
                    isPlaying = false;
                    WakelockPlus.disable();
                    player.reset();
                    playingIndex = -1;
                    double newPosition = _scrollController.offset - 100;
                    _scrollController.animateTo(
                      newPosition,
                      duration: Duration(milliseconds: 200),
                      curve: Curves.ease,
                    );
                  });
                  await _loadAudioFiles(recordDir);
                },
                child: const Text('删除'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('取消'),
              ),
            ],
          );
        },
      );
    }

    Future<void> renameAudio(int index, String newName) async {
      if (newName.isNotEmpty) {
        final newPath =
            '${audioFiles[index].parent.path}/$newName${newName.endsWith('.aac') ? '' : '.aac'}';
        await audioFiles[index].rename(newPath);
        setState(() {
          audioFiles[index] = File(newPath);
        });
      }
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
            final fileName = path.basenameWithoutExtension(file.path);
            return InkWell(
              onLongPress: () {
                showModalBottomSheet(
                  context: context,
                  builder: (context) => SafeArea(
                    child: Column(
                      children: [
                        ListTile(
                          title: Text('分享'),
                          onTap: () async {
                            Navigator.pop(context);
                            showModalBottomSheet(
                              context: context,
                              builder: (context) => CommunicationPage(
                                data: {
                                  'type': 'file',
                                  'data': file.path,
                                  'topath': path.relative(
                                    file.path,
                                    from: settings.docPath,
                                  ),
                                  'length': file.statSync().size,
                                },
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(_cardPadding),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(Icons.play_arrow),
                            onPressed: () {
                              bool temp = isPlaying;
                              setState(() {
                                filName = file.path;
                                isPlaying = true;
                              });
                              WakelockPlus.disable();
                              player.reset();
                              if (!temp) {
                                WidgetsBinding.instance.addPostFrameCallback((
                                  _,
                                ) {
                                  double newPosition =
                                      _scrollController.offset + 100;
                                  _scrollController.animateTo(
                                    newPosition, // 使用 clamp 确保值在范围内
                                    duration: Duration(milliseconds: 200),
                                    curve: Curves.linear,
                                  );
                                });
                              }
                            },
                          ),

                          Padding(
                            padding: EdgeInsets.all(8.0),
                            child: InkWell(
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    final TextEditingController textController =
                                        TextEditingController(text: fileName);
                                    return AlertDialog(
                                      title: Text('修改文件名'),
                                      content: TextField(
                                        controller: textController,
                                        decoration: InputDecoration(
                                          hintText: '输入新的文件名',
                                        ),
                                      ),
                                      actions: <Widget>[
                                        TextButton(
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                          },
                                          child: Text('取消'),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            renameAudio(
                                              index,
                                              textController.text,
                                            );
                                            Navigator.of(context).pop();
                                          },
                                          child: Text('确定'),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                              child: Text(fileName),
                            ),
                          ),
                          Spacer(),
                          IconButton(
                            icon: Icon(Icons.delete),
                            onPressed: () => deleteAudio(index),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Future<void> _analyseJson() async {
    DeepSeekApi api = DeepSeekApi(apiKey: settings.apiKey);
    Map temp = {...MedicalRecord}; // 创建副本避免修改原始数据

    // 清理已有的AI输出
    if (temp.containsKey('ai输出')) {
      temp.remove('ai输出');
    }

    final messages = [
      {
        'role': 'system',
        'content':
            '请根据user给出的json数据生成一份入院记录，要求有且仅有主诉，现病史，既往史，个人史，婚育史，月经史（如果有）、家族史、摘要，并想出可能的鉴别诊断，写出支持和不支持点，注意如果json某个字段enabled是false则代表该字段可忽略，不得使用MarkdownMarkdown', // 保持您的系统提示
      },
      {'role': 'user', 'content': jsonEncode(temp)},
    ];

    try {
      final stream = await api.chatCompletions(
        messages: messages,
        model: settings.model,
        stream: true,
      );

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AIDialog(
          stream: stream,
          onAccept: (result) {
            setState(() {
              MedicalRecord['ai输出'] = result;
            });
          },
        ),
      );
    } catch (e) {
      debugPrint('API调用失败: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('请求失败: $e')));
    }
  }

  Widget _buildAIOutputCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(_cardPadding),
        child: Column(
          children: [
            Text('AI生成的入院记录', style: TextStyle(fontWeight: FontWeight.bold)),
            if (MedicalRecord['ai输出'] != null)
              InkWell(
                onLongPress: () {
                  showModalBottomSheet(
                    context: context,
                    builder: (context) => SafeArea(
                      child: Column(
                        children: [
                          ListTile(
                            leading: Icon(Icons.share),
                            title: Text('分享'),
                            onTap: () async {
                              Navigator.pop(context);
                              showModalBottomSheet(
                                context: context,
                                builder: (context) => CommunicationPage(
                                  data: {
                                    'type': 'text',
                                    'data': MedicalRecord['ai输出'],
                                  },
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) {
                        TextEditingController ryjlController =
                            TextEditingController(text: MedicalRecord['ai输出']);
                        return Scaffold(
                          appBar: AppBar(
                            title: Text('AI生成的入院记录'),
                            actions: [
                              IconButton(
                                icon: Icon(Icons.copy),
                                onPressed: () {
                                  Clipboard.setData(
                                    ClipboardData(text: MedicalRecord['ai输出']),
                                  );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('已复制到剪贴板')),
                                  );
                                },
                              ),
                              IconButton(
                                onPressed: () {
                                  setState(() {
                                    MedicalRecord['ai输出'] = ryjlController.text;
                                  });
                                  Navigator.pop(context);
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
                                        controller: ryjlController,
                                        textAlignVertical:
                                            TextAlignVertical.top,
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
                },
                child: AbsorbPointer(
                  child: TextField(
                    controller: TextEditingController(
                      text: MedicalRecord['ai输出'],
                    ),
                    maxLines: 10,
                    minLines: 10,
                    readOnly: true,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'AI生成的入院记录',
                    ),
                  ),
                ),
              ),
            if (MedicalRecord['ai输出'] == null) Text('请点击上方按钮生成入院记录'),
          ],
        ),
      ),
    );
  }

  TextEditingController con = TextEditingController(text: '1');
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Padding(
        padding: EdgeInsets.only(bottom: isPlaying ? 100.0 : 0.0),
        child: SingleChildScrollView(
          controller: _scrollController,
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
                clipBehavior: Clip.antiAlias,
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
              _buildAIOutputCard(),
            ],
          ),
        ),
      ),
      bottomSheet: isPlaying
          ? Material(elevation: 4.0, child: player.buildPlayer(filName))
          : null,
    );
  }
}

class AIDialog extends StatefulWidget {
  final Stream stream;
  final Function(String) onAccept; // 可选的回调函数，当生成完成时调用
  const AIDialog({super.key, required this.stream, required this.onAccept});

  @override
  AIDialogState createState() => AIDialogState();
}

class AIDialogState extends State<AIDialog> {
  late TextEditingController _controller;

  StringBuffer responseBuffer = StringBuffer();
  late bool isCompleted; // 标记生成是否完成
  StreamSubscription? subscription;
  ScrollController scrollController = ScrollController();
  @override
  void initState() {
    super.initState();
    isCompleted = false;
    _controller = TextEditingController();
    subscription = widget.stream.listen(
      (data) {
        try {
          final jsonData = json.decode(data);
          final content = jsonData['choices']?[0]['delta']?['content'];
          if (content != null && content.isNotEmpty) {
            responseBuffer.write(content);
            setState(() {
              _controller.text = responseBuffer.toString();
            });

            // 自动滚动到底部
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (scrollController.hasClients) {
                scrollController.animateTo(
                  scrollController.position.maxScrollExtent,
                  duration: const Duration(milliseconds: 100),
                  curve: Curves.easeOut,
                );
              }
            });
          }
        } catch (e) {
          debugPrint('Error parsing stream data: $e');
        }
      },
      onDone: () {
        setState(() {
          isCompleted = true;
        });
      },
      onError: (error) {
        debugPrint('Stream error: $error');
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('生成失败: $error')));
          Navigator.of(context).pop();
        }
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    subscription?.cancel();
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('生成入院记录'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _controller,
              maxLines: 10,
              minLines: 10,
              readOnly: !isCompleted,
              enableInteractiveSelection: isCompleted,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: '正在生成入院记录...',
              ),
              scrollController: scrollController,
            ),
            isCompleted
                ? const LinearProgressIndicator(value: 1)
                : const LinearProgressIndicator(),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            subscription?.cancel();
            Navigator.pop(context);
          },
          child: const Text('取消'),
        ),
        if (isCompleted)
          ElevatedButton(
            onPressed: () {
              // 保存结果到状态
              widget.onAccept(_controller.text);
              Navigator.pop(context);
            },
            child: const Text('应用'),
          )
        else
          ElevatedButton(
            onPressed: () {
              setState(() {
                isCompleted = true; // 模拟生成完成
                subscription?.cancel();
              });
            },
            child: const Text('停止生成'),
          ),
      ],
    ); // 确保对话框关闭时取消订阅
  }
}
