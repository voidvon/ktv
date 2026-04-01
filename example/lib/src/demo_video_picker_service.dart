import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:ktv2/ktv2.dart';
import 'package:ktv2_example/core/media/demo_supported_video_formats.dart';

class DemoVideoPickerService {
  static const MethodChannel _channel = MethodChannel(
    'ktv2_example/video_picker',
  );

  Future<MediaSource?> pickVideo() async {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.macOS) {
      return _pickVideoOnDesktop();
    }

    final result = await _channel.invokeMapMethod<String, Object?>('pickVideo');
    if (result == null) {
      return null;
    }

    final path = result['uri'] as String?;
    if (path == null || path.isEmpty) {
      return null;
    }

    final displayName =
        (result['displayName'] as String?)?.trim().isNotEmpty == true
        ? (result['displayName'] as String).trim()
        : path.split('/').last;

    return MediaSource(path: path, displayName: displayName);
  }

  Future<MediaSource?> _pickVideoOnDesktop() async {
    final XTypeGroup typeGroup = XTypeGroup(
      label: 'video',
      extensions: demoSupportedVideoExtensions,
    );

    final file = await openFile(acceptedTypeGroups: <XTypeGroup>[typeGroup]);
    if (file == null) {
      return null;
    }

    return MediaSource(path: file.path, displayName: file.name);
  }
}
