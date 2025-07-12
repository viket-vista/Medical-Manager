import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:permission_handler/permission_handler.dart';

class AudioRecorderController with ChangeNotifier {
  final FlutterSoundRecorder _audioRecorder = FlutterSoundRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isRecording = false;
  bool _isPlaying = false;
  bool _isPaused = false;
  int _playingIndex = -1;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  Duration _recordingDuration = Duration.zero;
  String? _currentRecordingPath;
  List<FileSystemEntity> _audioFiles = [];

  bool get isRecording => _isRecording;
  bool get isPlaying => _isPlaying;
  bool get isPaused => _isPaused;
  int get playingIndex => _playingIndex;
  Duration get currentPosition => _currentPosition;
  Duration get totalDuration => _totalDuration;
  Duration get recordingDuration => _recordingDuration;
  List<FileSystemEntity> get audioFiles => _audioFiles;

  Future<void> init() async {
    await _audioRecorder.openRecorder();
    if (kIsWeb) {
      await _audioPlayer.setSource(DeviceFileSource(''));
    }
  }

  Future<void> play(FileSystemEntity file, int index) async {
    if (_isPlaying && _playingIndex == index) {
      await togglePause();
      return;
    }

    await stopPlayer();
    
    if (Platform.isAndroid || Platform.isIOS) {
      await _audioPlayer.play(DeviceFileSource(file.path));
    } else {
      await _audioPlayer.play(DeviceFileSource(file.path));
    }

    _setupPlayerListeners();
    
    _playingIndex = index;
    _isPlaying = true;
    _isPaused = false;
    notifyListeners();
  }

  Future<void> togglePause() async {
    if (_isPaused) {
      await _audioPlayer.resume();
    } else {
      await _audioPlayer.pause();
    }
    _isPaused = !_isPaused;
    notifyListeners();
  }

  Future<void> stopPlayer() async {
    await _audioPlayer.stop();
    _playingIndex = -1;
    _isPlaying = false;
    _isPaused = false;
    _currentPosition = Duration.zero;
    notifyListeners();
  }

  Future<void> toggleRecording(String recordDir) async {
    if (_isRecording) {
      await _stopRecording(recordDir);
    } else {
      await _startRecording(recordDir);
    }
  }

  Future<void> _startRecording(String recordDir) async {
    await Permission.microphone.request();
    
    int idx = 1;
    while (File('$recordDir${idx.toString().padLeft(4, '0')}.aac').existsSync()) {
      idx++;
    }
    
    _currentRecordingPath = '$recordDir${idx.toString().padLeft(4, '0')}.aac';
    await Directory(recordDir).create(recursive: true);
    
    await _audioRecorder.startRecorder(
      toFile: _currentRecordingPath,
      codec: Codec.aacADTS,
    );
    
    _isRecording = true;
    _recordingDuration = Duration.zero;
    
    _audioRecorder.onProgress!.listen((event) {
      _recordingDuration = event.duration;
      notifyListeners();
    });
    
    notifyListeners();
  }

  Future<void> _stopRecording(String recordDir) async {
    await _audioRecorder.stopRecorder();
    _isRecording = false;
    _currentRecordingPath = null;
    _recordingDuration = Duration.zero;
    await _loadAudioFiles(recordDir);
    notifyListeners();
  }

  Future<void> _loadAudioFiles(String recordDir) async {
    final dir = Directory(recordDir);
    if (!await dir.exists()) return;
    
    _audioFiles = dir.listSync()
      .where((f) => f.path.endsWith('.aac'))
      .toList()
      ..sort((a, b) => a.path.compareTo(b.path));
    
    notifyListeners();
  }

  Future<void> deleteAudio(int index, String recordDir) async {
    await File(_audioFiles[index].path).delete();
    await _loadAudioFiles(recordDir);
    if (_playingIndex == index) {
      await stopPlayer();
    }
  }

  Future<void> renameAudio(int index, String newName, String recordDir) async {
    if (newName.isEmpty) return;
    
    final newPath = '${_audioFiles[index].parent.path}/$newName${newName.endsWith('.aac') ? '' : '.aac'}';
    await _audioFiles[index].rename(newPath);
    await _loadAudioFiles(recordDir);
  }

  void _setupPlayerListeners() {
    _audioPlayer.onPositionChanged.listen((position) {
      _currentPosition = position;
      notifyListeners();
    });
    
    _audioPlayer.onDurationChanged.listen((duration) {
      _totalDuration = duration;
      notifyListeners();
    });
    
    _audioPlayer.onPlayerComplete.listen((_) {
      stopPlayer();
    });
  }

  void seek(Duration duration){
    
  }

  @override
  void dispose() {
    _audioRecorder.closeRecorder();
    _audioPlayer.dispose();
    super.dispose();
  }
}