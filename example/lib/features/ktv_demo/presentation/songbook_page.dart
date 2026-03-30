part of 'ktv_demo_shell.dart';

class _SongBookPage extends StatelessWidget {
  const _SongBookPage({
    required this.controller,
    required this.searchController,
    required this.route,
    required this.searchQuery,
    required this.selectedLanguage,
    required this.songs,
    required this.hasConfiguredDirectory,
    required this.isScanningLibrary,
    required this.libraryScanErrorMessage,
    required this.queuedSongs,
    required this.onBackPressed,
    required this.onQueuePressed,
    required this.onEnterSongBook,
    required this.onLanguageSelected,
    required this.onAppendSearchToken,
    required this.onRemoveSearchCharacter,
    required this.onClearSearch,
    required this.onRequestSong,
    required this.onPrioritizeQueuedSong,
    required this.onRemoveQueuedSong,
    required this.onSettingsPressed,
    required this.onToggleAudioMode,
    required this.onTogglePlayback,
    required this.onRestartPlayback,
    required this.onSkipSong,
    this.compact = false,
  });

  final PlayerController controller;
  final TextEditingController searchController;
  final DemoRoute route;
  final String searchQuery;
  final String selectedLanguage;
  final List<DemoSong> songs;
  final bool hasConfiguredDirectory;
  final bool isScanningLibrary;
  final String? libraryScanErrorMessage;
  final List<DemoSong> queuedSongs;
  final VoidCallback onBackPressed;
  final VoidCallback onQueuePressed;
  final VoidCallback onEnterSongBook;
  final ValueChanged<String> onLanguageSelected;
  final ValueChanged<String> onAppendSearchToken;
  final VoidCallback onRemoveSearchCharacter;
  final VoidCallback onClearSearch;
  final ValueChanged<DemoSong> onRequestSong;
  final ValueChanged<DemoSong> onPrioritizeQueuedSong;
  final ValueChanged<DemoSong> onRemoveQueuedSong;
  final VoidCallback onSettingsPressed;
  final VoidCallback onToggleAudioMode;
  final VoidCallback onTogglePlayback;
  final VoidCallback onRestartPlayback;
  final VoidCallback onSkipSong;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final bool showLetterKeyboard =
        MediaQuery.orientationOf(context) == Orientation.landscape;
    final double sectionGap = showLetterKeyboard
        ? (compact ? 20 : 12)
        : (compact ? 20 : 10);
    final Widget rightColumn = _SongBookRightColumn(
      controller: controller,
      compact: compact,
      route: route,
      searchQuery: searchQuery,
      selectedLanguage: selectedLanguage,
      songs: songs,
      hasConfiguredDirectory: hasConfiguredDirectory,
      isScanningLibrary: isScanningLibrary,
      libraryScanErrorMessage: libraryScanErrorMessage,
      queuedSongs: queuedSongs,
      onBackPressed: onBackPressed,
      onQueuePressed: onQueuePressed,
      onEnterSongBook: onEnterSongBook,
      onLanguageSelected: onLanguageSelected,
      onRequestSong: onRequestSong,
      onPrioritizeQueuedSong: onPrioritizeQueuedSong,
      onRemoveQueuedSong: onRemoveQueuedSong,
      onSettingsPressed: onSettingsPressed,
      onToggleAudioMode: onToggleAudioMode,
      onTogglePlayback: onTogglePlayback,
      onRestartPlayback: onRestartPlayback,
      onSkipSong: onSkipSong,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _SongBookLeftColumn(
          controller: controller,
          searchController: searchController,
          route: route,
          compact: compact,
          showLetterKeyboard: showLetterKeyboard,
          onAppendSearchToken: onAppendSearchToken,
          onRemoveSearchCharacter: onRemoveSearchCharacter,
          onClearSearch: onClearSearch,
        ),
        SizedBox(height: sectionGap),
        if (compact) rightColumn else Expanded(child: rightColumn),
      ],
    );
  }
}

