import 'package:flutter_test/flutter_test.dart';
import 'package:maimai_ktv/core/models/song_identity.dart';
import 'package:maimai_ktv/core/models/song.dart';
import 'package:maimai_ktv/features/ktv/application/ktv_controller.dart';

void main() {
  test('copyWith updates nested library and playback state compatibly', () {
    final KtvState state = const KtvState().copyWith(
      searchQuery: 'jay',
      scanDirectoryPath: '/music',
      libraryTotalCount: 8,
      libraryPageSongs: <Song>[
        Song(
          songId: buildAggregateSongId(title: '澶滄洸', artist: '鍛ㄦ澃浼?),
          sourceId: 'local',
          sourceSongId: buildLocalSourceSongId(
            fingerprint: buildLocalMetadataFingerprint(
              locator: '/music/yequ.mp4',
            ),
          ),
          title: '澶滄洸',
          artist: '鍛ㄦ澃浼?,
          languages: <String>['鍥借'],
          searchIndex: 'yequ zhoujielun',
          mediaPath: '/music/yequ.mp4',
        ),
      ],
      queuedSongs: <Song>[
        Song(
          songId: buildAggregateSongId(title: '闈掕姳鐡?, artist: '鍛ㄦ澃浼?),
          sourceId: 'local',
          sourceSongId: buildLocalSourceSongId(
            fingerprint: buildLocalMetadataFingerprint(
              locator: '/music/qinghuaci.mp4',
            ),
          ),
          title: '闈掕姳鐡?,
          artist: '鍛ㄦ澃浼?,
          languages: <String>['鍥借'],
          searchIndex: 'qinghuaci zhoujielun',
          mediaPath: '/music/qinghuaci.mp4',
        ),
      ],
    );

    expect(state.library.searchQuery, 'jay');
    expect(state.searchQuery, 'jay');
    expect(state.library.scanDirectoryPath, '/music');
    expect(state.library.totalCount, 8);
    expect(state.playback.queuedSongs, hasLength(1));
    expect(state.queuedSongs.single.title, '闈掕姳鐡?);
    expect(state.libraryPageSongs.single.title, '澶滄洸');
  });
}

