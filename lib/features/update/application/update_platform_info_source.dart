import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

abstract interface class UpdatePlatformInfoSource {
  Future<List<String>> readAndroidSupportedAbis();
}

class MethodChannelUpdatePlatformInfoSource
    implements UpdatePlatformInfoSource {
  MethodChannelUpdatePlatformInfoSource({
    MethodChannel channel = const MethodChannel(
      'com.app0122.maimai.app/update',
    ),
  }) : _channel = channel;

  final MethodChannel _channel;

  @override
  Future<List<String>> readAndroidSupportedAbis() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return const <String>[];
    }
    final List<dynamic>? result = await _channel.invokeMethod<List<dynamic>>(
      'getSupportedAbis',
    );
    return (result ?? const <dynamic>[])
        .map((dynamic item) => item.toString().trim())
        .where((String item) => item.isNotEmpty)
        .toList(growable: false);
  }
}
