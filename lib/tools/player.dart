import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path/path.dart' as path;

enum PlayerState { start, stopped, playing, paused, ended }

class Player {
  Duration currentPosition = Duration.zero;
  Duration totalDuration = Duration.zero;
  late AudioPlayer _audioPlayer;
  PlayerState _state = PlayerState.stopped;
  Function _currentOnComplete = () {};

  void init(Function onPlayerComplete) {
    _audioPlayer = AudioPlayer();
    _currentOnComplete = onPlayerComplete;
    _setupListeners();
  }

  void _setupListeners() {
    _audioPlayer.onPositionChanged.listen((position) {
      currentPosition = position;
    });
    _audioPlayer.onDurationChanged.listen((duration) {
      totalDuration = duration;
    });
    _audioPlayer.onPlayerComplete.listen((_) {
      _state = PlayerState.ended;
      currentPosition = Duration.zero;
      _currentOnComplete();
    });
  }

  Future<void> reset() async {
    await _audioPlayer.stop();
    _state = PlayerState.stopped;
    totalDuration = Duration.zero;
    currentPosition = Duration.zero;
  }

  Future<void> _playAudio({required String fileName}) async {
    try {
      await _audioPlayer.play(DeviceFileSource(fileName));
      _state = PlayerState.playing;
    } catch (e) {
      debugPrint('播放错误: $e');
    }
  }
  Future<void> pause() async {
    await _audioPlayer.pause();
    _state = PlayerState.paused;
  }
  Future<void> resume() async {
    await _audioPlayer.resume();
    _state = PlayerState.playing;
  }
  Widget buildPlayer(String fileName) {
    return StatefulBuilder(
      builder: (context, setState) {
        if (_state == PlayerState.stopped) {
          _handlePlayPause(fileName: fileName, setState: setState);
        }
        return Container(
          padding: EdgeInsets.all(16),
          height: 100,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 25,
                child: Row(
                  children: [
                    Expanded(
                      child: Slider(
                        value: currentPosition.inMilliseconds.toDouble(),
                        max: totalDuration.inMilliseconds.toDouble().clamp(
                          1,
                          double.infinity,
                        ),
                        onChangeStart: (value) {
                          _audioPlayer.pause();
                          setState(() => _state = PlayerState.paused);
                        },
                        onChanged: (value) {
                          final newPos = Duration(milliseconds: value.toInt());
                          _audioPlayer.seek(newPos);
                          setState(() => currentPosition = newPos);
                        },
                        onChangeEnd: (value) {
                          _audioPlayer.resume();
                          setState(() => _state = PlayerState.playing);
                        },
                      ),
                    ),
                    Text(
                      '${_formatDuration(currentPosition)}/${_formatDuration(totalDuration)}',
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Icon(
                      _state == PlayerState.playing
                          ? Icons.pause
                          : Icons.play_arrow,
                    ),
                    onPressed: () {
                      _handlePlayPause(fileName: fileName, setState: setState);
                    },
                  ),
                  if (_state != PlayerState.stopped)
                    IconButton(
                      icon: Icon(Icons.stop),
                      onPressed: () {
                        _handleStop(setState);
                        _currentOnComplete();
                      },
                    ),
                  Spacer(),
                  Text('正在播放：${path.basename(fileName)}'),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _handlePlayPause({
    required String fileName,
    required void Function(void Function()) setState,
  }) {
    if (_state == PlayerState.playing) {
      _audioPlayer.pause();
      setState(() => _state = PlayerState.paused);
    } else {
      _playAudio(fileName: fileName);
      setState(() => _state = PlayerState.playing);
    }
  }

  void _handleStop(void Function(void Function()) setState) {
    _audioPlayer.stop();
    setState(() {
      _state = PlayerState.stopped;
      currentPosition = Duration.zero;
    });
  }

  String _formatDuration(Duration d) {
    return "${d.inMinutes.toString().padLeft(2, '0')}:"
        "${(d.inSeconds % 60).toString().padLeft(2, '0')}";
  }

  void dispose() {
    _audioPlayer.dispose();
  }
}
