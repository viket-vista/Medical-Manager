import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:medicalmanager/models/settings_model.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photo_view/photo_view.dart';
import 'package:path/path.dart' as path; // 添加路径处理包

class ImageGalleryPage extends StatefulWidget {
  final List<dynamic> imageData;
  final String uuid;
  final Function(List<dynamic>) onreturn; // 明确类型
  final String name;

  const ImageGalleryPage({
    super.key,
    required this.imageData,
    required this.uuid,
    required this.onreturn,
    required this.name,
  });

  @override
  State<ImageGalleryPage> createState() => _ImageGalleryPageState();
}

class _ImageGalleryPageState extends State<ImageGalleryPage> {
  late List<String> _images;
  Directory? _imageDirectory; // 改为可空
  bool _isLoading = true; // 添加加载状态
  bool _hasError = false; // 添加错误状态

  @override
  void initState() {
    super.initState();
    _images = [...widget.imageData.map((e) => e.toString())]; // 创建副本
    _initializeDirectory(); // 异步初始化目录
  }

  // 异步初始化目录
  Future<void> _initializeDirectory() async {
    try {
      final dirsetting = Provider.of<SettingsModel>(context, listen: false);
      final docPath = dirsetting.docPath;

      // 确保UUID不为空
      if (widget.uuid.isEmpty) {
        throw Exception('UUID为空');
      }

      final dirPath = path.join(docPath, 'data', widget.uuid, 'pictures');
      final dir = Directory(dirPath);

      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      setState(() {
        _imageDirectory = dir;
        _isLoading = false;
      });
    } catch (e) {
      print('初始化目录失败: $e');
      setState(() {
        _isLoading = false;
        _hasError = true;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('无法创建图片目录: ${e.toString()}')));
    }
  }

