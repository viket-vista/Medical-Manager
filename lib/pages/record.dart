import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class RecordPage extends StatefulWidget {
  final String uuid;
  const RecordPage({Key? key, required this.uuid}) : super(key: key);

  @override
  State<RecordPage> createState() => _RecordPageState();
}

class _RecordPageState extends State<RecordPage> {
  late Directory folder;
  List<FileSystemEntity> files = [];

  @override
  void initState() {
    super.initState();
    _initFolder();
  }

  Future<void> _initFolder() async {
    final dir = await getApplicationDocumentsDirectory();
    folder = Directory('${dir.path}/${widget.uuid}');
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
            .map((opt) => SimpleDialogOption(
                  child: Text(opt),
                  onPressed: () => Navigator.pop(context, opt),
                ))
            .toList(),
      ),
    );
    if (selected == null) return;
    final now = DateTime.now();
    final formattedTime =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}';
    final file = File('${folder.path}/$selected\_$formattedTime.json');
    await file.writeAsString('New file');
    _loadFiles();
  }

  void _deleteFiles() async {
    for (var f in files) {
      if (f is File) await f.delete();
    }
    _loadFiles();
  }

  void _openBlankPage() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const BlankPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('UUID: ${widget.uuid}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: '插入',
            onPressed: _insertFile,
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            tooltip: '删除',
            onPressed: _deleteFiles,
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
                  onTap: _openBlankPage,
                );
              },
            ),
    );
  }
}

class BlankPage extends StatelessWidget {
  const BlankPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('新页面')),
      body: const Center(child: Text('空白页面')),
    );
  }
}