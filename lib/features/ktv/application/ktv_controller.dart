import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:ktv2/ktv2.dart';

import '../../../core/models/artist.dart';
import '../../../core/models/song.dart';
import '../../media_library/data/media_library_repository.dart';
import 'library_session.dart';
import 'navigation_history.dart';
import 'playback_queue_manager.dart';
import 'ktv_state.dart';

export 'ktv_state.dart' show KtvRoute, SongBookMode, KtvState;

class KtvController extends ChangeNotifier {
  KtvController({
    MediaLibraryRepository? mediaLibraryRepository,
    PlayerController? playerController,
  }) : _mediaLibraryRepository =
           mediaLibraryRepository ?? MediaLibraryRepository(),
       playerController = playerController ?? createPlayerController();

  static const String allLanguagesLabel = '全部';
  static const Duration _searchRefreshDebounce = Duration(milliseconds: 180);

  final MediaLibraryRepository _mediaLibraryRepository;
  final PlayerController playerController;
  late final PlaybackQueueManager _playbackQueueManager = PlaybackQueueManager(
    playerController: playerController,
  );
  late final LibrarySession _librarySession = LibrarySession(
    repository: _mediaLibraryRepository,
    readState: () => _state,
    writeState: _setState,
    allLanguagesLabel: allLanguagesLabel,
  );
  final NavigationHistory _navigationHistory = NavigationHistory();

  KtvState _state = const KtvState();
  bool _didInitialize = false;
  Timer? _pendingSearchRefresh;

  MediaLibraryRepository get mediaLibraryRepository => _mediaLibraryRepository;
  KtvState get state => _state;

  KtvRoute get route => _state.route;
  SongBookMode get songBookMode => _state.songBookMode;
  String get selectedLanguage => _state.selectedLanguage;
  String? get selectedArtist => _state.selectedArtist;
  String get searchQuery => _state.searchQuery;
  String? get libraryScanErrorMessage => _state.libraryScanErrorMessage;
  String? get scanDirectoryPath => _state.scanDirectoryPath;
  bool get isScanningLibrary => _state.isScanningLibrary;
  bool get isLoadingLibraryPage => _state.isLoadingLibraryPage;
  bool get hasConfiguredDirectory => _state.hasConfiguredDirectory;
  bool get canNavigateBack => _navigationHistory.canNavigateBack;
  List<Song> get queuedSongs => List<Song>.unmodifiable(_state.queuedSongs);
  List<Song> get librarySongs =>
      List<Song>.unmodifiable(_state.libraryPageSongs);
  List<Artist> get libraryArtists =>
      List<Artist>.unmodifiable(_state.libraryPageArtists);
  List<Song> get filteredSongs => librarySongs;
  int get libraryTotalCount => _state.libraryTotalCount;
  int get libraryPageIndex => _state.libraryPageIndex;
  int get libraryPageSize => _state.libraryPageSize;
  int get libraryTotalPages => _state.libraryTotalPages;
  List<Song> get filteredQueuedSongs => _state.filteredQueuedSongs();

  String get currentTitle => _state.currentTitle;

  String get currentSubtitle => _state.currentSubtitle;

  String get breadcrumbLabel => _navigationHistory.breadcrumbLabel;

  Future<void> initialize() async {
    if (_didInitialize) {
      return;
    }
    _didInitialize = true;
    await _librarySession.restoreSavedDirectory();
  }

  void setSearchQuery(String query) {
    if (_state.searchQuery == query) {
      return;
    }
    _setState(_state.copyWith(searchQuery: query));
    _scheduleLibraryRefresh(resetPage: true);
  }

  void enterSongBook({SongBookMode mode = SongBookMode.songs}) {
    if (!_navigationHistory.enterSongBook(mode: mode)) {
      return;
    }
    _applyNavigationState(_navigationHistory.current);
    unawaited(_librarySession.reloadLibraryPage(pageIndex: 0));
  }