class _SongBookLeftColumn extends StatefulWidget {
  const _SongBookLeftColumn({
    required this.controller,
    required this.searchController,
    required this.route,
    required this.showLetterKeyboard,
    required this.onAppendSearchToken,
    required this.onRemoveSearchCharacter,
    required this.onClearSearch,
    this.compact = false,
  });

  final PlayerController controller;
  final TextEditingController searchController;
  final DemoRoute route;
  final bool showLetterKeyboard;
  final ValueChanged<String> onAppendSearchToken;
  final VoidCallback onRemoveSearchCharacter;
  final VoidCallback onClearSearch;
  final bool compact;

  @override
  State<_SongBookLeftColumn> createState() => _SongBookLeftColumnState();
}

class _SongBookLeftColumnState extends State<_SongBookLeftColumn> {
  bool _showNumberKeyboard = false;

  void _handleKeyboardKeyPressed(String key) {
    if (key == _numberKeyboardToggleLabel) {
      setState(() => _showNumberKeyboard = true);
      return;
    }
    if (key == _letterKeyboardToggleLabel) {
      setState(() => _showNumberKeyboard = false);
      return;
    }
    widget.onAppendSearchToken(key.toLowerCase());
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _SongBookSearchField(
          controller: widget.searchController,
          placeholder: widget.route == DemoRoute.queueList
              ? '搜索已点歌曲 / 歌手'
              : '输入歌名 / 中文 / 拼音首字母',
          enableSystemKeyboard: !widget.showLetterKeyboard,
          onBackspacePressed: widget.onRemoveSearchCharacter,
          onClearPressed: widget.onClearSearch,
        ),
        if (widget.showLetterKeyboard) ...<Widget>[
          SizedBox(height: widget.compact ? 6 : 8),
          _SearchKeyboard(
            showNumberKeyboard: _showNumberKeyboard,
            onKeyPressed: _handleKeyboardKeyPressed,
          ),
        ],
      ],
    );
  }
}

class _SongPreviewPlaceholder extends StatelessWidget {
  const _SongPreviewPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[Color(0xFF1C0634), Color(0xFF120520)],
        ),
      ),
    );
  }
}

class _SongBookSearchField extends StatelessWidget {
  const _SongBookSearchField({
    required this.controller,
    required this.placeholder,
    required this.enableSystemKeyboard,
    required this.onBackspacePressed,
    required this.onClearPressed,
  });

  final TextEditingController controller;
  final String placeholder;
  final bool enableSystemKeyboard;
  final VoidCallback onBackspacePressed;
  final VoidCallback onClearPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      decoration: BoxDecoration(
        color: const Color(0x24FFFFFF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: <Widget>[
          const SizedBox(width: 10),
          const Icon(Icons.search_rounded, size: 14, color: Color(0xCCFFF2FF)),
          const SizedBox(width: 6),
          Expanded(
            child: TextField(
              controller: controller,
              readOnly: !enableSystemKeyboard,
              showCursor: enableSystemKeyboard,
              enableInteractiveSelection: enableSystemKeyboard,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFFFFF7FF),
              ),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: placeholder,
                hintStyle: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Color(0x99F2DFFF),
                ),
              ),
            ),
          ),
          IconButton(
            onPressed: onBackspacePressed,
            splashRadius: 14,
            iconSize: 14,
            color: const Color(0xCCFFF2FF),
            icon: const Icon(Icons.backspace_outlined),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: Material(
              color: const Color(0x24FFFFFF),
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onClearPressed,
                child: const SizedBox(
                  width: 16,
                  height: 16,
                  child: Icon(
                    Icons.close_rounded,
                    size: 10,
                    color: Color(0xCCFFF2FF),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchKeyboard extends StatelessWidget {
  const _SearchKeyboard({
    required this.showNumberKeyboard,
    required this.onKeyPressed,
  });

  final bool showNumberKeyboard;
  final ValueChanged<String> onKeyPressed;

  @override
  Widget build(BuildContext context) {
    final List<List<String>> keyboardRows = showNumberKeyboard
        ? _numberKeyboardRows
        : _letterKeyboardRows;
    return Column(
      children: keyboardRows
          .map((List<String> row) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: row == keyboardRows.last ? 0 : 6,
              ),
              child: Row(
                children: row
                    .map((String key) {
                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                            right: key == row.last ? 0 : 6,
                          ),
                          child: _KeyboardKey(
                            label: key,
                            onPressed: () => onKeyPressed(key),
                          ),
                        ),
                      );
                    })
                    .toList(growable: false),
              ),
            );
          })
          .toList(growable: false),
    );
  }
}

