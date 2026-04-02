import 'dart:async';
import 'dart:math' as math;

import '../../../core/models/artist.dart';
import '../../../core/models/artist_page.dart';
import '../../../core/models/song.dart';
import '../../../core/models/song_page.dart';
import '../../media_library/data/media_library_repository.dart';
import 'ktv_state.dart';

typedef KtvStateReader = KtvState Function();
typedef KtvStateWriter = void Function(KtvState nextState);

class LibrarySession {
  LibrarySession({
    required MediaLibraryRepository repository,
    required KtvStateReader readState,
    required KtvStateWriter writeState,
    required this.allLanguagesLabel,
  }) : _repository = repository,
       _readState = readState,
       _writeState = writeState;

  final MediaLibraryRepository _repository;
  final KtvStateReader _readState;
  final KtvStateWriter _writeState;
  final String allLanguagesLabel;

  int _libraryQueryGeneration = 0;

  Future<void> restoreSavedDirectory() async {
    final String? savedDirectory = await _repository.loadSelectedDirectory();
    if (savedDirectory == null) {
      return;
    }

    final bool hasAccess = await _repository.ensureDirectoryAccess(
      savedDirectory,
    );
    if (!hasAccess) {
      await _repository.clearDirectoryAccess(path: savedDirectory);
      return;
    }

    _writeState(_readState().copyWith(scanDirectoryPath: savedDirectory));
    await reloadLibraryPage(pageIndex: 0, clearErrorMessage: true);
    if (_readState().libraryTotalCount == 0) {
      await scanLibrary(savedDirectory);
      return;
    }
    unawaited(refreshLibraryIndexInBackground(savedDirectory));
  }

  Future<void> handleSelectedDirectory(String directory) async {
    _writeState(_readState().copyWith(scanDirectoryPath: directory));
    await _repository.saveSelectedDirectory(directory);
    await scanLibrary(directory);
  }

  Future<bool> scanLibrary(String directory) async {
    _writeState(
      _readState().copyWith(
        scanDirectoryPath: directory,
        isScanningLibrary: true,
        libraryScanErrorMessage: null,
        selectedLanguage: allLanguagesLabel,
        searchQuery: '',
        libraryPageIndex: 0,
      ),
    );

    try {
      await _repository.scanLibrary(directory);
      await reloadLibraryPage(pageIndex: 0, clearErrorMessage: true);
      return true;
    } catch (error) {
      _writeState(
        _readState().copyWith(
          libraryPageSongs: const <Song>[],
          libraryPageArtists: const <Artist>[],
          libraryTotalCount: 0,
          libraryPageIndex: 0,
          libraryScanErrorMessage: '扫描目录失败：$error',
        ),
      );
      return false;
    } finally {
      _writeState(_readState().copyWith(isScanningLibrary: false));
    }
  }

  Future<void> requestLibraryPage({
    required int pageIndex,
    required int pageSize,
  }) {
    final KtvState state = _readState();
    final int normalizedPageSize = math.max(1, pageSize);
    final int previousOffset = state.libraryPageIndex * state.libraryPageSize;
    final int nextPageIndex = normalizedPageSize == state.libraryPageSize
        ? pageIndex
        : previousOffset ~/ normalizedPageSize;
    return reloadLibraryPage(
      pageIndex: nextPageIndex,
      pageSize: normalizedPageSize,
    );
  }

  Future<void> refreshLibraryIndexInBackground(String directory) async {
    if (_readState().scanDirectoryPath != directory) {
      return;
    }
    _writeState(
      _readState().copyWith(
        isScanningLibrary: true,
        libraryScanErrorMessage: null,
      ),
    );
    try {
      await _repository.scanLibrary(directory);
      if (_readState().scanDirectoryPath != directory) {
        return;
      }
      await reloadLibraryPage(
        pageIndex: _readState().libraryPageIndex,
        pageSize: _readState().libraryPageSize,
        clearErrorMessage: true,
      );
    } catch (error) {
      if (_readState().scanDirectoryPath != directory) {
        return;
      }
      _writeState(
        _readState().copyWith(libraryScanErrorMessage: '后台刷新目录失败：$error'),
      );
    } finally {
      if (_readState().scanDirectoryPath == directory) {
        _writeState(_readState().copyWith(isScanningLibrary: false));
      }
    }
  }

