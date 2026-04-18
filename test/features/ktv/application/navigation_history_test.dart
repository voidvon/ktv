import 'package:flutter_test/flutter_test.dart';
import 'package:maimai_ktv/features/ktv/application/ktv_state.dart';
import 'package:maimai_ktv/features/ktv/application/navigation_history.dart';

void main() {
  test('navigation history builds breadcrumb labels across pages', () {
    final NavigationHistory history = NavigationHistory();

    expect(history.current.route, KtvRoute.home);
    expect(history.breadcrumbLabel, '主页');

    expect(history.enterSongBook(mode: SongBookMode.artists), isTrue);
    expect(history.selectArtist('周杰伦'), isTrue);
    expect(
      history.enterQueueList(
        songBookMode: history.current.songBookMode,
        libraryScope: history.current.libraryScope,
        selectedArtist: history.current.selectedArtist,
      ),
      isTrue,
    );

    expect(history.breadcrumbLabel, '主页 / 歌星 / 周杰伦 / 已点');
    expect(history.navigateBack(), isNotNull);
    expect(history.current.selectedArtist, '周杰伦');
    expect(history.current.route, KtvRoute.songBook);
  });

  test('returnHome resets the stack to a single home destination', () {
    final NavigationHistory history = NavigationHistory();

    history.enterSongBook(mode: SongBookMode.songs);

    expect(history.returnHome(), isTrue);
    expect(history.current, const NavigationDestination.home());
    expect(history.canNavigateBack, isFalse);
    expect(history.returnHome(), isFalse);
  });
}
