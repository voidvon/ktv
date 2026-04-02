import 'ktv_state.dart';

class NavigationDestination {
  const NavigationDestination.home()
    : route = KtvRoute.home,
      songBookMode = SongBookMode.songs,
      selectedArtist = null;

  const NavigationDestination.songBook({
    required SongBookMode mode,
    this.selectedArtist,
  }) : route = KtvRoute.songBook,
       songBookMode = mode;

  const NavigationDestination.queueList({
    required this.songBookMode,
    required this.selectedArtist,
  }) : route = KtvRoute.queueList;

  final KtvRoute route;
  final SongBookMode songBookMode;
  final String? selectedArtist;

  String get breadcrumbSegment {
    switch (route) {
      case KtvRoute.home:
        return '主页';
      case KtvRoute.songBook:
        if (selectedArtist != null) {
          return selectedArtist!;
        }
        return switch (songBookMode) {
          SongBookMode.artists => '歌星',
          SongBookMode.favorites => '收藏',
          SongBookMode.frequent => '常唱',
          SongBookMode.songs => '本地',
        };
      case KtvRoute.queueList:
        return '已点';
    }
  }

  @override
  bool operator ==(Object other) {
    return other is NavigationDestination &&
        other.route == route &&
        other.songBookMode == songBookMode &&
        other.selectedArtist == selectedArtist;
  }

  @override
  int get hashCode => Object.hash(route, songBookMode, selectedArtist);
}

class NavigationHistory {
  final List<NavigationDestination> _stack = <NavigationDestination>[
    const NavigationDestination.home(),
  ];

  NavigationDestination get current => _stack.last;

  bool get canNavigateBack => _stack.length > 1;

  String get breadcrumbLabel =>
      '‹ ${_stack.map((entry) => entry.breadcrumbSegment).join(' / ')}';

  bool enterSongBook({SongBookMode mode = SongBookMode.songs}) {
    final NavigationDestination target = NavigationDestination.songBook(
      mode: mode,
    );
    if (current == target) {
      return false;
    }
    _stack.add(target);
    return true;
  }

  bool enterQueueList({
    required SongBookMode songBookMode,
    required String? selectedArtist,
  }) {
    final NavigationDestination target = NavigationDestination.queueList(
      songBookMode: songBookMode,
      selectedArtist: selectedArtist,
    );
    if (current == target) {
      return false;
    }
    _stack.add(target);
    return true;
  }

  bool selectArtist(String artist) {
    final String normalizedArtist = artist.trim();
    if (normalizedArtist.isEmpty) {
      return false;
    }
    final NavigationDestination target = NavigationDestination.songBook(
      mode: SongBookMode.songs,
      selectedArtist: normalizedArtist,
    );
    if (current == target) {
      return false;
    }
    _stack.add(target);
    return true;
  }

  bool returnHome() {
    if (_stack.length == 1 &&
        _stack.first == const NavigationDestination.home()) {
      return false;
    }
    _stack
      ..clear()
      ..add(const NavigationDestination.home());
    return true;
  }

  NavigationDestination? navigateBack() {
    if (!canNavigateBack) {
      return null;
    }
    _stack.removeLast();
    return current;
  }
}
