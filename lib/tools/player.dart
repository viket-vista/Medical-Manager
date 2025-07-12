import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path/path.dart' as path;

enum PlayerState { start, stopped, playing, paused, ended }

class Player {
  Duration currentPosition = Duration.zero;
  Duration totalDuration = Duration.zero;
  late AudioPlayer _audioPlayer;
  PlayerState _state = PlayerState.stopped;

  void init() {
    _audioPlayer = AudioPlayer();
  }

  void _setupListeners(Function? onPlayerComplete) {
    _audioPlayer.onPositionChanged.listen((position) {
      currentPosition = position;
    });
    _audioPlayer.onDurationChanged.listen((duration) {
      totalDuration = duration;
    });
    _audioPlayer.onPlayerComplete.listen((_) {
      _state = PlayerState.ended;
      currentPosition = Duration.zero;
    });
  }

  Future<void> _playAudio({
    required String fileName,
    Function? onPlayerComplete,
  }) async {
    _setupListeners(onPlayerComplete);
    try {
      await _audioPlayer.play(DeviceFileSource(fileName));
      _state = PlayerState.playing;
    } catch (e) {
      debugPrint('播放错误: $e');
    }
  }

  Widget buildPlayer(String fileName, Function onPlayerComplete) {
    return StatefulBuilder(
      builder: (context, setState) {
        if (_state == PlayerState.stopped) {
          _handlePlayPause(fileName, setState);
        }
        return Container(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Icon(
                      _state == PlayerState.playing
                          ? Icons.pause
                          : Icons.play_arrow,
                    ),
                    onPressed: () => _handlePlayPause(fileName, setState),
                  ),
                  if (_state != PlayerState.stopped)
                    IconButton(
                      icon: Icon(Icons.stop),
                      onPressed: () {
                        _handleStop(setState);
                        onPlayerComplete();
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

  void _handlePlayPause(
    String fileName,
    void Function(void Function()) setState,
  ) {
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
