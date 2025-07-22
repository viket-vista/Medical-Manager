import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:provider/provider.dart';
import 'package:medicalmanager/models/settings_model.dart';
import 'package:flutter/material.dart';
import 'package:medicalmanager/tools/recorder.dart';
import 'package:medicalmanager/tools/player.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class RecordEdit extends StatefulWidget {
  final FileSystemEntity file;
  final String name;
  const RecordEdit({super.key, required this.file, required this.name});
  @override
  State<StatefulWidget> createState() => _RecordPageState();
}

class _RecordPageState extends State<RecordEdit> {
  bool isRecording = false;
  bool isPlaying = false;
  String filName = '';
  final Player player = Player();
  final ScrollController _scrollController = ScrollController();
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
  }

  @override
  Widget build(BuildContext context) {
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
        child: Column(
          children: [
            _buildRecordButtonSection(context),
            _buildAudioFileList(context),
          ],
        ),
      ),
      bottomSheet: isPlaying
          ? Material(elevation: 4.0, child: player.buildPlayer(filName))
          : SizedBox.shrink(),
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
      await File(audioFiles[index].path).delete();
      final json = jsonDecode((widget.file as File).readAsStringSync());
      final String recordDir =
          '${Provider.of<SettingsModel>(context, listen: false).docPath}/data/$uuid/record/${json['id']}/';
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
                          onPressed: () {
                            bool temp = isPlaying;
                            setState(() {
                              filName = file.path;
                              isPlaying = true;
                            });
                            WakelockPlus.disable();
                            player.reset();
                            if (!temp) {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
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
                                builder: (BuildContext context1) {
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
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(context1);
                                        },
                                        child: Text('取消'),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          renameAudio(
                                            index,
                                            textController.text,
                                          );
                                          Navigator.pop(context1);
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
    final json = jsonDecode((widget.file as File).readAsStringSync());
    final String recordDir =
        '${Provider.of<SettingsModel>(context, listen: false).docPath}/data/$uuid/record/${json['id']}/';

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
        return  Text('to be developed');
      },
    );
  }
}
