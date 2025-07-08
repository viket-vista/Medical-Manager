# 医疗病历管理应用

这个Flutter应用是一个功能完善的医疗病历管理系统，帮助医生高效管理患者病历、生成结构化病历内容，并整合了AI辅助功能。

## 主要功能

### 📝 病历管理
- 患者基本信息管理（姓名、年龄、性别）
- 完整病历结构支持（主诉、现病史、既往史、个人史等）
- 图片附件管理（拍照/相册上传）
- 录音功能（记录患者口述）

### 🤖 AI集成
- DeepSeek API集成（支持多个模型）
- 流式响应和普通请求模式
- 根据病历表单自动生成入院记录
- AI辅助诊断建议

### ⚙️ 系统设置
- API密钥管理
- 深色模式/自动主题切换
- 文档存储路径配置
- 模型选择（DeepSeek-V3/R1）

### 📁 数据管理
- 本地JSON存储
- 按患者分类管理
- 数据导入/导出
- 图片和录音文件管理

## 技术架构

```
lib/
├── models/            # 数据模型
├── pages/             # 应用页面
│   ├── MedicalRecord.dart  # 病历列表
│   ├── editpage.dart       # 病历编辑器
│   ├── AI.dart             # AI交互页面
│   ├── Settings.dart       # 设置页面
│   ├── record.dart         # 录音管理
│   └── ShowPhotos.dart     # 图片管理
├── tools/             # 工具类
│   ├── aitool.dart        # AI接口工具
│   └── JsonChange.dart    # JSON处理工具
└── home.dart          # 主入口
```

## 安装与运行

1. 克隆仓库：
   ```bash
   git clone https://github.com/your-repo/medical-manager.git
   cd medical-manager
   ```

2. 安装依赖：
   ```bash
   flutter pub get
   ```

3. 运行应用：
   ```bash
   flutter run
   ```

## 配置指南

1. **API密钥设置**：
   - 进入"设置"页面
   - 点击"API Key"项
   - 输入您的DeepSeek API密钥

2. **模型选择**：
   - 在设置页面选择AI模型
   - 可选模型：DeepSeek-V3 或 DeepSeek-R1

3. **存储路径**：
   - 应用默认使用文档目录
   - 可在设置中自定义存储路径

## 使用示例

### 创建新病历
1. 点击主页面的"+"按钮
2. 填写患者基本信息
3. 添加主诉和现病史
4. 使用"根据表单生成入院记录"按钮自动生成病历内容

### AI辅助功能
1. 进入AI页面
2. 输入医疗相关问题
3. 选择"流式请求"实时获取回答
4. 使用"停止接收"按钮控制响应流

## 依赖项

主要依赖包：
- `provider`: 状态管理
- `dio`: 网络请求
- `file_picker`: 文件选择
- `image_picker`: 图片选择
- `flutter_sound`: 录音功能
- `photo_view`: 图片预览
- `path_provider`: 路径访问

完整依赖请查看 `pubspec.yaml` 文件

## 贡献指南

欢迎提交Issue和Pull Request。在提交PR前请确保：
1. 代码通过静态分析 (`flutter analyze`)
2. 添加相应的单元测试
3. 更新相关文档

## 许可证

本项目采用 [MIT 许可证](LICENSE)