  Future<void> reloadLibraryPage({
    int? pageIndex,
    int? pageSize,
    bool clearErrorMessage = false,
  }) async {
    final KtvState state = _readState();
    final String? directory = state.scanDirectoryPath;
    if (directory == null) {
      _writeState(
        state.copyWith(
          libraryPageSongs: const <Song>[],
          libraryPageArtists: const <Artist>[],
          libraryTotalCount: 0,
          libraryPageIndex: 0,
          isLoadingLibraryPage: false,
        ),
      );
      return;
    }

    final int targetPageSize = math.max(1, pageSize ?? state.libraryPageSize);
    final int targetPageIndex = math.max(
      0,
      pageIndex ?? state.libraryPageIndex,
    );
    final int generation = ++_libraryQueryGeneration;

    _writeState(
      state.copyWith(
        isLoadingLibraryPage: true,
        libraryPageIndex: targetPageIndex,
        libraryPageSize: targetPageSize,
        libraryScanErrorMessage: clearErrorMessage
            ? null
            : state.libraryScanErrorMessage,
      ),
    );

    try {
      final KtvState currentState = _readState();
      final String? language =
          currentState.selectedLanguage == allLanguagesLabel
          ? null
          : currentState.selectedLanguage;
      if (currentState.songBookMode == SongBookMode.artists &&
          currentState.selectedArtist == null) {
        final ArtistPage page = await _repository.queryArtists(
          directory: directory,
          language: language,
          searchQuery: currentState.searchQuery,
          pageIndex: targetPageIndex,
          pageSize: targetPageSize,
        );
        if (generation != _libraryQueryGeneration) {
          return;
        }

        final int totalPages = page.totalPages;
        if (page.totalCount > 0 && targetPageIndex >= totalPages) {
          await reloadLibraryPage(
            pageIndex: totalPages - 1,
            pageSize: targetPageSize,
            clearErrorMessage: clearErrorMessage,
          );
          return;
        }

        _writeState(
          _readState().copyWith(
            libraryPageSongs: const <Song>[],
            libraryPageArtists: page.artists,
            libraryTotalCount: page.totalCount,
            libraryPageIndex: page.pageIndex,
            libraryPageSize: page.pageSize,
            isLoadingLibraryPage: false,
            libraryScanErrorMessage: clearErrorMessage
                ? null
                : _readState().libraryScanErrorMessage,
          ),
        );
        return;
      }

      final SongPage page = await _repository.querySongs(
        directory: directory,
        language: language,
        artist: currentState.selectedArtist,
        searchQuery: currentState.searchQuery,
        pageIndex: targetPageIndex,
        pageSize: targetPageSize,
      );
      if (generation != _libraryQueryGeneration) {
        return;
      }

      final int totalPages = page.totalPages;
      if (page.totalCount > 0 && targetPageIndex >= totalPages) {
        await reloadLibraryPage(
          pageIndex: totalPages - 1,
          pageSize: targetPageSize,
          clearErrorMessage: clearErrorMessage,
        );
        return;
      }

      _writeState(
        _readState().copyWith(
          libraryPageSongs: page.songs,
          libraryPageArtists: const <Artist>[],
          libraryTotalCount: page.totalCount,
          libraryPageIndex: page.pageIndex,
          libraryPageSize: page.pageSize,
          isLoadingLibraryPage: false,
          libraryScanErrorMessage: clearErrorMessage
              ? null
              : _readState().libraryScanErrorMessage,
        ),
      );
    } catch (error) {
      if (generation != _libraryQueryGeneration) {
        return;
      }
      _writeState(
        _readState().copyWith(
          libraryPageSongs: const <Song>[],
          libraryPageArtists: const <Artist>[],
          libraryTotalCount: 0,
          isLoadingLibraryPage: false,
          libraryScanErrorMessage: '加载歌曲列表失败：$error',
        ),
      );
    }
  }
}
