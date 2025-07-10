import 'package:flutter/material.dart';
import 'package:medicalmanager/tools/aitool.dart';
import 'package:provider/provider.dart';
import 'package:medicalmanager/models/settings_model.dart';
import 'dart:convert';
import 'dart:async';

class AIPage extends StatefulWidget {
  const AIPage({super.key});

  @override
  _AIPageState createState() => _AIPageState();
}

class _AIPageState extends State<AIPage> {
  final TextEditingController _messageController = TextEditingController();
  late DeepSeekApi _api;
  String _response = '';
  String _displayText = ''; // 用于实时显示流式响应的文本
  String _reasoningResponse = ''; // 用于存储推理响应
  bool _isLoading = false;
  late bool _isStreaming;
  final List<String> _streamResponses = [];
  final List<String> _streamResponses_reasoner = [];
  late SettingsModel settings;
  StreamSubscription? _streamSubscription; // 用于管理流订阅
  final ScrollController _scrollController = ScrollController(); // 用于自动滚动
  final ScrollController _scrollController1 = ScrollController(); // 用于推理响应的自动滚动

  @override
  void initState() {
    super.initState();
    _isStreaming = false;
    // 使用Future.microtask确保在Widget树构建完成后获取Provider
    Future.microtask(() {
      setState(() {
        settings = Provider.of<SettingsModel>(context, listen: false);
        _api = DeepSeekApi(apiKey: settings.apiKey);
        _messageController.text = '你好，介绍一下你自己';
      });
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _streamSubscription?.cancel(); // 取消流订阅
    _scrollController.dispose(); // 释放滚动控制器
    super.dispose();
  }

  Future<void> _sendNormalRequest() async {
    setState(() {
      _isLoading = true;
      _response = '';
      _displayText = ''; // 清空显示文本
    });

    try {
      final messages = [
        {'role': 'user', 'content': _messageController.text},
      ];

      final result = await _api.chatCompletions(
        messages: messages,
        model: settings.model,
        stream: false,
      );

      setState(() {
        _response = result['choices'][0]['message']['content'];
      });
    } catch (e) {
      setState(() {
        _response = 'Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _startStreamRequest() async {
    // 取消之前的订阅（如果有）
    _streamSubscription?.cancel();
    
    setState(() {
      _isStreaming = true;
      _streamResponses.clear();
      _streamResponses_reasoner.clear();
      _displayText = ''; // 重置显示文本
      _response = ''; // 清空普通响应
      _reasoningResponse = ''; // 清空推理响应
    });

    try {
      final messages = [
        {'role': 'user', 'content': _messageController.text},
      ];
      
      // 获取流
      final stream = await _api.chatCompletions(
        messages: messages,
        model: settings.model,
        stream: true,
      );

      // 监听流数据
      _streamSubscription = stream.listen(
        (data) {
          try {
            final jsonData = json.decode(data);
            final content = jsonData['choices']?[0]['delta']?['content'];
            final reasoningcontent = jsonData['choices']?[0]['delta']?['reasoning_content'];
            if (reasoningcontent != null && reasoningcontent.isNotEmpty) {
              setState(() {
                // 添加到响应列表
                _streamResponses_reasoner.add(reasoningcontent);
                // 更新显示文本（打字机效果）
                _reasoningResponse += reasoningcontent;
                
                // 滚动到底部
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollController1.hasClients) {
                    _scrollController1.animateTo(
                      _scrollController1.position.maxScrollExtent,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                    );
                  }
                });
              });
            } else if (content != null && content.isNotEmpty) {
              setState(() {
                // 添加到响应列表
                _streamResponses.add(content);
                // 更新显示文本（打字机效果）
                _displayText += content;
                
                // 滚动到底部
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollController.hasClients) {
                    _scrollController.animateTo(
                      _scrollController.position.maxScrollExtent,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                    );
                  }
                });
              });
            }
          } catch (e) {
            debugPrint('Error parsing stream data: $e');
          }
        },
        onError: (error) {
          setState(() {
            _streamResponses.add('Error: $error');
            _isStreaming = false;
          });
        },
        onDone: () {
          setState(() {
            _isStreaming = false;
          });
        },
        cancelOnError: true,
      );
    } catch (e) {
      setState(() {
        _streamResponses.add('Initialization Error: $e');
        _isStreaming = false;
      });
    }
  }

  void _stopStreaming() {
    _streamSubscription?.cancel();
    setState(() {
      _isStreaming = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DeepSeek API Demo'),
        actions: [
          if (_isStreaming)
            IconButton(
              icon: const Icon(Icons.stop),
              onPressed: _stopStreaming,
              tooltip: '停止接收',
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 消息输入框
            TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                labelText: '消息内容',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            
            // 按钮区域
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.send),
                  label: const Text('普通请求'),
                  onPressed: _isLoading || _isStreaming ? null : _sendNormalRequest,
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.stream),
                  label: const Text('流式请求'),
                  onPressed: _isLoading || _isStreaming ? null : _startStreamRequest,
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // 响应结果标题
            const Text(
              '响应结果:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            
            // 响应内容显示区域
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withAlpha(25),
                      spreadRadius: 1,
                      blurRadius: 3,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: _buildResponseContent(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResponseContent() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('正在请求中...', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }
    
    if (_isStreaming) {
      return SingleChildScrollView(
        controller: _scrollController,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _displayText,
              style: const TextStyle(fontSize: 16, height: 1.5),
            ),
            if (_isStreaming)
              const Padding(
                padding: EdgeInsets.only(top: 8.0),
                child: Row(
                  children: [
                    SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)),
                    SizedBox(width: 8),
                    Text('接收中...', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
          ],
        ),
      );
    }
    
    if (_response.isNotEmpty) {
      return SingleChildScrollView(
        controller: _scrollController,
        child: Text(
          _response,
          style: const TextStyle(fontSize: 16, height: 1.5),
        ),
      );
    }
    
    if (_streamResponses.isNotEmpty) {
      return SingleChildScrollView(
        controller: _scrollController,
        child: Text(
          _streamResponses.join(),
          style: const TextStyle(fontSize: 16, height: 1.5),
        ),
      );
    }
    
    return const Center(
      child: Text(
        '输入消息并点击按钮开始对话',
        style: TextStyle(color: Colors.grey, fontSize: 16),
      ),
    );
  }
}