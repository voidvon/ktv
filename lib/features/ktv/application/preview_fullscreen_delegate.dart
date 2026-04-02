import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

abstract class PreviewFullscreenDelegate {
  const PreviewFullscreenDelegate();

  Future<void> setVideoFullscreen({required bool enabled});
}

class MethodChannelPreviewFullscreenDelegate extends PreviewFullscreenDelegate {
  const MethodChannelPreviewFullscreenDelegate({
    MethodChannel orientationChannel = const MethodChannel(
      'ktv2_example/orientation',
    ),
  }) : _orientationChannel = orientationChannel;

  final MethodChannel _orientationChannel;

  @override
  Future<void> setVideoFullscreen({required bool enabled}) async {
    if (defaultTargetPlatform != TargetPlatform.android) {
      return;
    }
    try {
      await _orientationChannel.invokeMethod<void>(
        enabled ? 'enterVideoFullscreen' : 'exitVideoFullscreen',
      );
    } on MissingPluginException {
      // Android-only channel; fall back to SystemChrome when unavailable.
    } on PlatformException {
      // Keep fullscreen flow alive even if the platform request fails.
    }
  }
}
