// ignore_for_file: prefer_if_null_operators

import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:medicalmanager/pages/MedicalRecord.dart';
import 'package:medicalmanager/tools/JsonParse.dart';
import 'package:medicalmanager/tools/JsonChange.dart';
import 'package:medicalmanager/tools/asyncBuildWidget.dart';
import 'package:path_provider/path_provider.dart';
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

class _EditPageState extends State<EditPage> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  
  late int now;
  late String uuid;
  late Map<String, dynamic> MedicalRecord;
  late TextEditingController name;
  late TextEditingController age;
  late TextEditingController zhusu;
  late TextEditingController dabian;
  late TextEditingController xiaobian;
  late TextEditingController tizhong;
  late TextEditingController shuimian;
  
  // 症状相关
  late List<Widget> _symptomWidgets;
  final List<List<TextEditingController>> _symptomControllers = [];
  
  // 既往史相关
  late Widget _pastHistoryWidget;
  
  // 个人史相关
  late Widget _personalHistoryWidget;
  late List<bool> _switchValues;
  late Map<String, dynamic> _personalHistoryControllers;
  
  // 婚育史相关
  late Widget _marriageHistoryWidget;
  late DropdownButton<String> _sexDropdown;
  late DropdownButton<String> _marriageDropdown;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() {
    MedicalRecord = widget.medicalRecord1;
    now = DateTime.now().millisecondsSinceEpoch;
    
    if (widget.item != null && widget.item!['uuid'] != null) {
      uuid = widget.item!['uuid'];
    } else {
      uuid = sha256.convert([now]).toString();
    }
    
    // 初始化文本控制器
    name = TextEditingController(text: MedicalRecord['name']);
    age = TextEditingController(text: MedicalRecord['age']);
    zhusu = TextEditingController(text: MedicalRecord['主诉']);
    dabian = TextEditingController(text: MedicalRecord['现病史']['一般情况']['大便']);
    xiaobian = TextEditingController(text: MedicalRecord['现病史']['一般情况']['小便']);
    shuimian = TextEditingController(text: MedicalRecord['现病史']['一般情况']['精神']);
    tizhong = TextEditingController(text: MedicalRecord['现病史']['一般情况']['体重']);
    
    // 初始化症状
    _initSymptoms();
    
    // 初始化性别下拉
    _initSexDropdown();
    
    // 初始化既往史
    _buildPastHistory();
    
    // 初始化个人史
    _initPersonalHistory();
    
    // 初始化婚育史
    _initMarriageHistory();
  }

  @override
  void dispose() {
    // 销毁所有控制器
    name.dispose();
    age.dispose();
    zhusu.dispose();
    dabian.dispose();
    xiaobian.dispose();
    tizhong.dispose();
    shuimian.dispose();
    
    // 销毁症状控制器
    for (var controllers in _symptomControllers) {
      for (var controller in controllers) {
        controller.dispose();
      }
    }
    
    super.dispose();
  }

  void saveData() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/data/$uuid.json');
    final jsonStr = jsonEncode(MedicalRecord);
    Map<String, dynamic> returnjson = {
      "name": MedicalRecord["name"],
      "age": MedicalRecord["age"],
      "created_at": MedicalRecord["created_at"],
      "last_edit_at": DateTime.now().millisecondsSinceEpoch,
      "uuid": uuid,
    };
    await file.writeAsString(jsonStr);
    widget.onSave(returnjson);
    Navigator.pop(context);
  }

  Widget _buildExpandTextEdit(TextEditingController controller, String label, Function(String) onChanged) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(labelText: label),
      onChanged: onChanged,
    );
  }

  Widget _buildBasicInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Flexible(child: _buildExpandTextEdit(name, '姓名', (value) => MedicalRecord['name'] = value)),
            const SizedBox(width: 16),
            SizedBox(
              width: 100,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("性别", style: TextStyle(fontSize: 12)),
                  _sexDropdown,
                ],
              ),
            ),
            const SizedBox(width: 16),
            Flexible(child: _buildExpandTextEdit(age, '年龄', (value) => MedicalRecord['age'] = value)),
          ],
        ),
      ),
    );
  }

  Widget _buildZhusu() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: _buildExpandTextEdit(
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

  Widget _buildXianbingshi() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        const Text("现病史"),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                ExpansionTile(
                  title: Row(
                    children: [
                      const Text('症状'),
                      const Spacer(),
                      IconButton(
                        onPressed: _addSymptom,
                        icon: const Icon(Icons.add),
                      ),
                    ],
                  ),
                  children: [
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _symptomWidgets.length,
                      itemBuilder: (context, index) => _symptomWidgets[index],
                    ),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: _buildExpandTextEdit(dabian, '大便', (value) {
                    MedicalRecord = JsonChange(
                      ["现病史", '一般情况', '大便'],
                      MedicalRecord,
                      value == '' ? '无异常' : value,
                    );
                  }),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: _buildExpandTextEdit(xiaobian, '小便', (value) {
                    MedicalRecord = JsonChange(
                      ["现病史", '一般情况', '小便'],
                      MedicalRecord,
                      value == '' ? '无异常' : value,
                    );
                  }),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: _buildExpandTextEdit(shuimian, '精神', (value) {
                    MedicalRecord = JsonChange(
                      ["现病史", '一般情况', '精神'],
                      MedicalRecord,
                      value == '' ? '无异常' : value,
                    );
                  }),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: _buildExpandTextEdit(tizhong, '体重', (value) {
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

  void _initSymptoms() {
    _symptomWidgets = [];
    final symptoms = MedicalRecord["现病史"]['症状'] as List<dynamic>;
    
    for (int i = 0; i < symptoms.length; i++) {
      _addSymptomController(i, symptoms[i]);
    }
  }

  void _addSymptom() {
    setState(() {
      final index = _symptomControllers.length;
      final newSymptom = {
        '名字': '', '开始时间': '', '持续时间': '', '频率': '', 
        '程度': '', '类型': '', '伴随症状': '', '其他': ''
      };
      
      // 添加到数据
      MedicalRecord['现病史']['症状'].add(newSymptom);
      
      // 添加控制器和widget
      _addSymptomController(index, newSymptom);
    });
  }

  void _addSymptomController(int index, Map<String, dynamic> symptom) {
    final List<String> fields = [
      '名字', '开始时间', '持续时间', '频率', '程度', '类型', '伴随症状', '其他'
    ];
    
    final controllers = fields.map((field) {
      final controller = TextEditingController(text: symptom[field]?.toString() ?? '');
      return controller;
    }).toList();
    
    _symptomControllers.add(controllers);
    
    _symptomWidgets.add(
      ExpansionTile(
        key: ValueKey(index),
        title: Text('症状${index + 1}'),
        children: fields.map((field) {
          final fieldIndex = fields.indexOf(field);
          return Padding(
            padding: const EdgeInsets.all(20),
            child: TextField(
              controller: controllers[fieldIndex],
              decoration: InputDecoration(labelText: field),
              onChanged: (value) {
                MedicalRecord['现病史']['症状'][index][field] = value;
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  void _initSexDropdown() {
    const List<String> items = ['男', '女', '其他', '未知'];
    
    _sexDropdown = DropdownButton<String>(
      style: const TextStyle(fontSize: 16, color: Colors.black),
      value: MedicalRecord["sex"] == "" ? "未知" : MedicalRecord["sex"],
      icon: const Icon(Icons.arrow_drop_down),
      onChanged: (String? newValue) {
        setState(() {
          MedicalRecord["sex"] = newValue!;
          _initMarriageHistory();
        });
      },
      items: items.map<DropdownMenuItem<String>>((String value) {
        return DropdownMenuItem<String>(value: value, child: Text(value));
      }).toList(),
    );
  }

  void _buildPastHistory() {
    _pastHistoryWidget = _PastHistoryWidget(
      medicalRecord: MedicalRecord,
      onChanged: (newRecord) {
        setState(() {
          MedicalRecord = newRecord;
        });
      },
    );
  }

  void _initPersonalHistory() {
    _switchValues = [
      MedicalRecord['个人史']['吸烟']['enabled'],
      MedicalRecord['个人史']['饮酒']['enabled'],
      MedicalRecord['个人史']['成瘾物']['enabled'],
    ];
    
    _personalHistoryControllers = {
      '吸烟': [
        TextEditingController(text: MedicalRecord['个人史']['吸烟']['时长'] ?? ''),
        TextEditingController(text: MedicalRecord['个人史']['吸烟']['频率'] ?? ''),
        TextEditingController(text: MedicalRecord['个人史']['吸烟']['戒烟时长'] ?? ''),
      ],
      '饮酒': [
        TextEditingController(text: MedicalRecord['个人史']['饮酒']['时长'] ?? ''),
        TextEditingController(text: MedicalRecord['个人史']['饮酒']['频率'] ?? ''),
      ],
      '成瘾物': [
        TextEditingController(text: MedicalRecord['个人史']['成瘾物']['种类'] ?? ''),
      ],
      '生活史': TextEditingController(text: MedicalRecord['个人史']['生活史'] ?? ''),
      '职业': TextEditingController(text: MedicalRecord['个人史']['职业'] ?? ''),
      '其他': TextEditingController(text: MedicalRecord['个人史']['其他'] ?? ''),
    };
    
    _buildPersonalHistoryWidget();
  }

  void _buildPersonalHistoryWidget() {
    _personalHistoryWidget = Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSwitchSection('吸烟', 0),
            if (_switchValues[0]) _buildSmokingSection(),
            _buildSwitchSection('饮酒', 1),
            if (_switchValues[1]) _buildDrinkingSection(),
            _buildSwitchSection('成瘾物', 2),
            if (_switchValues[2]) _buildAddictionSection(),
            _buildTextFieldSection('生活史', '生活史', _personalHistoryControllers['生活史']!),
            _buildTextFieldSection('职业', '职业', _personalHistoryControllers['职业']!),
            _buildTextFieldSection('其他', '其他', _personalHistoryControllers['其他']!),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchSection(String title, int index) {
    return Row(
      children: [
        Text(title),
        const Spacer(),
        Switch(
          value: _switchValues[index],
          onChanged: (bool newValue) {
            setState(() {
              _switchValues[index] = newValue;
              MedicalRecord['个人史'][title]['enabled'] = newValue;
              _buildPersonalHistoryWidget();
            });
          },
        ),
      ],
    );
  }

  Widget _buildSmokingSection() {
    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _personalHistoryControllers['吸烟']![0],
                decoration: const InputDecoration(labelText: '吸烟时长'),
                onChanged: (value) {
                  MedicalRecord['个人史']['吸烟']['时长'] = value;
                },
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _personalHistoryControllers['吸烟']![1],
                decoration: const InputDecoration(labelText: '吸烟频率'),
                onChanged: (value) {
                  MedicalRecord['个人史']['吸烟']['频率'] = value;
                },
              ),
            ),
          ),
          Checkbox(
            value: MedicalRecord['个人史']['吸烟']['戒烟'] ?? false,
            onChanged: (bool? val) {
              setState(() {
                MedicalRecord['个人史']['吸烟']['戒烟'] = val!;
                _buildPersonalHistoryWidget();
              });
            },
          ),
          const Text('已戒烟'),
          if (MedicalRecord['个人史']['吸烟']['戒烟'] ?? false)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _personalHistoryControllers['吸烟']![2],
                  decoration: const InputDecoration(labelText: '戒除时间'),
                  onChanged: (value) {
                    MedicalRecord['个人史']['吸烟']['戒烟时长'] = value;
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDrinkingSection() {
    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _personalHistoryControllers['饮酒']![0],
                decoration: const InputDecoration(labelText: '饮酒时长'),
                onChanged: (value) {
                  MedicalRecord['个人史']['饮酒']['时长'] = value;
                },
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _personalHistoryControllers['饮酒']![1],
                decoration: const InputDecoration(labelText: '饮酒频率'),
                onChanged: (value) {
                  MedicalRecord['个人史']['饮酒']['频率'] = value;
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddictionSection() {
    return Row(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _personalHistoryControllers['成瘾物']![0],
              decoration: const InputDecoration(labelText: '种类'),
              onChanged: (value) {
                MedicalRecord['个人史']['成瘾物']['种类'] = value;
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextFieldSection(String key, String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 16),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(labelText: label),
        onChanged: (value) {
          MedicalRecord['个人史'][key] = value;
        },
      ),
    );
  }

  void _initMarriageHistory() {
    const List<String> items = ['未婚', '已婚', '离异', '丧偶'];
    
    _marriageDropdown = DropdownButton<String>(
      style: const TextStyle(fontSize: 16, color: Colors.black),
      value: MedicalRecord['婚育史']['结婚']['statue'] == "" 
          ? "未婚" 
          : MedicalRecord['婚育史']['结婚']['statue'],
      icon: const Icon(Icons.arrow_drop_down),
      onChanged: (String? newValue) {
        setState(() {
          MedicalRecord['婚育史']['结婚']['statue'] = newValue!;
          _buildMarriageHistoryWidget();
        });
      },
      items: items.map<DropdownMenuItem<String>>((String value) {
        return DropdownMenuItem<String>(value: value, child: Text(value));
      }).toList(),
    );
    
    _buildMarriageHistoryWidget();
  }

  void _buildMarriageHistoryWidget() {
    _marriageHistoryWidget = Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [const Text('结婚'), const Spacer(), _marriageDropdown]),
            if (MedicalRecord['婚育史']['结婚']['statue'] != '未婚' && 
                MedicalRecord['婚育史']['结婚']['statue'] != '')
              Container(
                margin: const EdgeInsets.only(top: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: TextField(
                          controller: TextEditingController(
                            text: MedicalRecord['婚育史']['结婚']['详情'] ?? '',
                          ),
                          decoration: const InputDecoration(labelText: '详情'),
                          onChanged: (value) {
                            MedicalRecord['婚育史']['结婚']['详情'] = value;
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            _buildFertilitySection(),
          ],
        ),
      ),
    );
  }

  Widget _buildFertilitySection() {
    return Column(
      children: [
        Row(
          children: [
            const Text('生育'),
            const Spacer(),
            Switch(
              value: MedicalRecord['婚育史']['生育']['enabled'],
              onChanged: (bool newValue) {
                setState(() {
                  MedicalRecord['婚育史']['生育']['enabled'] = newValue;
                  _buildMarriageHistoryWidget();
                });
              },
            ),
          ],
        ),
        if (MedicalRecord['婚育史']['生育']['enabled'])
          Row(
            children: [
              _buildNumberField('儿子数', '生育儿子数'),
              _buildNumberField('女儿数', '生育女儿数'),
              _buildTextField('子女健康情况', '子女健康情况'),
              if (MedicalRecord['sex'] != "男") _buildNumberField('孕', '孕'),
              if (MedicalRecord['sex'] != "男") _buildNumberField('产', '产'),
            ],
          ),
      ],
    );
  }

  Widget _buildNumberField(String label, String key) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: TextField(
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^[0-9]*$')),
          ],
          controller: TextEditingController(
            text: MedicalRecord['婚育史']['生育'][key]?.toString() ?? '0',
          ),
          decoration: InputDecoration(labelText: label),
          onChanged: (value) {
            final intValue = int.tryParse(value) ?? 0;
            MedicalRecord['婚育史']['生育'][key] = intValue;
          },
        ),
      ),
    );
  }

  Widget _buildTextField(String label, String key) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: TextField(
          controller: TextEditingController(
            text: MedicalRecord['婚育史']['生育'][key]?.toString() ?? '',
          ),
          decoration: InputDecoration(labelText: label),
          onChanged: (value) {
            MedicalRecord['婚育史']['生育'][key] = value;
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.item == null ? '新建病历' : '编辑病历:${MedicalRecord['name']}',
        ),
        actions: [
          IconButton(icon: const Icon(Icons.save), onPressed: saveData),
          if (widget.item != null)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: widget.onDelete,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildBasicInfo(),
            _buildZhusu(),
            _buildXianbingshi(),
            _pastHistoryWidget,
            _personalHistoryWidget,
            _marriageHistoryWidget,
          ],
        ),
      ),
    );
  }
}

class _PastHistoryWidget extends StatefulWidget {
  final Map<String, dynamic> medicalRecord;
  final Function(Map<String, dynamic>) onChanged;

  const _PastHistoryWidget({
    required this.medicalRecord,
    required this.onChanged,
  });

  @override
  __PastHistoryWidgetState createState() => __PastHistoryWidgetState();
}

class __PastHistoryWidgetState extends State<_PastHistoryWidget> {
  late Widget _content;

  @override
  void initState() {
    super.initState();
    _buildContent();
  }

  void _buildContent() {
    final menu = widget.medicalRecord['既往史'];
    final children = <Widget>[];

    for (var entry in menu.entries) {
      final childrenList = <Widget>[];

      if (entry.value is List) {
        if (entry.value.isNotEmpty) {
          if (entry.value[0] is Map) {
            for (int j = 0; j < entry.value.length; j++) {
              final controllers = <TextEditingController>[];
              final keys = entry.value[j].keys.toList();

              for (int k = 0; k < keys.length; k++) {
                final controller = TextEditingController(
                  text: entry.value[j][keys[k]].toString(),
                );
                controllers.add(controller);
              }

              childrenList.add(
                ExpansionTile(
                  key: ValueKey('${entry.key}-$j'),
                  title: Text(entry.value[j].values.first.toString()),
                  children: List.generate(keys.length, (k) {
                    return Padding(
                      padding: const EdgeInsets.all(20),
                      child: TextField(
                        controller: controllers[k],
                        decoration: InputDecoration(labelText: keys[k]),
                        onChanged: (value) {
                          widget.medicalRecord['既往史'][entry.key][j][keys[k]] = value;
                          widget.onChanged(widget.medicalRecord);
                        },
                      ),
                    );
                  }),
                ),
              );
            }
          } else if (entry.value[0] is String) {
            for (int k = 0; k < entry.value.length; k++) {
              final controller = TextEditingController(text: entry.value[k]);
              childrenList.add(
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: TextField(
                    controller: controller,
                    onChanged: (value) {
                      widget.medicalRecord['既往史'][entry.key][k] = value;
                      widget.onChanged(widget.medicalRecord);
                    },
                  ),
                ),
              );
            }
          }
        }
      } else if (entry.value is String) {
        final controller = TextEditingController(text: entry.value);
        childrenList.add(
          Padding(
            padding: const EdgeInsets.all(10),
            child: TextField(
              controller: controller,
              decoration: InputDecoration(labelText: entry.key),
              onChanged: (value) {
                widget.medicalRecord['既往史'][entry.key] = value;
                widget.onChanged(widget.medicalRecord);
              },
            ),
          ),
        );
      }

      children.add(
        ExpansionTile(
          key: ValueKey(entry.key),
          title: Row(
            children: [
              Text(entry.key),
              const Spacer(),
              IconButton(
                onPressed: () => _addItem(entry.key),
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          children: childrenList,
        ),
      );
    }

    _content = Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        const Text("既往史"),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [...children, const Divider()],
            ),
          ),
        ),
      ],
    );
  }

  void _addItem(String key) {
    setState(() {
      final menu = {
        '慢性病': ['病名', '确诊时间', '确诊地址', '服用药物', '控制情况', '发病情况', '其他'],
        '传染病': ['病名', '确诊时间', '确诊地址', '服用药物', '控制情况', '发病情况', '其他'],
        '手术': ['手术时间', '病名', '手术名称'],
        '外伤': ['外伤时间', '外伤部位'],
        '输血': 'list',
        '过敏史': 'list',
      };

      if (!menu.containsKey(key)) return;

      final len = widget.medicalRecord['既往史'][key].length;
      if (menu[key] is List) {
        final fields = menu[key] as List<String>;
        widget.medicalRecord['既往史'][key].add({});
        for (var field in fields) {
          widget.medicalRecord['既往史'][key][len][field] = '';
        }
      } else if (menu[key] is String) {
        widget.medicalRecord['既往史'][key].add('');
      }

      _buildContent();
    });
  }

  @override
  Widget build(BuildContext context) {
    return _content;
  }
}