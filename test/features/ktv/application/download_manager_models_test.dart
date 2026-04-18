import 'package:flutter_test/flutter_test.dart';
import 'package:maimai_ktv/features/ktv/application/download_manager_models.dart';

void main() {
  group('isRetryableDownloadErrorMessage', () {
    test('recognizes network failures and retryable http status codes', () {
      expect(
        isRetryableDownloadErrorMessage(
          'SocketException: Connection reset by peer',
        ),
        isTrue,
      );
      expect(isRetryableDownloadErrorMessage('下载失败: 503'), isTrue);
      expect(
        const DownloadingSongItem(
          songId: 'song-1',
          sourceId: 'baidu_pan',
          sourceSongId: 'fsid-1',
          title: '夜曲',
          artist: '周杰伦',
          startedAtMillis: 1,
          updatedAtMillis: 2,
          status: DownloadTaskStatus.failed,
          errorMessage: 'TimeoutException: request timed out',
        ).isAutoRetryableFailure,
        isTrue,
      );
    });

    test(
      'does not mark validation or non-retryable auth errors as retryable',
      () {
        expect(isRetryableDownloadErrorMessage('下载失败: 401'), isFalse);
        expect(
          isRetryableDownloadErrorMessage('StateError: 缺少可下载 dlink'),
          isFalse,
        );
      },
    );
  });

  group('isAuthorizationDownloadErrorMessage', () {
    test('recognizes explicit auth failures and 401 responses', () {
      expect(
        isAuthorizationDownloadErrorMessage(
          'BaiduPanUnauthorizedException: 百度网盘未授权',
        ),
        isTrue,
      );
      expect(isAuthorizationDownloadErrorMessage('下载失败: 401'), isTrue);
      expect(isAuthorizationDownloadErrorMessage('下载失败: 403'), isFalse);
      expect(
        const DownloadingSongItem(
          songId: 'song-2',
          sourceId: 'baidu_pan',
          sourceSongId: 'fsid-2',
          title: '晴天',
          artist: '周杰伦',
          startedAtMillis: 1,
          updatedAtMillis: 2,
          status: DownloadTaskStatus.failed,
          errorMessage: 'BaiduPanTokenExpiredException: 授权已过期',
        ).isAuthorizationFailure,
        isTrue,
      );
    });
  });

  group('buildDownloadErrorSummary', () {
    test('returns user-facing summaries for common download failures', () {
      expect(
        buildDownloadErrorSummary(
          'HttpException: 百度网盘接口返回异常: 503 https://pan.baidu.com/rest/2.0',
          fallback: '下载失败',
        ),
        '下载失败，请稍后重试',
      );
      expect(
        buildDownloadErrorSummary(
          'BaiduPanUnauthorizedException: 百度网盘未授权',
          fallback: '下载失败',
        ),
        '登录已失效，请重新登录',
      );
      expect(
        buildDownloadErrorSummary('StateError: 缺少可下载 dlink', fallback: '下载失败'),
        '下载失败，文件不可用',
      );
      expect(
        buildDownloadErrorSummary('StateError: 下载服务未启用', fallback: '下载失败'),
        '下载失败，下载服务不可用',
      );
      expect(buildDownloadErrorSummary(null, fallback: '下载失败'), '下载失败');
    });
  });
}
