import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'RecordEdit.dart';
import 'package:provider/provider.dart';
import 'package:medicalmanager/models/settings_model.dart';

class RecordPage extends StatefulWidget {
  final String uuid;
  final String name;
  const RecordPage({Key? key, required this.uuid, required this.name})
    : super(key: key);

  @override
  State<RecordPage> createState() => _RecordPageState();
}

class _RecordPageState extends State<RecordPage> {
  late Directory folder;
  List<FileSystemEntity> files = [];
  late bool _deletemode;

  @override
  void initState() {
    super.initState();
    _deletemode = false;
    _initFolder();
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
    final list = folder
        .listSync()
        .whereType<File>()
        .where((f) => f.path.toLowerCase().endsWith('.json'))
        .toList();

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
    final formattedTime =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final file = File('${folder.path}/${selected}_$formattedTime.json');
    await file.writeAsString('New file');
    _loadFiles();
  }

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
      body: files.isEmpty
          ? const Center(child: Text('暂无文件'))
          : ListView.builder(
              itemCount: files.length,
              itemBuilder: (context, index) {
                final file = files[index];
                return ListTile(
                  title: Text(file.path.split(Platform.pathSeparator).last),
                  onTap: () => openEditPage(file),
                  onLongPress: () {
                    showBottomSheet(context: context, builder: (BuildContext context){return Container(child: Text('tobefilled'),);});
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
                );
              },
            ),
    );
  }

  openEditPage(FileSystemEntity fil) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => RecordEdit(file: fil,name: widget.name,)),
    );
  }
}
