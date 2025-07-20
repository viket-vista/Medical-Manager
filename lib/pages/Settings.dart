import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'dart:io';

import '../models/settings_model.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsModel>(context, listen: true);
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildDeviceName(settings, context),
          const SizedBox(height: 16),
          _buildAutoDarkModeSwitch(settings, context),
          const SizedBox(height: 16),
          _buildDarkModeSwitch(settings, context),
          const SizedBox(height: 16),
          _buildApiKeySetting(settings, context),
          const SizedBox(height: 16),
          _buildSelectAIMode(settings),
        ],
      ),
    );
  }

  Widget _buildDeviceName(SettingsModel settings, BuildContext context) {
    return Card(
      child: ListTile(
        title: const Text('设备名称'),
        subtitle: Text(settings.name == '' ? '未设置设备名称' : settings.name),
        leading: const Icon(Icons.devices_rounded),
        trailing: IconButton(
          onPressed: () async {
            final name = await showDialog<String>(
              context: context,
              builder: (context) {
                String? input;
                return AlertDialog(
                  title: const Text('输入设备名称'),
                  content: TextField(
                    onChanged: ((value) => input = value),
                    decoration: const InputDecoration(hintText: '请输入设备名称'),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, null),
                      child: const Text('取消'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, input),
                      child: const Text('确定'),
                    ),
                  ],
                );
              },
            );
            if (name != null && name.isNotEmpty) {
              final uuid = Uuid().v4();
              settings.setState(name: name, uuid: uuid);
              settings.updateSettings(name: name, uuid: uuid);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('name 已更新为: $name\nuuid 已更新为: $uuid'),
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          },
          icon: Icon(Icons.edit),
        ),
      ),
    );
  }

  Widget _buildAutoDarkModeSwitch(
    SettingsModel settings,
    BuildContext context,
  ) {
    return Card(
      child: ListTile(
        title: const Text('自动深色模式'),
        subtitle: const Text('根据系统设置自动切换深色模式', maxLines: 1),
        leading: settings.autoDarkMode
            ? const Icon(Icons.settings_brightness)
            : settings.darkMode
            ? const Icon(Icons.dark_mode)
            : const Icon(Icons.light_mode),
        trailing: Switch(
          value: settings.autoDarkMode,
          onChanged: (value) {
            settings.setState(autoDarkMode: value);
            settings.updateSettings(autoDarkMode: value);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('自动深色模式已${value ? '启用' : '禁用'}'),
                duration: const Duration(seconds: 2),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildApiKeySetting(SettingsModel settings, BuildContext context) {
    return Card(
      child: ListTile(
        title: const Text('API Key'),
        subtitle: Text(
          settings.apiKey.isNotEmpty
              ? '*' * settings.apiKey.length
              : '未设置 API Key',
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
        leading: const Icon(Icons.vpn_key),
        trailing: IconButton(
          icon: const Icon(Icons.edit),
          onPressed: () async {
            final apiKey = await showDialog<String>(
              context: context,
              builder: (context) {
                String? input;
                return AlertDialog(
                  title: const Text('输入 API Key'),
                  content: TextField(
                    onChanged: (value) => input = value,
                    decoration: const InputDecoration(hintText: '请输入 API Key'),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, null),
                      child: const Text('取消'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, input),
                      child: const Text('确定'),
                    ),
                  ],
                );
              },
            );

            if (apiKey != null && apiKey.isNotEmpty) {
              settings.setState(apiKey: apiKey);
              settings.updateSettings(apiKey: apiKey);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('API Key 已更新为: $apiKey'),
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          },
        ),
      ),
    );
  }
}

Widget _buildDarkModeSwitch(SettingsModel settings, BuildContext context) {
  return Card(
    child: Opacity(
      opacity: settings.autoDarkMode ? 0.5 : 1.0,
      child: SwitchListTile(
        title: const Text('深色模式'),
        subtitle: settings.autoDarkMode
            ? const Text('当前由系统控制')
            : const Text('切换应用的主题模式'),
        value: settings.darkMode,
        onChanged: settings.autoDarkMode
            ? null
            : (value) {
                settings.setState(darkMode: value);
                settings.updateSettings(darkMode: value);
                // 主题切换逻辑应在应用的顶层处理，这里只更新设置
                // 可以通过 Provider、Bloc 或其他状态管理在 MaterialApp 处响应设置变化
                // 或提示用户重启应用以应用主题变化
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('主题设置已更改'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
        secondary: Icon(settings.darkMode ? Icons.dark_mode : Icons.light_mode),
      ),
    ),
  );
}

Widget _buildDocumentPathSetting(SettingsModel settings, BuildContext context) {
  return Card(
    child: ListTile(
      title: const Text('文档存储路径'),
      subtitle: Text(
        settings.docPath.isNotEmpty ? settings.docPath : '未设置文档存储路径',
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      ),
      leading: const Icon(Icons.folder),
      trailing: IconButton(
        icon: const Icon(Icons.edit),
        onPressed: () async {
          String? selectedDirectory;
          if (Platform.isAndroid) {
            final directory = await getApplicationDocumentsDirectory();
            selectedDirectory = directory.path;
          } else {
            selectedDirectory = await FilePicker.platform.getDirectoryPath();
          }

          if (selectedDirectory != null) {
            settings.setState(docPath: selectedDirectory);
            settings.updateSettings(docPath: selectedDirectory);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('文档路径已更新为: $selectedDirectory'),
                duration: const Duration(seconds: 2),
              ),
            );
          }
        },
      ),
    ),
  );
}

Widget _buildSelectAIMode(SettingsModel settings) {
  final Map<String, String> aiModels = {
    "DeepSeek-V3": 'deepseek-chat',
    "DeepSeek-R1": 'deepseek-reasoner',
  };
  return Card(
    child: ListTile(
      title: const Text("选择模型"),
      subtitle: const Text('选择deepseek版本', maxLines: 1),
      leading: const Icon(Icons.android),
      trailing: DropdownButton<String>(
        value: settings.model,
        items: aiModels.entries.map((entry) {
          return DropdownMenuItem<String>(
            value: entry.value,
            child: Text(entry.key),
          );
        }).toList(),
        onChanged: (value) {
          settings.updateSettings(model: value);
        },
      ),
    ),
  );
}