  // 添加图片
  Future<void> _addImage(ImageSource source) async {
    if (_imageDirectory == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('图片目录未准备好，请稍后再试')));
      return;
    }

    final picker = ImagePicker();
    try {
      final pickedFile = await picker.pickImage(source: source);

      if (pickedFile != null) {
        // 生成唯一文件名
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final ext = path.extension(pickedFile.path); // 保留原始扩展名
        final filename = '$timestamp$ext';
        final destPath = path.join(_imageDirectory!.path, filename);

        await File(pickedFile.path).copy(destPath);

        setState(() {
          _images.add(filename); // 只存储文件名
        });
      }
    } catch (e) {
      print('添加图片失败: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('添加图片失败: ${e.toString()}')));
    }
  }

  // 删除图片
  Future<void> _deleteImage(int index) async {
    if (_imageDirectory == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('您确定要删除这张图片吗？此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final filename = _images[index];
        final filePath = path.join(_imageDirectory!.path, filename);
        final file = File(filePath);

        if (await file.exists()) {
          await file.delete();
        }

        setState(() {
          _images.removeAt(index);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('图片已删除'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      } catch (e) {
        print('删除图片失败: $e');
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('删除图片失败: ${e.toString()}')));
      }
    }
  }

  // 显示添加图片选项
  void _showAddImageOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.blue),
              title: const Text('拍照'),
              onTap: () {
                Navigator.pop(context);
                _addImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.green),
              title: const Text('从相册选择'),
              onTap: () {
                Navigator.pop(context);
                _addImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.close, color: Colors.grey),
              title: const Text('取消'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  // 查看大图（支持缩放）
  void _viewFullImage(int index) {
    if (_imageDirectory == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FullScreenImageViewer(
          images: _images,
          imageDirectory: _imageDirectory!,
          initialIndex: index,
        ),
      ),
    );
  }

  // 退出页面
  void _exitWithValue() {
    widget.onreturn(_images); // 回调更新数据
    Navigator.pop(context, _images);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) {
          _exitWithValue(); // 处理手势退出
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.name),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _exitWithValue, // 处理返回按钮
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.add_a_photo),
              onPressed: _showAddImageOptions,
              tooltip: '添加图片',
            ),
          ],
        ),
        body: _buildBody(),
      ),
    );
  }

  // 构建主体内容
  Widget _buildBody() {
    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text('初始化失败', style: TextStyle(fontSize: 24)),
            const SizedBox(height: 8),
            const Text('无法创建图片目录，请检查权限'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _initializeDirectory,
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_imageDirectory == null) {
      return const Center(child: Text('目录初始化失败'));
    }

    return _images.isEmpty ? _buildEmptyState() : _buildImageGrid();
  }

  // 空状态界面
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.photo_library, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 20),
          const Text(
            '暂无图片',
            style: TextStyle(fontSize: 24, color: Colors.grey),
          ),
          const SizedBox(height: 10),
          const Text('点击右上角按钮添加图片', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            icon: const Icon(Icons.add_a_photo),
            label: const Text('添加图片'),
            onPressed: _showAddImageOptions,
          ),
        ],
      ),
    );
  }

  // 图片网格视图
  Widget _buildImageGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 0.8,
      ),
      itemCount: _images.length,
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () => _showImageActionDialog(context, index), // 修改这里
          child: _buildImageItem(index),
        );
      },
    );
  }

  // 添加对话框方法（与之前相同但适配网格视图）
  Future<void> _showImageActionDialog(BuildContext context, int index) async {
    final imagePath = path.join(_imageDirectory!.path, _images[index]);

    final result = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("选择操作"),
          content: Text("您要对这张图片执行什么操作？"),
          actions: [
            TextButton(
              child: Text("解析", style: TextStyle(color: Colors.blue[300])),
              onPressed: () => Navigator.pop(context, 'analyze'),
            ),
            TextButton(
              child: Text("查看", style: TextStyle(color: Colors.green[300])),
              onPressed: () => Navigator.pop(context, 'view'),
            ),
            TextButton(
              child: Text("取消", style: TextStyle(color: Colors.grey)),
              onPressed: () => Navigator.pop(context, 'cancel'),
            ),
          ],
        );
      },
    );

    if (result == 'analyze') {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return Dialog(
            child: AlertDialog(
              title: const Text('解析功能尚未实现'),
              content: Text('imagePath: ${_images[index]}\n请稍后再试。'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('确定'),
                ),
              ],
            ),
          );
        },
      );

      //_analyzeImage(imagePath);
    } else if (result == 'view') {
      _viewFullImage(index); // 调用原有的全屏查看方法
    }
  }

  // 单个图片项
  Widget _buildImageItem(int index) {
    final filename = _images[index];
    final filePath = path.join(_imageDirectory!.path, filename);

    return Stack(
      fit: StackFit.expand,
      children: [
        // 图片
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.file(
            File(filePath),
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Colors.grey[200],
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.broken_image, color: Colors.grey),
                      const SizedBox(height: 8),
                      Text(
                        filename,
                        style: const TextStyle(fontSize: 10),
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        // 图片信息
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(8),
                bottomRight: Radius.circular(8),
              ),
            ),
            child: Text(
              filename,
              style: const TextStyle(color: Colors.white, fontSize: 10),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),

        // 删除按钮
        Positioned(
          top: 4,
          right: 4,
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.delete, size: 18, color: Colors.white),
              onPressed: () => _deleteImage(index),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ),
        ),
      ],
    );
  }
}

// 全屏图片查看器（支持缩放和滑动）
class FullScreenImageViewer extends StatefulWidget {
  final List<String> images;
  final Directory imageDirectory;
  final int initialIndex;

  const FullScreenImageViewer({
    super.key,
    required this.images,
    required this.imageDirectory,
    this.initialIndex = 0,
  });

  @override
  State<FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<FullScreenImageViewer> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          // 图片查看区域（添加了GestureDetector）
          PageView.builder(
            controller: _pageController,
            itemCount: widget.images.length,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemBuilder: (context, index) {
              final imagePath = path.join(
                widget.imageDirectory.path,
                widget.images[index],
              );
              return InteractiveViewer(
                panEnabled: true,
                minScale: 0.1,
                maxScale: 5.0,
                child: Center(
                  child: Image.file(
                    File(imagePath),
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(
                        child: Icon(
                          Icons.broken_image,
                          color: Colors.grey,
                          size: 50,
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),

          // 图片索引指示器
          if (widget.images.length > 1)
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  widget.images.length,
                  (index) => Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _currentIndex == index
                          ? Colors.white
                          : Colors.white.withAlpha(128),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
