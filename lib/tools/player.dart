import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

class Player {
  final Function(Duration duration) ontotalDuration;
  final Function(Duration duration) oncurrentPosition;
  late Duration currentPosition;
  late Duration totalDuration;
  int playingIndex = -1;
  bool isPlaying = false;
  bool ispausing = false;
  late AudioPlayer _audioPlayer;
  Player({required this.ontotalDuration, required this.oncurrentPosition});
  void init() {
    _audioPlayer = AudioPlayer();
  }

  void buildPlayer(context, String fileName) {
    Scaffold.of(context).showBottomSheet(
      (context) => StatefulBuilder(
        builder: (context, setState) {
          return Column(
            children: [
              Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Slider(
                          value: currentPosition.inMilliseconds.toDouble(),
                          max: totalDuration.inMilliseconds.toDouble() > 0
                              ? totalDuration.inMilliseconds.toDouble()
                              : 1,
                          onChangeStart: (value) {
                            _audioPlayer.pause();
                          },
                          onChangeEnd: (value) {
                            _audioPlayer.resume();
                          },
                          onChanged: (v) {
                            final newPosition = Duration(
                              milliseconds: v.toInt(),
                            );
                            _audioPlayer.seek(newPosition);
                            setState(() {
                              currentPosition = newPosition;
                            });
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0, right: 8.0),
                        child: Text(
                          "${currentPosition.inMinutes.toString().padLeft(2, '0')}:${(currentPosition.inSeconds % 60).toString().padLeft(2, '0')} / ${totalDuration.inMinutes.toString().padLeft(2, '0')}:${(totalDuration.inSeconds % 60).toString().padLeft(2, '0')}",
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          isPlaying && !ispausing
                              ? Icons.pause
                              : Icons.play_arrow,
                        ),
                        onPressed: () {
                          if (ispausing || !isPlaying) {
                            _audioPlayer.pause();
                            setState(() {
                              isPlaying = true;
                              ispausing = true;
                            });
                          } else {
                            _audioPlayer.play(DeviceFileSource(fileName));
                            _audioPlayer.onPositionChanged.listen((position) {
                              setState(() => currentPosition = position);
                            });
                            _audioPlayer.onDurationChanged.listen((duration) {
                              setState(() {
                                totalDuration = duration;
                              });
                            });
                            _audioPlayer.onPlayerComplete.listen((_){
                              setState(() {
                                isPlaying = false;
                                ispausing = false;
                                totalDuration = Duration.zero;
                                currentPosition = Duration.zero;
                              });
                            });
                            setState(() {
                              ispausing = false;
                              isPlaying = true;
                            });
                          }
                        },
                      ),
                      if (isPlaying)
                        IconButton(
                          onPressed: () {
                            _audioPlayer.stop();
                            setState(() {
                              ispausing = false;
                              isPlaying = false;
                              currentPosition = Duration.zero;
                              totalDuration = Duration.zero;
                            });
                          },
                          icon: Icon(Icons.stop),
                        ),
                    ],
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
