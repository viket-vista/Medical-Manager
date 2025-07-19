import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'RecordEdit.dart';
import 'package:provider/provider.dart';
import 'package:medicalmanager/models/settings_model.dart';
import 'package:table_calendar/table_calendar.dart';

class RecordPage extends StatefulWidget {
  final String uuid;
  final String name;
  const RecordPage({super.key, required this.uuid, required this.name});

  @override
  State<RecordPage> createState() => _RecordPageState();
}

class _RecordPageState extends State<RecordPage> {
  late Directory folder;
  List<FileSystemEntity> files = [];
  late bool _deletemode;
  late CalendarFormat _format;
  @override
  void initState() {
    super.initState();
    _deletemode = false;
    _initFolder();
    _format = CalendarFormat.week;
  }

  Future<void> _initFolder() async {
    final dir = Provider.of<SettingsModel>(context, listen: false).docPath;
    folder = Directory('$dir/${widget.uuid}');
    if (!(await folder.exists())) {
      await folder.create(recursive: true);
    }
    _loadFiles();
  }

  Future<void> _loadFiles() async {
    final exists = await folder.exists();
    if (!exists) return;
    final list = folder.listSync().whereType<File>().toList();

    setState(() {
      files = list;
    });
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
    final file = File('${folder.path}/${formattedTime}_$selected.json');
    await file.writeAsString('New file');
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
          Card(
            child: Column(
              children: [
                TableCalendar(
                  locale: 'zh_CN',
                  focusedDay: _focusedDay,
                  firstDay: DateTime.utc(2020, 1, 1),
                  lastDay: DateTime.utc(2030, 12, 31),
                  calendarFormat: _format,
                  selectedDayPredicate: (day) => isSameDay(day, _selectedDay),
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
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
          ),
          files.isEmpty
              ? const Center(child: Text('暂无文件'))
              : ListView.builder(
                  itemCount: files.length,
                  itemBuilder: (context, index) {
                    final file = files[index];
                    return Card(
                      child: ListTile(
                        title: Text(file.path),
                        onTap: () => openEditPage(file),
                        onLongPress: () {
                          showBottomSheet(
                            context: context,
                            builder: (BuildContext context) {
                              return Container(child: Text('tobefilled'));
                            },
                          );
                        },
                        trailing: _deletemode
                            ? IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () async {
                                  await file.delete();
                                  setState(() {
                                    files.removeAt(index);
                                  });
                                },
                              )
                            : null,
                      ),
                    );
                  },
                ),
        ],
      ),
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
}
