import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';
import 'RecordEdit.dart';
import 'package:provider/provider.dart';
import 'package:medicalmanager/models/settings_model.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:medicalmanager/tools/JsonParse.dart';
import 'package:toggle_switch/toggle_switch.dart';

class RecordPage extends StatefulWidget {
  final String uuid;
  final String name;
  const RecordPage({super.key, required this.uuid, required this.name});

  @override
  State<RecordPage> createState() => _RecordPageState();
}

class _RecordPageState extends State<RecordPage>
    with SingleTickerProviderStateMixin {
  late Directory folder;
  late bool _deletemode;
  late CalendarFormat _format;
  late bool _showCalendar;
  ValueNotifier<List<FileSystemEntity>> files = ValueNotifier([]);
  @override
  void initState() {
    super.initState();
    _showCalendar = true;
    _deletemode = false;
    _initFolder();
    _format = CalendarFormat.week;
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _initFolder() async {
    final dir = Provider.of<SettingsModel>(context, listen: false).docPath;
    folder = Directory('$dir/${widget.uuid}');
    if (!(await folder.exists())) {
      await folder.create(recursive: true);
    }
    _loadFiles();
  }

  void _showDetailDialog(BuildContext context, FileSystemEntity file) {
    File trueFile = file as File;
    if (!trueFile.existsSync()) return;
    late final Map<String, dynamic> item;
    try {
      final jsonall = JsonParse(file.readAsStringSync());
      item = jsonall.parse();
    } catch (e) {
      item = {'id': 'error'};
    }
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("详情"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("姓名: ${widget.name}"),
              Text("标识符: ${widget.uuid}"),
              Text("此项标识符: ${item['id']}"),
              Text(
                "项目名称: ${path.basenameWithoutExtension(file.path).substring(11)}",
              ),
              Text(
                "项目归属时间: ${path.basenameWithoutExtension(file.path).substring(0, 10)}",
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Text('地址：${file.path}', maxLines: 1, softWrap: false),
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

  Future<void> _navigateToEditOrigin(
    BuildContext context,
    FileSystemEntity item,
  ) async {
    try {
      TextEditingController controller = TextEditingController();
      File file = item as File;
      controller.text = file.readAsStringSync();
      if (!context.mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) {
            return Scaffold(
              appBar: AppBar(
                title: Text('编辑元数据${widget.name}'),
                actions: [
                  IconButton(
                    onPressed: () {
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

  List<Widget> _buildFileList(List<FileSystemEntity> files, BuildContext con) {
    return List.generate(files.length, (index) {
      final file = files[index];
      return Card(
        child: ListTile(
          title: Text(path.basenameWithoutExtension(file.path).substring(11)),
          onTap: () => openEditPage(file),
          onLongPress: () {
            showModalBottomSheet(
              context: con,
              builder: (BuildContext context) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      leading: const Icon(Icons.info),
                      title: const Text('详情'),
                      onTap: () {
                        Navigator.pop(context); // 关闭底部菜单
                        _showDetailDialog(context, file);
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.edit),
                      title: const Text('重命名'),
                      onTap: () {
                        Navigator.pop(context); // 关闭底部菜单
                        _onEditInfo(file, con);
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.edit),
                      title: const Text('编辑元数据'),
                      onTap: () {
                        Navigator.pop(context); // 关闭底部菜单
                        _navigateToEditOrigin(context, file);
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.delete),
                      title: const Text('删除'),
                      onTap: () {
                        Navigator.pop(context); // 关闭底部菜单
                        deleteItem(file as File);
                      },
                    ),
                  ],
                );
              },
            );
          },
          trailing: _deletemode
              ? IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () async {
                    deleteItem(file as File);
                    setState(() {
                      files.removeAt(index);
                    });
                  },
                )
              : null,
        ),
      );
    });
  }

  void deleteItem(File file) async {
    if (file.existsSync()) {
      await file.delete();
      try {
        final jsonall = JsonParse(file.readAsStringSync());
        final item = jsonall.parse();
        Directory dir = Directory(path.join(folder.path, 'record', item['id']));
        if (dir.existsSync()) {
          dir.deleteSync(recursive: true);
        }
      } catch (e) {
        return;
      }
    }
  }

  Future<void> _loadFiles() async {
    late final List<FileSystemEntity> list;
    if (_showCalendar) {
      final exists = await folder.exists();
      if (!exists) return;
      list = folder.listSync().whereType<File>().where((element) {
        return path
            .basename(element.path)
            .contains(_selectedDay.toIso8601String().substring(0, 10));
      }).toList();
    } else {
      final exists = await folder.exists();
      if (!exists) return;
      list = folder.listSync().whereType<File>().toList();
    }

    files.value = list;
  }

  void _insertFile() async {
    final options = ['日常病程', '主任/副主任查房'];
    final selected = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('选择类型'),
        children: options
            .map(
              (opt) => SimpleDialogOption(
                child: Text(opt),
                onPressed: () => Navigator.pop(context, opt),
              ),
            )
            .toList(),
      ),
    );
    if (selected == null) return;
    final now = DateTime.now();
    final formattedTime = now.toIso8601String().substring(0, 10);
    File file = File('${folder.path}/${formattedTime}_$selected.json');
    if (file.existsSync()) {
      int i = 0;
      while (file.existsSync()) {
        i++;
        file = File(
          '${folder.path}/${formattedTime}_${selected}_${i.toString()}.json',
        );
      }
    }
    file.createSync();
    await file.writeAsString('{"id":"${Uuid().v4()}"}');
    _loadFiles();
  }

  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: '插入',
            onPressed: _insertFile,
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            tooltip: '删除',
            onPressed: () {
              setState(() {
                _deletemode = !_deletemode;
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, animation) {
              return SizeTransition(
                sizeFactor: animation,
                axisAlignment: 1.0,
                child: child,
              );
            },
            child: _showCalendar
                ? Card(
                    child: Column(
                      children: [
                        TableCalendar(
                          locale: 'zh_CN',
                          focusedDay: _focusedDay,
                          firstDay: DateTime.utc(2020, 1, 1),
                          lastDay: DateTime.utc(2030, 12, 31),
                          calendarFormat: _format,
                          selectedDayPredicate: (day) =>
                              isSameDay(day, _selectedDay),
                          onDaySelected: (selectedDay, focusedDay) {
                            setState(() {
                              _selectedDay = selectedDay;
                              _focusedDay = focusedDay;
                              _loadFiles();
                            });
                          },
                          onFormatChanged: (format) {
                            setState(() {
                              _format = format;
                            });
                          },
                        ),
                        IconButton(
                          onPressed: () {
                            if (_format == CalendarFormat.month) {
                              setState(() {
                                _format = CalendarFormat.week;
                              });
                            } else {
                              setState(() {
                                _format = CalendarFormat.month;
                              });
                            }
                          },
                          icon: _format == CalendarFormat.month
                              ? Icon(Icons.expand_less)
                              : Icon(Icons.expand_more),
                        ),
                      ],
                    ),
                  )
                : SizedBox.shrink(key: ValueKey<bool>(!_showCalendar)),
          ),
          ValueListenableBuilder(
            valueListenable: files,
            builder: (context, value, child) {
              if (files.value.isEmpty) {
                return Center(child: Text('暂无记录'));
              }
              return Column(children: [..._buildFileList(value, context)]);
            },
          ),
        ],
      ),
      floatingActionButton: ToggleSwitch(
        initialLabelIndex: _showCalendar ? 1 : 0,
        totalSwitches: 2,
        minWidth: 100,
        labels: ['显示全部', '显示日历'],
        onToggle: (index) {
          setState(() {
            _showCalendar = index == 1;
            _loadFiles();
          });
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  openEditPage(FileSystemEntity fil) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RecordEdit(file: fil, name: widget.name),
      ),
    );
  }

  void _onEditInfo(FileSystemEntity file, BuildContext con) {
    String name = path.basenameWithoutExtension(file.path).substring(11);
    DateTime? focusedDay = DateTime.tryParse(
      path.basename(file.path).substring(0, 10),
    );
    DateTime? selected = DateTime.tryParse(
      path.basename(file.path).substring(0, 10),
    );
    TextEditingController newname = TextEditingController(text: name);
    CalendarFormat format = CalendarFormat.month;
    showModalBottomSheet(
      context: con,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState1) {
            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: TextField(
                        controller: newname,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: '文件名',
                        ),
                      ),
                    ),
                    Text('归属时间'),
                    TableCalendar(
                      firstDay: DateTime.utc(2020, 1, 1),
                      lastDay: DateTime.utc(2030, 12, 31),
                      focusedDay: focusedDay ?? DateTime.now(),
                      calendarFormat: format,
                      selectedDayPredicate: (day) =>
                          isSameDay(day, selected ?? DateTime.now()),
                      onDaySelected: (selectedDay, focusedDay) {
                        setState1(() {
                          selected = selectedDay;
                          focusedDay = focusedDay;
                        });
                      },
                      onFormatChanged: (form) => format = form,
                      locale: 'zh_CN',
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: Text('取消'),
                        ),
                        SizedBox(width: 100),
                        ElevatedButton(
                          onPressed: () {
                            file.renameSync(
                              '${file.parent.path}/${selected!.toIso8601String().substring(0, 10)}_${newname.text}${path.extension(file.path)}',
                            );
                            _loadFiles();
                            Navigator.pop(context);
                          },
                          child: Text('确定'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
