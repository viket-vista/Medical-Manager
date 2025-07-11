import 'dart:io';

import 'package:flutter/material.dart';

class RecordEdit extends StatefulWidget {
  final FileSystemEntity file;
  const RecordEdit({super.key, required this.file});
  @override
  State<StatefulWidget> createState() => _RecordPageState();
}

class _RecordPageState extends State<RecordEdit> {
  @override
  void initState() {
    super.initState();
    // 初始化逻辑（如果有）
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(appBar: AppBar(title: Text(widget.file.path)));
  }
}
