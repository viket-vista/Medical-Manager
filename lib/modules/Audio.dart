// audio_player_service.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:audioplayers/audioplayers.dart';

class AudioPlayerService {
  dynamic _audioPlayer;
  bool isPlaying = false;
  bool isPausing = false;
  int playingIndex = -1;
  Duration currentPosition = Duration.zero;
  Duration totalDuration = Duration.zero;

  AudioPlayerService() {
    if (Platform.isAndroid || Platform.isIOS) {
      _audioPlayer = FlutterSoundPlayer();
      _audioPlayer.openPlayer();
    } else {
      _audioPlayer = AudioPlayer();
    }
  }

  Future<void> play({
    required FileSystemEntity file, 
    required int index,
    required VoidCallback onPositionChanged,
    required VoidCallback onDurationChanged,
    required VoidCallback onPlaybackEnd,
  }) async {
    if (Platform.isIOS || Platform.isAndroid) {
      await _audioPlayer.setSubscriptionDuration(Duration(milliseconds: 100));
      await _audioPlayer.startPlayer(
        fromURI: file.path,
        codec: Codec.aacADTS,
        whenFinished: onPlaybackEnd,
      );
      _audioPlayer.onProgress!.listen((duration) {
        totalDuration = duration.duration;
        currentPosition = duration.position;
        onPositionChanged();
      });
    } else {
      _audioPlayer.play(DeviceFileSource(file.path));
      _audioPlayer.onPositionChanged.listen((position) {
        currentPosition = position;
        onPositionChanged();
      });
      _audioPlayer.onDurationChanged.listen((duration) {
        totalDuration = duration;
        onDurationChanged();
      });
    }

    isPlaying = true;
    playingIndex = index;
    isPausing = false;
  }

  Future<void> pause() async {
    if (Platform.isAndroid || Platform.isIOS) {
      await _audioPlayer.pausePlayer();
    } else {
      await _audioPlayer.pause();
    }
    isPausing = true;
  }

  Future<void> resume() async {
    if (Platform.isAndroid || Platform.isIOS) {
      await _audioPlayer.resumePlayer();
    } else {
      await _audioPlayer.resume();
    }
    isPausing = false;
  }

  Future<void> stop() async {
    if (Platform.isAndroid || Platform.isIOS) {
      await _audioPlayer.stopPlayer();
    } else {
      await _audioPlayer.stop();
    }
    isPlaying = false;
    playingIndex = -1;
    currentPosition = Duration.zero;
    totalDuration = Duration.zero;
    isPausing = false;
  }

  Future<void> seek(Duration position) async {
    if (Platform.isAndroid || Platform.isIOS) {
      await _audioPlayer.seekToPlayer(position);
    } else {
      await _audioPlayer.seek(position);
    }
    currentPosition = position;
  }

  Future<void> dispose() async {
    if (Platform.isAndroid || Platform.isIOS) {
      await _audioPlayer.closePlayer();
    } else {
      await _audioPlayer.stop();
    }
  }
}