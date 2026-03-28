# ktv2

从原项目中抽离出来的最小 KTV 播放器，只保留：

- 本地视频播放
- 完整原唱 / 伴唱切换
- Android libVLC 播放链路
- macOS 原生播放器桥接

## 说明文档

- Android 播放链路与排错记录：
  [docs/android_playback_notes.md](docs/android_playback_notes.md)

## 常用命令

```bash
flutter analyze
flutter build apk --release
```
