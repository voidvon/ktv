import '../../../core/models/demo_song.dart';

enum DemoRoute { home, songBook, queueList }

class KtvDemoState {
  const KtvDemoState({
    this.route = DemoRoute.home,
    this.selectedLanguage = '全部',
    this.libraryScanErrorMessage,
    this.scanDirectoryPath,
    this.searchQuery = '',
    this.isScanningLibrary = false,
    this.queuedSongs = const <DemoSong>[],
    this.librarySongs = const <DemoSong>[],
  });

  static const Object _unset = Object();

  final DemoRoute route;
  final String selectedLanguage;
  final String? libraryScanErrorMessage;
  final String? scanDirectoryPath;
  final String searchQuery;
  final bool isScanningLibrary;
  final List<DemoSong> queuedSongs;
  final List<DemoSong> librarySongs;

  bool get hasConfiguredDirectory => scanDirectoryPath != null;

  String get normalizedSearchQuery => searchQuery.trim().toLowerCase();

  List<DemoSong> filteredSongs(String allLanguagesLabel) {
    return librarySongs
        .where((DemoSong song) {
          final bool languageMatches =
              selectedLanguage == allLanguagesLabel ||
              song.language == selectedLanguage;
          if (!languageMatches) {
            return false;
          }
          if (normalizedSearchQuery.isEmpty) {
            return true;
          }
          return song.searchIndex.contains(normalizedSearchQuery);
        })
        .toList(growable: false);
  }

  List<DemoSong> filteredQueuedSongs() {
    if (normalizedSearchQuery.isEmpty) {
      return List<DemoSong>.unmodifiable(queuedSongs);
    }
    return queuedSongs
        .where(
          (DemoSong song) => song.searchIndex.contains(normalizedSearchQuery),
        )
        .toList(growable: false);
  }

  String get currentTitle {
    if (queuedSongs.isNotEmpty) {
      return queuedSongs.first.title;
    }
    return '等待点唱';
  }

  String get currentSubtitle {
    if (queuedSongs.isNotEmpty) {
      return '${queuedSongs.first.artist} · 已从目录中加载 ${librarySongs.length} 首';
    }
    if (scanDirectoryPath != null && librarySongs.isNotEmpty) {
      return '已从扫描目录加载 ${librarySongs.length} 首歌曲。';
    }
    return '请先在设置中选择扫描目录。';
  }

  KtvDemoState copyWith({
    DemoRoute? route,
    String? selectedLanguage,
    Object? libraryScanErrorMessage = _unset,
    Object? scanDirectoryPath = _unset,
    String? searchQuery,
    bool? isScanningLibrary,
    List<DemoSong>? queuedSongs,
    List<DemoSong>? librarySongs,
  }) {
    return KtvDemoState(
      route: route ?? this.route,
      selectedLanguage: selectedLanguage ?? this.selectedLanguage,
      libraryScanErrorMessage: identical(libraryScanErrorMessage, _unset)
          ? this.libraryScanErrorMessage
          : libraryScanErrorMessage as String?,
      scanDirectoryPath: identical(scanDirectoryPath, _unset)
          ? this.scanDirectoryPath
          : scanDirectoryPath as String?,
      searchQuery: searchQuery ?? this.searchQuery,
      isScanningLibrary: isScanningLibrary ?? this.isScanningLibrary,
      queuedSongs: queuedSongs ?? this.queuedSongs,
      librarySongs: librarySongs ?? this.librarySongs,
    );
  }
}
