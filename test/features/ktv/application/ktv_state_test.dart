import 'package:maimai_ktv/core/models/song.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maimai_ktv/features/ktv/application/ktv_state.dart';

import '../../../test_support/ktv_test_doubles.dart';

void main() {
  test('copyWith updates nested library and playback fields together', () {
    final KtvState state = const KtvState().copyWith(
      searchQuery: 'jay',
      scanDirectoryPath: '/music',
      libraryTotalCount: 2,
      libraryPageSongs: <Song>[buildLocalSong(title: '夜曲', artist: '周杰伦')],
      queuedSongs: <Song>[buildLocalSong(title: '青花瓷', artist: '周杰伦')],
    );

    expect(state.searchQuery, 'jay');
    expect(state.scanDirectoryPath, '/music');
    expect(state.libraryTotalCount, 2);
    expect(state.libraryPageSongs.single.title, '夜曲');
    expect(state.queuedSongs.single.title, '青花瓷');
  });

  test('current subtitle reflects queue and library scope', () {
    final KtvState state = const KtvState().copyWith(
      libraryScope: LibraryScope.aggregated,
      libraryTotalCount: 3,
      queuedSongs: <Song>[
        buildRemoteSong(
          title: '后来',
          artist: '刘若英',
          sourceId: 'baidu_pan',
          sourceSongId: 'song-1',
        ),
      ],
    );

    expect(state.currentTitle, '后来');
    expect(state.currentSubtitle, '刘若英 · 已从聚合曲库加载 3 首');
  });
}
