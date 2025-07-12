import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:provider/provider.dart';
import 'package:medicalmanager/models/settings_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:medicalmanager/tools/recorder.dart';

class RecordEdit extends StatefulWidget {
  final FileSystemEntity file;
  final String name;
  const RecordEdit({super.key, required this.file, required this.name});
  @override
  State<StatefulWidget> createState() => _RecordPageState();
}

class _RecordPageState extends State<RecordEdit> {
  bool isRecording = false;
  Duration recordingDuration = Duration.zero;
  Duration totalDuration = Duration.zero;
  List<FileSystemEntity> audioFiles = [];
  String uuid = '';
  late final Recorder recorder;
  @override
  void initState() {
    super.initState();
    recorder = Recorder(
      onProgress: (duration) {
        setState(() {
          recordingDuration = duration;
        });
      },
    );
    recorder.init();
    // 初始化逻辑（如果有）
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${widget.name}:${path.basenameWithoutExtension(widget.file.path)}',
        ),
        actions: [
          IconButton(
            onPressed: () {
              buildMenu();
            },
            icon: Icon(Icons.more_horiz),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(children: [_buildRecordButtonSection(context), _buildAudioFileList(context)]),
      ),
    );
  }

  Widget _buildAudioFileList(BuildContext context) {
    Future<void> deleteAudio(int index) async {
      bool delete = false;
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('确认删除'),
            content: const Text('确定要删除这个录音文件吗？'),
            actions: [
              TextButton(
                onPressed: () async {
                  delete = true;
                  Navigator.pop(context);
                },
                child: const Text('删除'),
              ),
              TextButton(
                onPressed: () {
                  delete = false;
                  Navigator.pop(context);
                },
                child: const Text('取消'),
              ),
            ],
          );
        },
      );
      if (!delete) return;
      if (Platform.isAndroid || Platform.isIOS) {
      } else {}
      await File(audioFiles[index].path).delete();

      final String recordDir =
          '${Provider.of<SettingsModel>(context, listen: false).docPath}/data/$uuid/record/${path.basenameWithoutExtension(widget.file.path)}/';
      await _loadAudioFiles(recordDir);
    }

    Future<void> renameAudio(int index, String newName) async {
      if (newName.isNotEmpty) {
        final newPath =
            '${audioFiles[index].parent.path}/$newName${newName.endsWith('.aac') ? '' : '.aac'}';
        await audioFiles[index].rename(newPath);
        setState(() {
          audioFiles[index] = File(newPath);
        });
        Navigator.pop(context);
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
            final fileName = file.path.split(Platform.pathSeparator).last;
            //final isThisPlaying = playingIndex == index && isPlaying;
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.play_arrow),
                          onPressed: () {},
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
            );
          }),
        ],
      ),
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

  Widget _buildRecordButtonSection(BuildContext context) {
    final String recordDir =
        '${Provider.of<SettingsModel>(context, listen: false).docPath}/data/$uuid/record/${path.basenameWithoutExtension(widget.file.path)}/';

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
              onPressed: () {},
              label: const Text('根据表单生成病程记录'),
            ),
          ],
        ),
      ),
    );
  }

  void buildMenu() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(child: Text('to be developed'));
      },
    );
  }
}
