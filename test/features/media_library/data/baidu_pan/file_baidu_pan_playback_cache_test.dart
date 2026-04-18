import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:maimai_ktv/features/media_library/data/baidu_pan/baidu_pan_auth_repository.dart';
import 'package:maimai_ktv/features/media_library/data/baidu_pan/baidu_pan_models.dart';
import 'package:maimai_ktv/features/media_library/data/baidu_pan/baidu_pan_remote_data_source.dart';
import 'package:maimai_ktv/features/media_library/data/baidu_pan/file_baidu_pan_playback_cache.dart';
import 'package:maimai_ktv/features/media_library/data/cloud/cloud_playback_cache.dart';

import '../../../../test_support/ktv_test_doubles.dart';

void main() {
  test(
    'resolve downloads a remote file and appends the access token',
    () async {
      final Directory tempDir = await Directory.systemTemp.createTemp(
        'baidu-pan-cache-test-',
      );
      addTearDown(() => tempDir.delete(recursive: true));

      Uri? capturedUri;
      final FileBaiduPanPlaybackCache cache = FileBaiduPanPlaybackCache(
        authRepository: _FakeBaiduPanAuthRepository(),
        remoteDataSource: _FakePlayableRemoteDataSource(),
        cacheDirectoryProvider: () async => tempDir,
        fileDownloader:
            ({
              required Uri uri,
              required File targetFile,
              void Function(double progress)? onProgress,
              CloudDownloadCancellationToken? cancellationToken,
            }) async {
              capturedUri = uri;
              await targetFile.writeAsString('downloaded');
              onProgress?.call(1);
            },
      );

      final result = await cache.resolve(
        song: buildRemoteSong(
          title: '发如雪',
          artist: '周杰伦',
          sourceId: 'baidu_pan',
          sourceSongId: 'song-1',
        ),
        sourceSongId: 'song-1',
      );

      expect(result.cacheHit, isFalse);
      expect(await File(result.localPath).exists(), isTrue);
      expect(capturedUri?.queryParameters['access_token'], 'token-123');
    },
  );
}

class _FakeBaiduPanAuthRepository extends BaiduPanAuthRepository {
  @override
  Future<Uri> buildAuthorizeUri() async => Uri.parse('https://example.com');

  @override
  Future<String> getValidAccessToken() async => 'token-123';

  @override
  Future<bool> hasValidSession() async => true;

  @override
  Future<void> loginWithAuthorizationCode(String code) async {}

  @override
  Future<BaiduPanAuthToken?> loginWithDeviceCode(String deviceCode) async {
    return null;
  }

  @override
  Future<void> logout() async {}

  @override
  Future<BaiduPanAuthToken?> readToken() async {
    return const BaiduPanAuthToken(
      accessToken: 'token-123',
      refreshToken: 'refresh-123',
      expiresAtMillis: 9999999999999,
    );
  }

  @override
  Future<BaiduPanDeviceCodeSession> createDeviceCodeSession() async {
    return BaiduPanDeviceCodeSession(
      deviceCode: 'device-code',
      userCode: 'user-code',
      verificationUrl: 'https://example.com',
      qrcodeUrl: 'https://example.com/qr',
      expiresAtMillis: DateTime.now()
          .add(const Duration(minutes: 5))
          .millisecondsSinceEpoch,
      intervalSeconds: 5,
    );
  }
}

class _FakePlayableRemoteDataSource extends BaiduPanRemoteDataSource {
  @override
  Future<BaiduPanRemoteFile> getPlayableFileMeta(String fileId) async {
    return const BaiduPanRemoteFile(
      fsid: 'song-1',
      path: '/KTV/song.mp4',
      serverFilename: 'song.mp4',
      isDirectory: false,
      size: 1,
      modifiedAtMillis: 1,
      dlink: 'https://example.com/download',
    );
  }

  @override
  Future<List<BaiduPanRemoteFile>> scanRoot(String rootPath) async {
    return const <BaiduPanRemoteFile>[];
  }

  @override
  Future<List<BaiduPanRemoteFile>> searchFiles({
    required String keyword,
    String? rootPath,
  }) async {
    return const <BaiduPanRemoteFile>[];
  }
}
