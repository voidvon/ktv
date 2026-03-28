# Repository Guidelines

## 项目结构与模块组织
本仓库是精简版 Flutter KTV 播放器。核心代码在 `lib/`：`main.dart` 为 UI 入口，`lib/player/` 放跨平台播放器控制器与声道切换逻辑，`lib/services/` 负责文件选择，`lib/models/` 与 `lib/platform/` 放数据模型和平台判断。原生实现位于 `android/` 与 `macos/`，Android 的 libVLC、JNI 与平台通道改动集中在 `android/app/src/main/`。排错记录在 `docs/`，构建产物 `build/`、`.dart_tool/`、`android/.gradle/` 不应提交。

## 构建、测试与开发命令
- `flutter pub get`：安装 Dart / Flutter 依赖。
- `flutter analyze`：执行静态检查，提交前必须通过。
- `flutter test`：运行 Dart/Flutter 测试；当前仓库测试较少，新增逻辑时应补齐。
- `flutter run -d macos`：本地验证 macOS 播放链路。
- `flutter run -d android`：连接设备后验证 Android 平台视图、文件选择和播放。
- `flutter build apk --release`：生成 Android Release 包，用于检查混淆和 libVLC 保留规则。

## 代码风格与命名
遵循 `analysis_options.yaml` 中的 `flutter_lints`，统一 2 空格缩进。Dart 文件名使用 `snake_case.dart`，类名使用 `UpperCamelCase`，成员与方法使用 `lowerCamelCase`。提交前运行 `dart format lib test`；平台通道、JNI 和播放器宿主类应保持命名语义明确，例如 `NativeKtvPlayerHost`、`platform_channel_player_controller.dart`。

## 测试要求
优先为 `lib/player/`、`lib/services/` 的变更加测试。测试文件放在 `test/`，命名建议采用 `*_test.dart`。涉及 Android 播放链路时，除 `flutter test` 外，至少手动验证一次“选文件、播放、原唱/伴唱切换、Release 安装后可播放”；相关背景先看 `docs/android_playback_notes.md`。

## 提交与合并请求
Git 历史采用 Conventional Commits，例如 `fix: stabilize android playback pipeline`、`feat: extract player-only app with channel switching`、`chore(init): ...`。建议继续使用 `type(scope): summary` 或 `type: summary`。PR 应包含：变更目的、影响平台（Android/macOS）、验证命令、手动验证结果；若改动播放器界面或播放行为，附截图、日志关键字或复现步骤。

## 平台注意事项
不要随意删除 Android 对 `content://` 的缓存复制、URI 持久权限处理、`proguard-rules.pro` 或 JNI 声道路由代码。这些都是当前播放器稳定性的关键约束。
