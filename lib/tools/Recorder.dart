import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';

class Recorder {
  late FlutterSoundRecorder _recorder;
  bool _isRecording = false;
  final Function(Duration duration)? onProgress;
  StreamSubscription<RecordingDisposition>? _progressSubscription;
  Duration _recordingDuration = Duration.zero;

  Recorder({this.onProgress});

  Future<void> init() async {
    if (Platform.isAndroid || Platform.isIOS) {
      _recorder = FlutterSoundRecorder();
      await _recorder.openRecorder(isBGService: false);
    }
  }

  Future<void> start(String toFile) async {
    if (Platform.isAndroid || Platform.isIOS) {
      await _recorder.startRecorder(toFile: toFile);
      _recorder.setSubscriptionDuration(const Duration(milliseconds: 100));

      _progressSubscription = _recorder.onProgress?.listen((event) {
        _recordingDuration = event.duration;
        if (onProgress != null) {
          onProgress!(event.duration);
        }
      });
    }
  }

  Future<void> stop() async {
    if (Platform.isAndroid || Platform.isIOS && _isRecording) {
      await _recorder.stopRecorder();
      await _progressSubscription?.cancel();
      _progressSubscription = null;
    }
  }

  Future<void> dispose() async {
    await stop();
    if (Platform.isAndroid || Platform.isIOS) {
      await _recorder.closeRecorder();
    }
  }

  Widget buildRecorderButton(BuildContext context, String dirName) {
    int idx = 1;
    while (File('$dirName${idx.toString().padLeft(4, '0')}.aac').existsSync()) {
      idx++;
    }
    if (Directory(dirName).existsSync()) {
      Directory(dirName).createSync(recursive: true);
    }
    String currentRecordingPath =
        '$dirName${idx.toString().padLeft(4, '0')}.aac';
    return StatefulBuilder(
      builder: (context, setState) {
        return ElevatedButton(
          onPressed: ()  {
            if (_isRecording) {
              stop();
            } else {
              start(currentRecordingPath);
            }
            setState(() {
              _isRecording = !_isRecording;
            });
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: _isRecording ? Colors.red[400] : null,
            foregroundColor: _isRecording ? Colors.white : null,
            animationDuration: const Duration(milliseconds: 200),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (child, animation) {
                  return ScaleTransition(
                    scale: animation,
                    child: FadeTransition(opacity: animation, child: child),
                  );
                },
                child: Icon(
                  key: ValueKey<bool>(_isRecording),
                  _isRecording ? Icons.stop : Icons.mic,
                  color: _isRecording
                      ? Colors.white
                      : Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 8),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 150),
                style: TextStyle(
                  fontWeight: _isRecording
                      ? FontWeight.bold
                      : FontWeight.normal,
                  color: _isRecording
                      ? Colors.white
                      : Theme.of(context).colorScheme.primary,
                ),
                child: Text(
                  _isRecording
                      ? '  ${_recordingDuration.inMinutes.toString().padLeft(2, '0')}:${(_recordingDuration.inSeconds % 60).toString().padLeft(2, '0')}   '
                      : '点击开始',
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
