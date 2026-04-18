import 'package:flutter_test/flutter_test.dart';
import 'package:maimai_ktv/features/ktv/application/download_manager_models.dart';

void main() {
  test('retryable network errors are auto retried', () {
    expect(
      isRetryableDownloadErrorMessage(
        'SocketException: Connection reset by peer',
      ),
      isTrue,
    );
    expect(
      isRetryableDownloadErrorMessage('HttpException: 鐧惧害缃戠洏涓嬭浇澶辫触: 503'),
      isTrue,
    );
    expect(
      const DownloadingSongItem(
        songId: 'song-1',
        sourceId: 'baidu_pan',
        sourceSongId: 'fsid-1',
        title: '澶滄洸',
        artist: '鍛ㄦ澃浼?,
        startedAtMillis: 1,
        updatedAtMillis: 2,
        status: DownloadTaskStatus.failed,
        errorMessage: 'TimeoutException: request timed out',
      ).isAutoRetryableFailure,
      isTrue,
    );
  });

  test('non-network errors are not auto retried', () {
    expect(
      isRetryableDownloadErrorMessage('StateError: 鐧惧害缃戠洏姝屾洸 song-1 缂哄皯鍙笅杞?dlink'),
      isFalse,
    );
    expect(
      isRetryableDownloadErrorMessage('HttpException: 鐧惧害缃戠洏涓嬭浇澶辫触: 401'),
      isFalse,
    );
    expect(
      isRetryableDownloadErrorMessage('HttpException: 鐧惧害缃戠洏涓嬭浇澶辫触: 404'),
      isFalse,
    );
    expect(
      const DownloadingSongItem(
        songId: 'song-2',
        sourceId: 'baidu_pan',
        sourceSongId: 'fsid-2',
        title: '鏅村ぉ',
        artist: '鍛ㄦ澃浼?,
        startedAtMillis: 1,
        updatedAtMillis: 2,
        status: DownloadTaskStatus.failed,
        errorMessage: 'StateError: baidu_pan 涓嬭浇鏈嶅姟鏈惎鐢?,
      ).isAutoRetryableFailure,
      isFalse,
    );
  });

  test('authorization errors are classified for foreground notice', () {
    expect(
      isAuthorizationDownloadErrorMessage(
        'BaiduPanUnauthorizedException: 鐧惧害缃戠洏鏈巿鏉?,
      ),
      isTrue,
    );
    expect(
      isAuthorizationDownloadErrorMessage(
        'BaiduPanTokenExpiredException: 鐧惧害缃戠洏鎺堟潈宸茶繃鏈?,
      ),
      isTrue,
    );
    expect(
      isAuthorizationDownloadErrorMessage('HttpException: 鐧惧害缃戠洏涓嬭浇澶辫触: 401'),
      isTrue,
    );
    expect(
      isAuthorizationDownloadErrorMessage('HttpException: 鐧惧害缃戠洏涓嬭浇澶辫触: 403'),
      isFalse,
    );
    expect(
      const DownloadingSongItem(
        songId: 'song-3',
        sourceId: 'baidu_pan',
        sourceSongId: 'fsid-3',
        title: '闈掕姳鐡?,
        artist: '鍛ㄦ澃浼?,
        startedAtMillis: 1,
        updatedAtMillis: 2,
        status: DownloadTaskStatus.failed,
        errorMessage: 'BaiduPanUnauthorizedException: 鐧惧害缃戠洏鏈巿鏉?,
      ).isAuthorizationFailure,
      isTrue,
    );
    expect(
      isAuthorizationDownloadErrorMessage(
        'StateError: 鐧惧害缃戠洏姝屾洸 song-1 缂哄皯鍙笅杞?dlink',
      ),
      isFalse,
    );
  });

  test('download error summary hides raw url and exception details', () {
    expect(
      buildDownloadErrorSummary(
        'HttpException: 鐧惧害缃戠洏鎺ュ彛杩斿洖寮傚父: 503 https://pan.baidu.com/rest/2.0/xpan/file?access_token=abc',
        fallback: '涓嬭浇澶辫触',
      ),
      '涓嬭浇澶辫触锛岃绋嶅悗閲嶈瘯',
    );
    expect(
      buildDownloadErrorSummary(
        'BaiduPanUnauthorizedException: 鐧惧害缃戠洏鏈巿鏉?,
        fallback: '涓嬭浇澶辫触',
      ),
      '鐧诲綍宸插け鏁堬紝璇烽噸鏂扮櫥褰?,
    );
    expect(
      buildDownloadErrorSummary(
        'StateError: 鐧惧害缃戠洏姝屾洸 song-1 缂哄皯鍙笅杞?dlink',
        fallback: '涓嬭浇澶辫触',
      ),
      '涓嬭浇澶辫触锛屾枃浠朵笉鍙敤',
    );
    expect(
      buildDownloadErrorSummary(
        'BaiduPanDownloadForbiddenException: 鐧惧害缃戠洏涓嬭浇琚嫆缁?,
        fallback: '涓嬭浇澶辫触',
      ),
      '涓嬭浇澶辫触锛屾枃浠朵笉鍙敤',
    );
    expect(
      buildDownloadErrorSummary(
        'StateError: baidu_pan 涓嬭浇鏈嶅姟鏈惎鐢?,
        fallback: '涓嬭浇澶辫触',
      ),
      '涓嬭浇澶辫触锛屼笅杞芥湇鍔′笉鍙敤',
    );
  });
}

