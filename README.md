# ktv

本仓库就是当前 KTV 主应用，播放器能力拆在内部 package `packages/ktv2/`。

## 目录结构

- `lib/`: 主应用页面、媒体库、设置与交互逻辑
- `android/` / `macos/`: 主应用宿主平台工程
- `packages/ktv2/`: 播放器 Flutter plugin/package，提供跨平台播放与声道切换能力
- `docs/`: Android 播放链路、导歌规则和排错资料

## 常用命令

```bash
flutter pub get
flutter analyze
flutter test
flutter run -d macos
flutter run -d android

cd packages/ktv2 && flutter pub get
cd packages/ktv2 && flutter analyze
cd packages/ktv2 && flutter test
```

## 说明

主应用通过本地路径依赖播放器包：

```yaml
dependencies:
  ktv2:
    path: packages/ktv2
```

播放器包文档见 `packages/ktv2/README.md`。