  void enterQueueList() {
    if (!_navigationHistory.enterQueueList(
      songBookMode: _state.songBookMode,
      selectedArtist: _state.selectedArtist,
    )) {
      return;
    }
    _applyNavigationState(_navigationHistory.current);
  }

  void returnHome() {
    if (!_navigationHistory.returnHome()) {
      return;
    }
    _applyNavigationState(_navigationHistory.current);
  }

  Future<void> selectArtist(String artist) async {
    if (!_navigationHistory.selectArtist(artist)) {
      return;
    }
    _applyNavigationState(_navigationHistory.current);
    await _librarySession.reloadLibraryPage(pageIndex: 0);
  }

  Future<bool> returnFromSelectedArtist() async {
    if (!canNavigateBack) {
      return false;
    }
    return navigateBack();
  }

  Future<bool> navigateBack() async {
    final NavigationDestination? target = _navigationHistory.navigateBack();
    if (target == null) {
      return false;
    }
    _applyNavigationState(target);
    if (target.route == KtvRoute.home) {
      return true;
    }
    await _librarySession.reloadLibraryPage(pageIndex: 0);
    return true;
  }

  void selectLanguage(String language) {
    if (_state.selectedLanguage == language) {
      return;
    }
    _setState(_state.copyWith(selectedLanguage: language));
    unawaited(_librarySession.reloadLibraryPage(pageIndex: 0));
  }

  Future<void> handleSelectedDirectory(String directory) async {
    await _librarySession.handleSelectedDirectory(directory);
  }

  Future<bool> scanLibrary(String directory) async {
    _pendingSearchRefresh?.cancel();
    return _librarySession.scanLibrary(directory);
  }

  Future<void> requestLibraryPage({
    required int pageIndex,
    required int pageSize,
  }) {
    return _librarySession.requestLibraryPage(
      pageIndex: pageIndex,
      pageSize: pageSize,
    );
  }

  Future<void> requestSong(Song song) async {
    final List<Song> nextQueue = await _playbackQueueManager.requestSong(
      _state.queuedSongs,
      song,
    );
    _setState(_state.copyWith(queuedSongs: nextQueue));
  }

  void prioritizeQueuedSong(Song song) {
    _setState(
      _state.copyWith(
        queuedSongs: _playbackQueueManager.prioritizeQueuedSong(
          _state.queuedSongs,
          song,
        ),
      ),
    );
  }

  void removeQueuedSong(Song song) {
    _setState(
      _state.copyWith(
        queuedSongs: _playbackQueueManager.removeQueuedSong(
          _state.queuedSongs,
          song,
        ),
      ),
    );
  }

  void togglePlayback() {
    _playbackQueueManager.togglePlayback();
  }

  void toggleAudioMode() {
    _playbackQueueManager.toggleAudioMode();
  }

  void restartPlayback() {
    _playbackQueueManager.restartPlayback();
  }

  Future<void> skipCurrentSong() async {
    final List<Song> nextQueue = await _playbackQueueManager.skipCurrentSong(
      _state.queuedSongs,
    );
    _setState(_state.copyWith(queuedSongs: nextQueue));
  }

  Future<void> stopPlayback() {
    return _playbackQueueManager.stopPlayback();
  }

  void _scheduleLibraryRefresh({required bool resetPage}) {
    _pendingSearchRefresh?.cancel();
    _pendingSearchRefresh = Timer(_searchRefreshDebounce, () {
      unawaited(
        _librarySession.reloadLibraryPage(pageIndex: resetPage ? 0 : null),
      );
    });
  }

  void _setState(KtvState nextState) {
    if (identical(_state, nextState)) {
      return;
    }
    _state = nextState;
    notifyListeners();
  }

  void _applyNavigationState(NavigationDestination target) {
    _setState(
      _state.copyWith(
        route: target.route,
        songBookMode: target.songBookMode,
        selectedArtist: target.selectedArtist,
        searchQuery: '',
        libraryPageIndex: 0,
      ),
    );
  }

  @override
  void dispose() {
    _pendingSearchRefresh?.cancel();
    playerController.dispose();
    super.dispose();
  }
}