class _KeyboardKey extends StatelessWidget {
  const _KeyboardKey({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    if (label == _keyboardSpacerLabel) {
      return const SizedBox(height: 22);
    }
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onPressed,
        child: Ink(
          height: 22,
          decoration: BoxDecoration(
            color: const Color(0x24FFFFFF),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: label.length > 1 ? 10 : 12,
                fontWeight: label.length > 1
                    ? FontWeight.w700
                    : FontWeight.w600,
                color: const Color(0xD9FFF6FF),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SongBookRightColumn extends StatefulWidget {
  const _SongBookRightColumn({
    required this.controller,
    required this.route,
    required this.searchQuery,
    required this.selectedLanguage,
    required this.songs,
    required this.hasConfiguredDirectory,
    required this.isScanningLibrary,
    required this.libraryScanErrorMessage,
    required this.queuedSongs,
    required this.onBackPressed,
    required this.onQueuePressed,
    required this.onEnterSongBook,
    required this.onLanguageSelected,
    required this.onRequestSong,
    required this.onPrioritizeQueuedSong,
    required this.onRemoveQueuedSong,
    required this.onSettingsPressed,
    required this.onToggleAudioMode,
    required this.onTogglePlayback,
    required this.onRestartPlayback,
    required this.onSkipSong,
    this.compact = false,
  });

  final PlayerController controller;
  final DemoRoute route;
  final String searchQuery;
  final String selectedLanguage;
  final List<DemoSong> songs;
  final bool hasConfiguredDirectory;
  final bool isScanningLibrary;
  final String? libraryScanErrorMessage;
  final List<DemoSong> queuedSongs;
  final VoidCallback onBackPressed;
  final VoidCallback onQueuePressed;
  final VoidCallback onEnterSongBook;
  final ValueChanged<String> onLanguageSelected;
  final ValueChanged<DemoSong> onRequestSong;
  final ValueChanged<DemoSong> onPrioritizeQueuedSong;
  final ValueChanged<DemoSong> onRemoveQueuedSong;
  final VoidCallback onSettingsPressed;
  final VoidCallback onToggleAudioMode;
  final VoidCallback onTogglePlayback;
  final VoidCallback onRestartPlayback;
  final VoidCallback onSkipSong;
  final bool compact;

  @override
  State<_SongBookRightColumn> createState() => _SongBookRightColumnState();
}

class _SongBookRightColumnState extends State<_SongBookRightColumn> {
  static const double _gridSpacing = 8;
  static const double _songTileHeight = 44;
  static const double _queueTileHeight = 48;
  static const double _paginationSectionHeight = 42;

  int _currentPage = 0;

  int _resolveCrossAxisCount(MediaQueryData media) {
    return media.size.width < 340 ? 1 : 2;
  }

  int _resolveRowsPerPage(MediaQueryData media, {required bool isLandscape}) {
    if (isLandscape) {
      return 4;
    }
    final double height = media.size.height;
    if (height >= 760) {
      return 6;
    }
    if (height >= 640) {
      return 5;
    }
    return 4;
  }

  int _resolveRowsPerPageForAvailableHeight({
    required double availableHeight,
    required bool isLandscape,
    required int fallbackRowsPerPage,
    required double tileHeight,
  }) {
    if (isLandscape) {
      return fallbackRowsPerPage;
    }
    final double listHeight = math.max(
      0,
      availableHeight - _paginationSectionHeight,
    );
    final int fittedRows =
        ((listHeight + _gridSpacing) / (tileHeight + _gridSpacing)).floor();
    return math.max(1, fittedRows);
  }

  int _computeMaxPage(int totalSongs, int songsPerPage) {
    if (totalSongs <= 0) {
      return 0;
    }
    return (totalSongs / songsPerPage).ceil() - 1;
  }

  @override
  Widget build(BuildContext context) {
    final MediaQueryData media = MediaQuery.of(context);
    final bool isLandscape = media.orientation == Orientation.landscape;
    final bool isQueueRoute = widget.route == DemoRoute.queueList;
    final int crossAxisCount = _resolveCrossAxisCount(media);
    final int fallbackRowsPerPage = _resolveRowsPerPage(
      media,
      isLandscape: isLandscape,
    );
    final double tileHeight = isQueueRoute ? _queueTileHeight : _songTileHeight;
    final List<_QueuedSongEntry> filteredQueueEntries = isQueueRoute
        ? _resolveFilteredQueueEntries()
        : const <_QueuedSongEntry>[];

    ({int currentPage, int totalPages, List<T> visibleItems})
    resolvePageData<T>(List<T> items, {required int rowsPerPage}) {
      final int itemsPerPage = crossAxisCount * rowsPerPage;
      final int maxPage = _computeMaxPage(items.length, itemsPerPage);
      if (_currentPage > maxPage) {
        _currentPage = maxPage;
      } else if (_currentPage < 0) {
        _currentPage = 0;
      }

      final int totalPages = items.isEmpty
          ? 1
          : (items.length / itemsPerPage).ceil();
      final int currentPage = _currentPage.clamp(0, totalPages - 1);
      final int startIndex = currentPage * itemsPerPage;
      final int endIndex = items.isEmpty
          ? 0
          : (startIndex + itemsPerPage).clamp(0, items.length);
      final List<T> visibleItems = items.isEmpty
          ? <T>[]
          : items.sublist(startIndex, endIndex);
      return (
        currentPage: currentPage,
        totalPages: totalPages,
        visibleItems: visibleItems,
      );
    }

    Widget buildLibraryContent(List<DemoSong> visibleSongs, int rowsPerPage) {
      if (!widget.hasConfiguredDirectory) {
        return const _EmptyContentCard(message: '请先在设置里选择扫描目录，扫描完成后这里会展示歌曲列表。');
      }
      if (widget.isScanningLibrary) {
        return const _EmptyContentCard(message: '正在扫描目录中的歌曲，请稍候。');
      }
      if (widget.libraryScanErrorMessage != null) {
        return _EmptyContentCard(message: widget.libraryScanErrorMessage!);
      }
      if (widget.songs.isEmpty) {
        return const _EmptyContentCard(
          message: '当前目录下没有扫描到可播放歌曲，请确认目录中包含 mp4、dat 等媒体文件。',
        );
      }

      final int visibleRowCount =
          ((visibleSongs.length + crossAxisCount - 1) / crossAxisCount)
              .clamp(1, rowsPerPage)
              .toInt();
      final double gridHeight =
          (_songTileHeight * visibleRowCount) +
          (_gridSpacing * (visibleRowCount - 1));

      return SizedBox(
        width: double.infinity,
        height: gridHeight,
        child: GridView.builder(
          padding: EdgeInsets.zero,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: _gridSpacing,
            crossAxisSpacing: _gridSpacing,
            mainAxisExtent: _songTileHeight,
          ),
          itemCount: visibleSongs.length,
          itemBuilder: (BuildContext context, int index) {
            final DemoSong song = visibleSongs[index];
            final bool isCurrent =
                widget.queuedSongs.isNotEmpty &&
                widget.queuedSongs.first == song;
            final bool isQueued = widget.queuedSongs.contains(song);
            return _SongTile(
              song: song,
              isCurrent: isCurrent,
              isQueued: isQueued,
              onTap: isQueued ? null : () => widget.onRequestSong(song),
            );
          },
        ),
      );
    }

    Widget buildQueueContent(
      List<_QueuedSongEntry> visibleEntries,
      int rowsPerPage,
    ) {
      if (widget.queuedSongs.isEmpty) {
        return const _EmptyContentCard(message: '当前还没有已点歌曲，点歌后会在这里显示。');
      }
      if (filteredQueueEntries.isEmpty) {
        return const _EmptyContentCard(message: '当前关键字下没有匹配的已点歌曲，试试清空搜索关键字。');
      }

      final int visibleRowCount =
          ((visibleEntries.length + crossAxisCount - 1) / crossAxisCount)
              .clamp(1, rowsPerPage)
              .toInt();
      final double gridHeight =
          (_queueTileHeight * visibleRowCount) +
          (_gridSpacing * (visibleRowCount - 1));

      return SizedBox(
        width: double.infinity,
        height: gridHeight,
        child: GridView.builder(
          padding: EdgeInsets.zero,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: _gridSpacing,
            crossAxisSpacing: _gridSpacing,
            mainAxisExtent: _queueTileHeight,
          ),
          itemCount: visibleEntries.length,
          itemBuilder: (BuildContext context, int index) {
            final _QueuedSongEntry entry = visibleEntries[index];
            return _QueuedSongTile(
              entry: entry,
              onPinToTop: entry.canPinToTop
                  ? () => widget.onPrioritizeQueuedSong(entry.song)
                  : null,
              onRemove: entry.isCurrent
                  ? null
                  : () => widget.onRemoveQueuedSong(entry.song),
            );
          },
        ),
      );
    }

    String breadcrumbLabel() {
      switch (widget.route) {
        case DemoRoute.home:
          return '‹ 主页';
        case DemoRoute.songBook:
          return '‹ 主页 / 歌名';
        case DemoRoute.queueList:
          return '‹ 主页 / 已点';
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _SongBookActionRow(
          controller: widget.controller,
          queueCount: widget.queuedSongs.length,
          compact: widget.compact,
          onQueuePressed: isQueueRoute ? null : widget.onQueuePressed,
          onSettingsPressed: widget.onSettingsPressed,
          onToggleAudioMode: widget.onToggleAudioMode,
          onTogglePlayback: widget.onTogglePlayback,
          onRestartPlayback: widget.onRestartPlayback,
          onSkipSong: widget.onSkipSong,
        ),
        const SizedBox(height: 8),
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                breadcrumbLabel(),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xEBFFF7FF),
                ),
              ),
            ),
            const SizedBox(width: 10),
            _ActionPill(
              label: '返回',
              icon: Icons.chevron_right_rounded,
              onPressed: widget.onBackPressed,
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (!isQueueRoute) ...<Widget>[
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _languageTabs
                  .map((String language) {
                    final bool selected = language == widget.selectedLanguage;
                    return Padding(
                      padding: EdgeInsets.only(
                        right: language == _languageTabs.last ? 0 : 4,
                      ),
                      child: Material(
                        color: selected
                            ? const Color(0x14FFFFFF)
                            : const Color(0x0AFFFFFF),
                        borderRadius: BorderRadius.circular(10),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () => widget.onLanguageSelected(language),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 3,
                            ),
                            child: Text(
                              language,
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: selected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: selected
                                    ? const Color(0xFFFF625E)
                                    : const Color(0xB8FFF0FF),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  })
                  .toList(growable: false),
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (widget.compact) ...<Widget>[
          Builder(
            builder: (BuildContext context) {
              if (isQueueRoute) {
                final ({
                  int currentPage,
                  int totalPages,
                  List<_QueuedSongEntry> visibleItems,
                })
                pageData = resolvePageData<_QueuedSongEntry>(
                  filteredQueueEntries,
                  rowsPerPage: fallbackRowsPerPage,
                );
                return buildQueueContent(
                  pageData.visibleItems,
                  fallbackRowsPerPage,
                );
              }
              final ({
                int currentPage,
                int totalPages,
                List<DemoSong> visibleItems,
              })
              pageData = resolvePageData<DemoSong>(
                widget.songs,
                rowsPerPage: fallbackRowsPerPage,
              );
              return buildLibraryContent(
                pageData.visibleItems,
                fallbackRowsPerPage,
              );
            },
          ),
          const SizedBox(height: 12),
          Builder(
            builder: (BuildContext context) {
              final pageData = isQueueRoute
                  ? resolvePageData<_QueuedSongEntry>(
                      filteredQueueEntries,
                      rowsPerPage: fallbackRowsPerPage,
                    )
                  : resolvePageData<DemoSong>(
                      widget.songs,
                      rowsPerPage: fallbackRowsPerPage,
                    );
              return _PaginationBar(
                currentPage: pageData.currentPage + 1,
                totalPages: pageData.totalPages,
                onPrevious: pageData.currentPage > 0
                    ? () => setState(() => _currentPage -= 1)
                    : null,
                onNext: pageData.currentPage < pageData.totalPages - 1
                    ? () => setState(() => _currentPage += 1)
                    : null,
              );
            },
          ),
        ] else
          Expanded(
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final int rowsPerPage = _resolveRowsPerPageForAvailableHeight(
                  availableHeight: constraints.maxHeight,
                  isLandscape: isLandscape,
                  fallbackRowsPerPage: fallbackRowsPerPage,
                  tileHeight: tileHeight,
                );
                final pageData = isQueueRoute
                    ? resolvePageData<_QueuedSongEntry>(
                        filteredQueueEntries,
                        rowsPerPage: rowsPerPage,
                      )
                    : resolvePageData<DemoSong>(
                        widget.songs,
                        rowsPerPage: rowsPerPage,
                      );
                return Column(
                  children: <Widget>[
                    Expanded(
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: isQueueRoute
                            ? buildQueueContent(
                                resolvePageData<_QueuedSongEntry>(
                                  filteredQueueEntries,
                                  rowsPerPage: rowsPerPage,
                                ).visibleItems,
                                rowsPerPage,
                              )
                            : buildLibraryContent(
                                resolvePageData<DemoSong>(
                                  widget.songs,
                                  rowsPerPage: rowsPerPage,
                                ).visibleItems,
                                rowsPerPage,
                              ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _PaginationBar(
                      currentPage: pageData.currentPage + 1,
                      totalPages: pageData.totalPages,
                      onPrevious: pageData.currentPage > 0
                          ? () => setState(() => _currentPage -= 1)
                          : null,
                      onNext: pageData.currentPage < pageData.totalPages - 1
                          ? () => setState(() => _currentPage += 1)
                          : null,
                    ),
                  ],
                );
              },
            ),
          ),
      ],
    );
  }

  List<_QueuedSongEntry> _resolveFilteredQueueEntries() {
    final String normalizedQuery = widget.searchQuery.trim().toLowerCase();
    final Iterable<_QueuedSongEntry> allEntries = widget.queuedSongs
        .asMap()
        .entries
        .map((MapEntry<int, DemoSong> entry) {
          return _QueuedSongEntry(song: entry.value, queueIndex: entry.key);
        });
    if (normalizedQuery.isEmpty) {
      return allEntries.toList(growable: false);
    }
    return allEntries
        .where(
          (_QueuedSongEntry entry) =>
              entry.song.searchIndex.contains(normalizedQuery),
        )
        .toList(growable: false);
  }
}

class _SongBookActionRow extends StatelessWidget {
  const _SongBookActionRow({
    required this.controller,
    required this.queueCount,
    required this.compact,
    required this.onQueuePressed,
    required this.onSettingsPressed,
    required this.onToggleAudioMode,
    required this.onTogglePlayback,
    required this.onRestartPlayback,
    required this.onSkipSong,
  });

  final PlayerController controller;
  final int queueCount;
  final bool compact;
  final VoidCallback? onQueuePressed;
  final VoidCallback onSettingsPressed;
  final VoidCallback onToggleAudioMode;
  final VoidCallback onTogglePlayback;
  final VoidCallback onRestartPlayback;
  final VoidCallback onSkipSong;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (BuildContext context, Widget? child) {
        return Align(
          alignment: compact ? Alignment.centerLeft : Alignment.centerRight,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                _ActionPill(
                  label: '已点$queueCount',
                  icon: Icons.queue_music_rounded,
                  onPressed: onQueuePressed,
                ),
                const SizedBox(width: 4),
                _ActionPill(
                  label:
                      controller.audioOutputMode ==
                          AudioOutputMode.accompaniment
                      ? '原唱'
                      : '伴唱',
                  icon: Icons.mic_rounded,
                  onPressed: controller.hasMedia ? onToggleAudioMode : null,
                ),
                const SizedBox(width: 4),
                _ActionPill(
                  label: '切歌',
                  icon: Icons.skip_next_rounded,
                  onPressed: controller.hasMedia || queueCount > 0
                      ? onSkipSong
                      : null,
                ),
                const SizedBox(width: 4),
                _ActionPill(
                  label: controller.isPlaying ? '暂停' : '播放',
                  icon: controller.isPlaying
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                  onPressed: controller.hasMedia ? onTogglePlayback : null,
                ),
                const SizedBox(width: 4),
                _ActionPill(
                  label: '重唱',
                  icon: Icons.replay_rounded,
                  onPressed: controller.hasMedia ? onRestartPlayback : null,
                ),
                const SizedBox(width: 4),
                _ActionPill(
                  label: '设置',
                  icon: Icons.settings_rounded,
                  onPressed: onSettingsPressed,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ActionPill extends StatelessWidget {
  const _ActionPill({required this.label, required this.icon, this.onPressed});

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final bool isEnabled = onPressed != null;
    return Material(
      color: isEnabled ? const Color(0x1AFFFFFF) : const Color(0x0DFFFFFF),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: isEnabled ? onPressed : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                icon,
                size: 12,
                color: isEnabled
                    ? const Color(0xCCFFF7FF)
                    : const Color(0x7AFFF7FF),
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: isEnabled
                      ? const Color(0xCCFFF7FF)
                      : const Color(0x7AFFF7FF),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SongTile extends StatelessWidget {
  const _SongTile({
    required this.song,
    required this.isCurrent,
    required this.isQueued,
    this.onTap,
  });

  final DemoSong song;
  final bool isCurrent;
  final bool isQueued;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Color backgroundColor = isCurrent
        ? const Color(0x29FFFFFF)
        : isQueued
        ? const Color(0x12FFFFFF)
        : const Color(0x1AFFFFFF);
    final Color subtitleColor = isCurrent
        ? const Color(0xCCF3DAFF)
        : isQueued
        ? const Color(0x80F3DAFF)
        : const Color(0xB8F3DAFF);

    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 6, 10, 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0x1AFFFFFF)),
          ),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      song.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        height: 1.15,
                        color: isQueued
                            ? const Color(0xA6FFF7FF)
                            : const Color(0xEDFFF7FF),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isCurrent
                          ? '${song.artist} · ${song.language} · 当前播放'
                          : isQueued
                          ? '${song.artist} · ${song.language} · 已点'
                          : '${song.artist} · ${song.language}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w500,
                        height: 1.2,
                        color: subtitleColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyContentCard extends StatelessWidget {
  const _EmptyContentCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 18),
      decoration: BoxDecoration(
        color: const Color(0x14FFFFFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x14FFFFFF)),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Color(0xCCF3DAFF), height: 1.5),
      ),
    );
  }
}

class _PaginationBar extends StatelessWidget {
  const _PaginationBar({
    required this.currentPage,
    required this.totalPages,
    this.onPrevious,
    this.onNext,
  });

  final int currentPage;
  final int totalPages;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 12,
        children: <Widget>[
          _PaginationButton(label: '上一页', onPressed: onPrevious),
          Text(
            '$currentPage/$totalPages',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Color(0xCCFFF2FF),
            ),
          ),
          _PaginationButton(label: '下一页', onPressed: onNext),
        ],
      ),
    );
  }
}

class _PaginationButton extends StatelessWidget {
  const _PaginationButton({required this.label, this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final bool enabled = onPressed != null;
    return Material(
      color: enabled ? const Color(0x16FFFFFF) : const Color(0x0DFFFFFF),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: enabled
                  ? const Color(0xCCFFF2FF)
                  : const Color(0x7AFFF2FF),
            ),
          ),
        ),
      ),
    );
  }
}
