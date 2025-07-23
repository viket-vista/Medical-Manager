import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:medicalmanager/models/global.dart' as globals;
import 'package:path/path.dart' as path;

void showProgressDialog(
  BuildContext context, {
  required String title,
  String? message,
}) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      title: Text(title, maxLines: 1, overflow: TextOverflow.fade),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (message != null)
            Text(message, maxLines: 1, overflow: TextOverflow.fade),
          const SizedBox(height: 16),
          const CircularProgressIndicator(),
        ],
      ),
    ),
  );
}

void updateProgressDialog(
  BuildContext context, {
  String? newTitle,
  String? newMessage,
}) {
  Navigator.of(context).pop();
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      title: newTitle != null
          ? Text(newTitle, maxLines: 1, overflow: TextOverflow.fade)
          : null,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (newMessage != null)
            Text(newMessage, maxLines: 1, overflow: TextOverflow.fade),
          const SizedBox(height: 16),
          const CircularProgressIndicator(),
        ],
      ),
    ),
  );
}

void hideProgressDialog(BuildContext context) {
  Navigator.of(context).pop();
}

Future<void> compressDirectoryToZip({
  required Directory sourceDir,
  required File zipFile,
  List<String> additionalFiles = const [],
}) async {
  final bytes = await compressDirectoryByte(
    sourceDir: sourceDir,
    additionalFiles: additionalFiles,
  );
  zipFile.writeAsBytes(bytes);
}

Future<List<int>> compressDirectoryByte({
  required Directory sourceDir,
  List<String> additionalFiles = const [], // 新增参数，默认为空列表
  String? root,
}) async {
  BuildContext context = globals.navigatorKey.currentContext!;
  // 显示进度对话框
  showProgressDialog(context, title: '正在压缩', message: '准备文件中...');

  try {
    final archive = Archive();

    // 1. 首先处理目录内容
    final dirFiles = await sourceDir.list(recursive: true).toList();
    int processed = 0;
    int totalFiles = dirFiles.whereType<File>().length + additionalFiles.length;

    // 处理目录中的文件
    for (final file in dirFiles) {
      if (file is File) {
        processed++;
        updateProgressDialog(
          context,
          newTitle: '正在压缩',
          newMessage: '处理文件中 ($processed/$totalFiles)...\n${file.path}',
        );
        late final String relativePath;
        final fileData = await file.readAsBytes();
        if (root != null) {
          relativePath = path.relative(file.path, from: root);
        } else {
          relativePath = file.path.substring(sourceDir.path.length + 1);
        }
        archive.addFile(ArchiveFile(relativePath, fileData.length, fileData));
      }
    }

    // 2. 然后处理额外文件（添加到根目录）
    for (final filePath in additionalFiles) {
      final file = File(filePath);
      if (await file.exists()) {
        processed++;
        updateProgressDialog(
          context,
          newTitle: '正在压缩',
          newMessage: '添加额外文件 ($processed/$totalFiles)...\n${file.path}',
        );

        final fileData = await file.readAsBytes();
        final fileName = path.basename(filePath);
        archive.addFile(ArchiveFile(fileName, fileData.length, fileData));
      }
    }

    // 更新为编码状态
    updateProgressDialog(context, newTitle: '正在压缩', newMessage: '编码ZIP文件...');

    final zipData = ZipEncoder().encode(archive);
    if (zipData == null) throw Exception('ZIP编码失败');

    // 更新为写入状态
    updateProgressDialog(context, newTitle: '正在压缩', newMessage: '写入ZIP文件...');

    // 完成
    hideProgressDialog(context);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('压缩完成')));

    return zipData;
  } catch (e) {
    hideProgressDialog(context);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('压缩失败: $e')));
    rethrow;
  }
}

Future<void> decompressZipToDirectory({
  required List<int> contentBytes,
  required Directory desDir,
}) async {
  BuildContext context = globals.navigatorKey.currentContext!;
  // 显示进度对话框
  showProgressDialog(context, title: '正在解压', message: '准备文件中...');

  try {
    // 更新为解码状态
    updateProgressDialog(context, newTitle: '正在解压', newMessage: '解码ZIP文件...');

    final zipArchive = ZipDecoder().decodeBytes(contentBytes);
    final files = zipArchive.files.where((f) => f.isFile).toList();
    int processed = 0;

    // 确保目标目录存在
    if (!await desDir.exists()) {
      await desDir.create(recursive: true);
    }

    for (final file in files) {
      // 更新进度
      processed++;
      updateProgressDialog(
        context,
        newTitle: '正在解压',
        newMessage: '解压文件中 ($processed/${files.length})...\n${file.name}',
      );

      final outputPath = '${desDir.path}/${file.name}';
      final outputFile = File(outputPath);
      await outputFile.parent.create(recursive: true);
      await outputFile.writeAsBytes(file.content);
    }

    // 完成
    hideProgressDialog(context);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('解压完成')));
  } catch (e) {
    hideProgressDialog(context);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('解压失败: $e')));
    rethrow;
  }
}

Future<void> decompressZipStreamToDirectoryChunked({
  required Stream<List<int>> zipStream,
  required Directory desDir,
}) async {
  final context = globals.navigatorKey.currentContext!;

  // 显示进度对话框
  showProgressDialog(context, title: '正在解压', message: '准备文件中...');

  try {
    // 收集数据流到字节数组
    updateProgressDialog(context, newTitle: '正在解压', newMessage: '接收数据流...');

    final completer = Completer<List<int>>();
    final bytes = <int>[];

    final subscription = zipStream.listen(
      (chunk) {
        bytes.addAll(chunk);

        // 更新进度（如果知道总大小）
      },
      onError: completer.completeError,
      onDone: () => completer.complete(bytes),
    );
    await completer.future;
    await subscription.cancel();

    // 解码ZIP文件
    updateProgressDialog(context, newTitle: '正在解压', newMessage: '解码ZIP文件...');

    final zipArchive = ZipDecoder().decodeBytes(Uint8List.fromList(bytes));
    final files = zipArchive.files.where((f) => f.isFile).toList();
    int processed = 0;

    // 确保目标目录存在
    if (!await desDir.exists()) {
      await desDir.create(recursive: true);
    }

    // 解压文件
    for (final file in files) {
      processed++;
      updateProgressDialog(
        context,
        newTitle: '正在解压',
        newMessage: '解压文件中 ($processed/${files.length})...\n${file.name}',
      );

      final outputPath = '${desDir.path}/${file.name}';
      final outputFile = File(outputPath);
      await outputFile.parent.create(recursive: true);
      await outputFile.writeAsBytes(file.content as List<int>);
    }

    // 完成
    hideProgressDialog(context);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('解压完成')));
  } catch (e) {
    hideProgressDialog(context);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('解压失败: $e')));
    rethrow;
  }
}
