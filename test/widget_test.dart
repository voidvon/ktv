import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ktv2/ktv2.dart';
import 'package:maimai_ktv/core/models/artist.dart';
import 'package:maimai_ktv/core/models/song.dart';
import 'package:maimai_ktv/core/models/song_identity.dart';
import 'package:maimai_ktv/features/ktv/application/download_manager_models.dart';
import 'package:maimai_ktv/features/ktv/application/ktv_controller.dart';
import 'package:maimai_ktv/features/ktv/presentation/songbook_contracts.dart';
import 'package:maimai_ktv/features/ktv/presentation/songbook_page.dart';
import 'package:maimai_ktv/features/ktv/presentation/songbook_right_column_widgets.dart';
import 'package:maimai_ktv/features/ktv/presentation/shared_widgets.dart';
import 'package:maimai_ktv/features/player/presentation/player_progress_bar.dart';
import 'package:maimai_ktv/main.dart';

void main() {
  SongBookCallbacks buildSongBookCallbacks() {
    return SongBookCallbacks(
      navigation: SongBookNavigationCallbacks(
        onBackPressed: () {},
        onQueuePressed: () {},
        onSelectArtist: (_) {},
        onSettingsPressed: () {},
      ),
      library: SongBookLibraryCallbacks(
        onLanguageSelected: (_) {},
        onAppendSearchToken: (_) {},
        onRemoveSearchCharacter: () {},
        onClearSearch: () {},
        onRequestLibraryPage: (_, _) {},
        onRequestSong: (_) {},
        onToggleFavorite: (_) {},
        onDownloadSong: (_) {},
      ),
      playback: SongBookPlaybackCallbacks(
        onPrioritizeQueuedSong: (_) {},
        onRemoveQueuedSong: (_) {},
        onToggleAudioMode: () {},
        onTogglePlayback: () {},
        onRestartPlayback: () {},
        onSkipSong: () {},
      ),
    );
  }

  testWidgets('shows home shell before media library is selected', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const KtvApp());

    expect(find.text('楹﹂害KTV'), findsOneWidget);
    expect(find.text('姝屽悕'), findsOneWidget);
    expect(find.text('璁剧疆'), findsAtLeastNWidgets(1));
    expect(find.text('棣栭〉棰勮鍖?), findsNothing);
    expect(find.byType(Slider), findsOneWidget);
  });

  testWidgets('opens scan directory settings dialog from top actions', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const KtvApp());

    await tester.tap(find.text('璁剧疆').first);
    await tester.pumpAndSettle();

    expect(find.text('璁剧疆'), findsOneWidget);
    expect(find.text('鏈湴鐩綍'), findsOneWidget);
    expect(find.text('鐧惧害缃戠洏'), findsOneWidget);
  });

  testWidgets('opens queued songs page from home toolbar', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const KtvApp());

    await tester.tap(find.text('宸茬偣0').first);
    await tester.pumpAndSettle();

    expect(find.text('涓婚〉 / 宸茬偣'), findsOneWidget);
    expect(find.text('褰撳墠杩樻病鏈夊凡鐐规瓕鏇诧紝鐐规瓕鍚庝細鍦ㄨ繖閲屾樉绀恒€?), findsOneWidget);
    expect(find.text('鎼滅储宸茬偣姝屾洸 / 姝屾墜'), findsOneWidget);
  });

  testWidgets('renders compact song book without layout exceptions', (
    WidgetTester tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(430, 932);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(const KtvApp());

    await tester.tap(find.text('姝屽悕'));
    await tester.pumpAndSettle();

    expect(find.text('璇峰厛鍦ㄨ缃噷閰嶇疆鏁版嵁婧愶紝閰嶇疆瀹屾垚鍚庤繖閲屼細灞曠ず鑱氬悎鏇插簱銆?), findsOneWidget);
  });

  testWidgets('renders landscape song book without layout exceptions', (
    WidgetTester tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(932, 430);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(const KtvApp());

    await tester.tap(find.text('姝屽悕'));
    await tester.pumpAndSettle();

    expect(find.text('涓婚〉 / 姝屽悕'), findsOneWidget);
    expect(find.text('璇峰厛鍦ㄨ缃噷閰嶇疆鏁版嵁婧愶紝閰嶇疆瀹屾垚鍚庤繖閲屼細灞曠ず鑱氬悎鏇插簱銆?), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders landscape artist grid without layout exceptions', (
    WidgetTester tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(932, 430);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final TextEditingController searchController = TextEditingController();
    addTearDown(searchController.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SongBookPage(
            controller: _TestPlayerController(),
            searchController: searchController,
            viewModel: const SongBookViewModel(
              navigation: SongBookNavigationViewModel(
                route: KtvRoute.songBook,
                songBookMode: SongBookMode.artists,
                libraryScope: LibraryScope.aggregated,
                selectedArtist: null,
                breadcrumbLabel: '涓婚〉 / 姝屾槦',
              ),
              library: SongBookLibraryViewModel(
                searchQuery: '',
                selectedLanguage: '鍏ㄩ儴',
                songs: <Song>[],
                artists: <Artist>[
                  Artist(name: '鍛ㄦ澃浼?, songCount: 12, searchIndex: 'zhoujielun'),
                  Artist(name: '鍒樿嫢鑻?, songCount: 8, searchIndex: 'liuruoying'),
                  Artist(
                    name: '寮犲鍙?,
                    songCount: 15,
                    searchIndex: 'zhangxueyou',
                  ),
                  Artist(name: 'A-Lin', songCount: 6, searchIndex: 'a-lin'),
                  Artist(name: '閭撶传妫?, songCount: 10, searchIndex: 'dengziqi'),
                  Artist(name: 'Beyond', songCount: 9, searchIndex: 'beyond'),
                ],
                favoriteSongIds: <String>[],
                downloadableSourceIds: <String>{},
                downloadingSongIds: <String>{},
                downloadedSongKeys: <String>{},
                totalCount: 6,
                pageIndex: 0,
                totalPages: 1,
                pageSize: 6,
                hasConfiguredDirectory: true,
                hasConfiguredAggregatedSources: true,
                isScanning: false,
                isLoadingPage: false,
                scanErrorMessage: null,
              ),
              playback: SongBookPlaybackViewModel(queuedSongs: <Song>[]),
            ),
            callbacks: SongBookCallbacks(
              navigation: SongBookNavigationCallbacks(
                onBackPressed: () {},
                onQueuePressed: () {},
                onSelectArtist: (_) {},
                onSettingsPressed: () {},
              ),
              library: SongBookLibraryCallbacks(
                onLanguageSelected: (_) {},
                onAppendSearchToken: (_) {},
                onRemoveSearchCharacter: () {},
                onClearSearch: () {},
                onRequestLibraryPage: (_, _) {},
                onRequestSong: (_) {},
                onToggleFavorite: (_) {},
                onDownloadSong: (_) {},
              ),
              playback: SongBookPlaybackCallbacks(
                onPrioritizeQueuedSong: (_) {},
                onRemoveQueuedSong: (_) {},
                onToggleAudioMode: () {},
                onTogglePlayback: () {},
                onRestartPlayback: () {},
                onSkipSong: () {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('涓婚〉 / 姝屾槦'), findsOneWidget);
    expect(find.text('鍛ㄦ澃浼?), findsAtLeastNWidgets(1));
    expect(find.text('鍒樿嫢鑻?), findsAtLeastNWidgets(1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('landscape song book uses visible capacity to show page count', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 700,
            height: 520,
            child: SongBookRightColumn(
              controller: _TestPlayerController(),
              viewModel: SongBookViewModel(
                navigation: const SongBookNavigationViewModel(
                  route: KtvRoute.songBook,
                  songBookMode: SongBookMode.songs,
                  libraryScope: LibraryScope.aggregated,
                  selectedArtist: null,
                  breadcrumbLabel: '涓婚〉 / 姝屽悕',
                ),
                library: SongBookLibraryViewModel(
                  searchQuery: '',
                  selectedLanguage: '鍏ㄩ儴',
                  songs: <Song>[
                    Song(
                      songId: buildAggregateSongId(title: '闈掕姳鐡?, artist: '鍛ㄦ澃浼?),
                      sourceId: 'local',
                      sourceSongId: buildLocalSourceSongId(
                        fingerprint: buildLocalMetadataFingerprint(
                          locator: '/tmp/1.mp4',
                        ),
                      ),
                      title: '闈掕姳鐡?,
                      artist: '鍛ㄦ澃浼?,
                      languages: <String>['鍥借'],
                      searchIndex: 'qinghuaci zhoujielun',
                      mediaPath: '/tmp/1.mp4',
                    ),
                    Song(
                      songId: buildAggregateSongId(title: '澶滄洸', artist: '鍛ㄦ澃浼?),
                      sourceId: 'local',
                      sourceSongId: buildLocalSourceSongId(
                        fingerprint: buildLocalMetadataFingerprint(
                          locator: '/tmp/2.mp4',
                        ),
                      ),
                      title: '澶滄洸',
                      artist: '鍛ㄦ澃浼?,
                      languages: <String>['鍥借'],
                      searchIndex: 'yequ zhoujielun',
                      mediaPath: '/tmp/2.mp4',
                    ),
                    Song(
                      songId: buildAggregateSongId(title: '鍚庢潵', artist: '鍒樿嫢鑻?),
                      sourceId: 'local',
                      sourceSongId: buildLocalSourceSongId(
                        fingerprint: buildLocalMetadataFingerprint(
                          locator: '/tmp/3.mp4',
                        ),
                      ),
                      title: '鍚庢潵',
                      artist: '鍒樿嫢鑻?,
                      languages: <String>['鍥借'],
                      searchIndex: 'houlai liuruoying',
                      mediaPath: '/tmp/3.mp4',
                    ),
                    Song(
                      songId: buildAggregateSongId(
                        title: '娴烽様澶╃┖',
                        artist: 'Beyond',
                      ),
                      sourceId: 'local',
                      sourceSongId: buildLocalSourceSongId(
                        fingerprint: buildLocalMetadataFingerprint(
                          locator: '/tmp/4.mp4',
                        ),
                      ),
                      title: '娴烽様澶╃┖',
                      artist: 'Beyond',
                      languages: <String>['绮よ'],
                      searchIndex: 'haikuotiankong beyond',
                      mediaPath: '/tmp/4.mp4',
                    ),
                  ],
                  artists: <Artist>[],
                  favoriteSongIds: <String>[],
                  downloadableSourceIds: <String>{},
                  downloadingSongIds: <String>{},
                  downloadedSongKeys: <String>{},
                  totalCount: 4,
                  pageIndex: 0,
                  totalPages: 2,
                  pageSize: 2,
                  hasConfiguredDirectory: true,
                  hasConfiguredAggregatedSources: true,
                  isScanning: false,
                  isLoadingPage: false,
                  scanErrorMessage: null,
                ),
                playback: SongBookPlaybackViewModel(queuedSongs: <Song>[]),
              ),
              callbacks: SongBookCallbacks(
                navigation: SongBookNavigationCallbacks(
                  onBackPressed: () {},
                  onQueuePressed: () {},
                  onSelectArtist: (_) {},
                  onSettingsPressed: () {},
                ),
                library: SongBookLibraryCallbacks(
                  onLanguageSelected: (_) {},
                  onAppendSearchToken: (_) {},
                  onRemoveSearchCharacter: () {},
                  onClearSearch: () {},
                  onRequestLibraryPage: (_, _) {},
                  onRequestSong: (_) {},
                  onToggleFavorite: (_) {},
                  onDownloadSong: (_) {},
                ),
                playback: SongBookPlaybackCallbacks(
                  onPrioritizeQueuedSong: (_) {},
                  onRemoveQueuedSong: (_) {},
                  onToggleAudioMode: () {},
                  onTogglePlayback: () {},
                  onRestartPlayback: () {},
                  onSkipSong: () {},
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('1/1'), findsOneWidget);
  });

  testWidgets(
    'landscape song book increases visible capacity on larger window',
    (WidgetTester tester) async {
      String resolvePaginationLabel() {
        final Iterable<Text> textWidgets = tester
            .widgetList<Text>(find.byType(Text))
            .where((Text text) => text.data != null);
        final Text pagination = textWidgets.firstWhere(
          (Text text) => RegExp(r'^\d+/\d+$').hasMatch(text.data!),
        );
        return pagination.data!;
      }

      ({int currentPage, int totalPages}) parsePaginationLabel(String label) {
        final List<String> parts = label.split('/');
        return (
          currentPage: int.parse(parts[0]),
          totalPages: int.parse(parts[1]),
        );
      }

      Future<void> pumpSongBook(double width, double height) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: width,
                height: height,
                child: SongBookRightColumn(
                  controller: _TestPlayerController(),
                  viewModel: SongBookViewModel(
                    navigation: const SongBookNavigationViewModel(
                      route: KtvRoute.songBook,
                      songBookMode: SongBookMode.songs,
                      libraryScope: LibraryScope.aggregated,
                      selectedArtist: null,
                      breadcrumbLabel: '涓婚〉 / 姝屽悕',
                    ),
                    library: SongBookLibraryViewModel(
                      searchQuery: '',
                      selectedLanguage: '鍏ㄩ儴',
                      songs: List<Song>.generate(
                        9,
                        (int index) => Song(
                          songId: buildAggregateSongId(
                            title: '姝屾洸$index',
                            artist: '姝屾墜$index',
                          ),
                          sourceId: 'local',
                          sourceSongId: buildLocalSourceSongId(
                            fingerprint: buildLocalMetadataFingerprint(
                              locator: '/tmp/$index.mp4',
                            ),
                          ),
                          title: '姝屾洸$index',
                          artist: '姝屾墜$index',
                          languages: const <String>['鍥借'],
                          searchIndex: 'gequ$index geshou$index',
                          mediaPath: '/tmp/$index.mp4',
                        ),
                      ),
                      artists: <Artist>[],
                      favoriteSongIds: <String>[],
                      downloadableSourceIds: const <String>{},
                      downloadingSongIds: <String>{},
                      downloadedSongKeys: const <String>{},
                      totalCount: 9,
                      pageIndex: 0,
                      totalPages: 5,
                      pageSize: 2,
                      hasConfiguredDirectory: true,
                      hasConfiguredAggregatedSources: true,
                      isScanning: false,
                      isLoadingPage: false,
                      scanErrorMessage: null,
                    ),
                    playback: const SongBookPlaybackViewModel(
                      queuedSongs: <Song>[],
                    ),
                  ),
                  callbacks: SongBookCallbacks(
                    navigation: SongBookNavigationCallbacks(
                      onBackPressed: () {},
                      onQueuePressed: () {},
                      onSelectArtist: (_) {},
                      onSettingsPressed: () {},
                    ),
                    library: SongBookLibraryCallbacks(
                      onLanguageSelected: (_) {},
                      onAppendSearchToken: (_) {},
                      onRemoveSearchCharacter: () {},
                      onClearSearch: () {},
                      onRequestLibraryPage: (_, _) {},
                      onRequestSong: (_) {},
                      onToggleFavorite: (_) {},
                      onDownloadSong: (_) {},
                    ),
                    playback: SongBookPlaybackCallbacks(
                      onPrioritizeQueuedSong: (_) {},
                      onRemoveQueuedSong: (_) {},
                      onToggleAudioMode: () {},
                      onTogglePlayback: () {},
                      onRestartPlayback: () {},
                      onSkipSong: () {},
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
      }

      await pumpSongBook(700, 250);
      final smallWindowPagination = parsePaginationLabel(
        resolvePaginationLabel(),
      );

      await pumpSongBook(980, 620);
      final largeWindowPagination = parsePaginationLabel(
        resolvePaginationLabel(),
      );

      expect(smallWindowPagination.currentPage, 1);
      expect(largeWindowPagination.currentPage, 1);
      expect(
        largeWindowPagination.totalPages,
        lessThan(smallWindowPagination.totalPages),
      );
    },
  );

  testWidgets('compact song grid keeps at least two columns', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 320,
            height: 640,
            child: SongBookRightColumn(
              controller: _TestPlayerController(),
              viewModel: SongBookViewModel(
                navigation: const SongBookNavigationViewModel(
                  route: KtvRoute.songBook,
                  songBookMode: SongBookMode.songs,
                  libraryScope: LibraryScope.aggregated,
                  selectedArtist: null,
                  breadcrumbLabel: '涓婚〉 / 姝屽悕',
                ),
                library: SongBookLibraryViewModel(
                  searchQuery: '',
                  selectedLanguage: '鍏ㄩ儴',
                  songs: List<Song>.generate(
                    6,
                    (int index) => Song(
                      songId: buildAggregateSongId(
                        title: '姝屾洸$index',
                        artist: '姝屾墜$index',
                      ),
                      sourceId: 'local',
                      sourceSongId: buildLocalSourceSongId(
                        fingerprint: buildLocalMetadataFingerprint(
                          locator: '/tmp/song_$index.mp4',
                        ),
                      ),
                      title: '姝屾洸$index',
                      artist: '姝屾墜$index',
                      languages: const <String>['鍥借'],
                      searchIndex: 'gequ$index geshou$index',
                      mediaPath: '/tmp/song_$index.mp4',
                    ),
                  ),
                  artists: const <Artist>[],
                  favoriteSongIds: const <String>[],
                  downloadableSourceIds: <String>{},
                  downloadingSongIds: <String>{},
                  downloadedSongKeys: <String>{},
                  totalCount: 6,
                  pageIndex: 0,
                  totalPages: 1,
                  pageSize: 6,
                  hasConfiguredDirectory: true,
                  hasConfiguredAggregatedSources: true,
                  isScanning: false,
                  isLoadingPage: false,
                  scanErrorMessage: null,
                ),
                playback: const SongBookPlaybackViewModel(
                  queuedSongs: <Song>[],
                ),
              ),
              callbacks: buildSongBookCallbacks(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final GridView grid = tester.widget<GridView>(find.byType(GridView).first);
    final SliverGridDelegateWithFixedCrossAxisCount delegate =
        grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
    expect(delegate.crossAxisCount, 2);
  });

  testWidgets('compact artist grid keeps at least three columns', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 320,
            height: 640,
            child: SongBookRightColumn(
              controller: _TestPlayerController(),
              viewModel: const SongBookViewModel(
                navigation: SongBookNavigationViewModel(
                  route: KtvRoute.songBook,
                  songBookMode: SongBookMode.artists,
                  libraryScope: LibraryScope.aggregated,
                  selectedArtist: null,
                  breadcrumbLabel: '涓婚〉 / 姝屾槦',
                ),
                library: SongBookLibraryViewModel(
                  searchQuery: '',
                  selectedLanguage: '鍏ㄩ儴',
                  songs: <Song>[],
                  artists: <Artist>[
                    Artist(
                      name: '鍛ㄦ澃浼?,
                      songCount: 12,
                      searchIndex: 'zhoujielun',
                    ),
                    Artist(
                      name: '鏋椾繆鏉?,
                      songCount: 10,
                      searchIndex: 'linjunjie',
                    ),
                    Artist(
                      name: '寮犲鍙?,
                      songCount: 8,
                      searchIndex: 'zhangxueyou',
                    ),
                    Artist(
                      name: '鍒樿嫢鑻?,
                      songCount: 6,
                      searchIndex: 'liuruoying',
                    ),
                    Artist(name: '闄堝杩?, songCount: 9, searchIndex: 'chenyixun'),
                    Artist(name: '瀛欑嚂濮?, songCount: 7, searchIndex: 'sunyanzi'),
                  ],
                  favoriteSongIds: <String>[],
                  downloadableSourceIds: <String>{},
                  downloadingSongIds: <String>{},
                  downloadedSongKeys: <String>{},
                  totalCount: 6,
                  pageIndex: 0,
                  totalPages: 1,
                  pageSize: 6,
                  hasConfiguredDirectory: true,
                  hasConfiguredAggregatedSources: true,
                  isScanning: false,
                  isLoadingPage: false,
                  scanErrorMessage: null,
                ),
                playback: SongBookPlaybackViewModel(queuedSongs: <Song>[]),
              ),
              callbacks: buildSongBookCallbacks(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final GridView grid = tester.widget<GridView>(find.byType(GridView).first);
    final SliverGridDelegateWithFixedCrossAxisCount delegate =
        grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
    expect(delegate.crossAxisCount, greaterThanOrEqualTo(3));
  });

  testWidgets('wide artist grid increases columns responsively', (
    WidgetTester tester,
  ) async {
    Future<int> pumpArtistGrid(double width) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: width,
              height: 430,
              child: SongBookRightColumn(
                controller: _TestPlayerController(),
                viewModel: const SongBookViewModel(
                  navigation: SongBookNavigationViewModel(
                    route: KtvRoute.songBook,
                    songBookMode: SongBookMode.artists,
                    libraryScope: LibraryScope.aggregated,
                    selectedArtist: null,
                    breadcrumbLabel: '涓婚〉 / 姝屾槦',
                  ),
                  library: SongBookLibraryViewModel(
                    searchQuery: '',
                    selectedLanguage: '鍏ㄩ儴',
                    songs: <Song>[],
                    artists: <Artist>[
                      Artist(
                        name: '鍛ㄦ澃浼?,
                        songCount: 12,
                        searchIndex: 'zhoujielun',
                      ),
                      Artist(
                        name: '鏋椾繆鏉?,
                        songCount: 10,
                        searchIndex: 'linjunjie',
                      ),
                      Artist(
                        name: '寮犲鍙?,
                        songCount: 8,
                        searchIndex: 'zhangxueyou',
                      ),
                      Artist(
                        name: '鍒樿嫢鑻?,
                        songCount: 6,
                        searchIndex: 'liuruoying',
                      ),
                      Artist(
                        name: '闄堝杩?,
                        songCount: 9,
                        searchIndex: 'chenyixun',
                      ),
                      Artist(
                        name: '瀛欑嚂濮?,
                        songCount: 7,
                        searchIndex: 'sunyanzi',
                      ),
                      Artist(name: '鐜嬭彶', songCount: 5, searchIndex: 'wangfei'),
                      Artist(
                        name: '浜旀湀澶?,
                        songCount: 11,
                        searchIndex: 'wuyuetian',
                      ),
                    ],
                    favoriteSongIds: <String>[],
                    downloadableSourceIds: <String>{},
                    downloadingSongIds: <String>{},
                    downloadedSongKeys: <String>{},
                    totalCount: 8,
                    pageIndex: 0,
                    totalPages: 1,
                    pageSize: 8,
                    hasConfiguredDirectory: true,
                    hasConfiguredAggregatedSources: true,
                    isScanning: false,
                    isLoadingPage: false,
                    scanErrorMessage: null,
                  ),
                  playback: SongBookPlaybackViewModel(queuedSongs: <Song>[]),
                ),
                callbacks: buildSongBookCallbacks(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final GridView grid = tester.widget<GridView>(
        find.byType(GridView).first,
      );
      final SliverGridDelegateWithFixedCrossAxisCount delegate =
          grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
      return delegate.crossAxisCount;
    }

    final int mediumColumns = await pumpArtistGrid(430);
    final int expandedColumns = await pumpArtistGrid(540);
    final int wideColumns = await pumpArtistGrid(900);

    expect(mediumColumns, 6);
    expect(expandedColumns, greaterThan(mediumColumns));
    expect(expandedColumns, 7);
    expect(wideColumns, greaterThan(mediumColumns));
  });

  testWidgets('artist tile keeps artist name below avatar in compact mode', (
    WidgetTester tester,
  ) async {
    const Artist artist = Artist(
      name: 'Alice Singer',
      songCount: 12,
      searchIndex: 'alice singer',
    );
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 76,
              height: 65,
              child: ArtistTile(artist: artist),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final Rect avatarRect = tester.getRect(find.text(artist.avatarLabel));
    final Rect nameRect = tester.getRect(find.text(artist.name));
    expect(nameRect.top, greaterThan(avatarRect.bottom));
  });

  testWidgets(
    'cloud songs show status icon instead of clickable download button',
    (WidgetTester tester) async {
      final Song song = Song(
        songId: buildAggregateSongId(title: '浜戠姝屾洸', artist: '浜戠姝屾墜'),
        sourceId: 'baidu_pan',
        sourceSongId: 'fsid-cloud-icon',
        title: '浜戠姝屾洸',
        artist: '浜戠姝屾墜',
        languages: const <String>['鍥借'],
        searchIndex: 'cloud song',
        mediaPath: '',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 320,
                height: 64,
                child: SongTile(
                  title: song.title,
                  subtitle: '${song.artist} 路 ${song.language}',
                  trailing: const Icon(Icons.cloud_rounded),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.cloud_rounded), findsOneWidget);
      expect(find.byIcon(Icons.download_rounded), findsNothing);
    },
  );

  testWidgets(
    'queued song tile reuses shared text style and shows queue actions',
    (WidgetTester tester) async {
      final Song librarySong = Song(
        songId: buildAggregateSongId(title: '鐐规瓕鍒楄〃姝屾洸', artist: '姝屾墜鐢?),
        sourceId: 'local',
        sourceSongId: buildLocalSourceSongId(
          fingerprint: buildLocalMetadataFingerprint(
            locator: '/tmp/library.mp4',
          ),
        ),
        title: '鐐规瓕鍒楄〃姝屾洸',
        artist: '姝屾墜鐢?,
        languages: const <String>['鍥借'],
        searchIndex: 'library song',
        mediaPath: '/tmp/library.mp4',
      );
      final Song queuedSong = Song(
        songId: buildAggregateSongId(title: '宸茬偣鍒楄〃姝屾洸', artist: '姝屾墜涔?),
        sourceId: 'local',
        sourceSongId: buildLocalSourceSongId(
          fingerprint: buildLocalMetadataFingerprint(locator: '/tmp/queue.mp4'),
        ),
        title: '宸茬偣鍒楄〃姝屾洸',
        artist: '姝屾墜涔?,
        languages: const <String>['鍥借'],
        searchIndex: 'queued song',
        mediaPath: '/tmp/queue.mp4',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: <Widget>[
                SizedBox(
                  width: 320,
                  height: 64,
                  child: SongTile(
                    title: librarySong.title,
                    subtitle: '${librarySong.artist} 路 ${librarySong.language}',
                    trailing: SongTileIconButton(
                      icon: Icons.favorite_border_rounded,
                      onPressed: () {},
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: 320,
                  height: 64,
                  child: SongTile(
                    title: queuedSong.title,
                    subtitle:
                        '${queuedSong.artist} 路 ${queuedSong.language} 路 闃熷垪 2',
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        SongTileIconButton(
                          icon: Icons.vertical_align_top_rounded,
                          onPressed: () {},
                        ),
                        const SizedBox(width: 4),
                        SongTileIconButton(
                          icon: Icons.delete_outline_rounded,
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final Text libraryTitle = tester.widget<Text>(find.text('鐐规瓕鍒楄〃姝屾洸'));
      final Text queuedTitle = tester.widget<Text>(find.text('宸茬偣鍒楄〃姝屾洸'));
      final Text librarySubtitle = tester.widget<Text>(find.text('姝屾墜鐢?路 鍥借'));
      final Text queuedSubtitle = tester.widget<Text>(
        find.text('姝屾墜涔?路 鍥借 路 闃熷垪 2'),
      );

      expect(queuedTitle.style?.fontSize, libraryTitle.style?.fontSize);
      expect(queuedTitle.style?.fontWeight, libraryTitle.style?.fontWeight);
      expect(queuedSubtitle.style?.fontSize, librarySubtitle.style?.fontSize);
      expect(
        queuedSubtitle.style?.fontWeight,
        librarySubtitle.style?.fontWeight,
      );
      expect(find.byIcon(Icons.vertical_align_top_rounded), findsOneWidget);
      expect(find.byIcon(Icons.delete_outline_rounded), findsOneWidget);
      expect(find.byIcon(Icons.favorite_border_rounded), findsOneWidget);
    },
  );

  testWidgets('downloading cloud songs show a thin progress bar', (
    WidgetTester tester,
  ) async {
    final Song song = Song(
      songId: buildAggregateSongId(title: '涓嬭浇涓殑浜戠姝屾洸', artist: '浜戠姝屾墜'),
      sourceId: 'baidu_pan',
      sourceSongId: 'fsid-cloud-progress',
      title: '涓嬭浇涓殑浜戠姝屾洸',
      artist: '浜戠姝屾墜',
      languages: const <String>['鍥借'],
      searchIndex: 'downloading cloud song',
      mediaPath: '',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 320,
              height: 64,
              child: SongTile(
                title: song.title,
                subtitle: '${song.artist} 路 ${song.language}',
                downloadProgress: 0.4,
                progressKey: ValueKey<String>(
                  'song-download-progress-${song.songId}',
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final Finder progressFinder = find.byKey(
      ValueKey<String>('song-download-progress-${song.songId}'),
    );
    expect(progressFinder, findsOneWidget);
    expect(tester.widget<LinearProgressIndicator>(progressFinder).value, 0.4);
    expect(find.byIcon(Icons.cloud_rounded), findsNothing);
    expect(find.byIcon(Icons.cloud_sync_rounded), findsNothing);
  });

  testWidgets('paused queued downloads hide pin action and keep progress bar', (
    WidgetTester tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(932, 430);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final TextEditingController searchController = TextEditingController();
    addTearDown(searchController.dispose);

    final Song pausedSong = Song(
      songId: buildAggregateSongId(title: '鏆傚仠涓嬭浇姝屾洸', artist: '浜戠姝屾墜'),
      sourceId: 'baidu_pan',
      sourceSongId: 'fsid-paused',
      title: '鏆傚仠涓嬭浇姝屾洸',
      artist: '浜戠姝屾墜',
      languages: const <String>['鍥借'],
      searchIndex: '鏆傚仠涓嬭浇姝屾洸 浜戠姝屾墜',
      mediaPath: '',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SongBookPage(
            controller: _TestPlayerController(),
            searchController: searchController,
            viewModel: SongBookViewModel(
              navigation: const SongBookNavigationViewModel(
                route: KtvRoute.queueList,
                songBookMode: SongBookMode.songs,
                libraryScope: LibraryScope.aggregated,
                selectedArtist: null,
                breadcrumbLabel: '涓婚〉 / 宸茬偣',
              ),
              library: SongBookLibraryViewModel(
                searchQuery: '',
                selectedLanguage: '鍏ㄩ儴',
                songs: const <Song>[],
                artists: const <Artist>[],
                favoriteSongIds: const <String>[],
                downloadableSourceIds: const <String>{'baidu_pan'},
                downloadingSongIds: <String>{pausedSong.songId},
                downloadingSongProgressByKey: const <String, double>{
                  'baidu_pan::fsid-paused': 0.4,
                },
                downloadTaskStatusByKey: const <String, DownloadTaskStatus>{
                  'baidu_pan::fsid-paused': DownloadTaskStatus.paused,
                },
                downloadedSongKeys: const <String>{},
                totalCount: 0,
                pageIndex: 0,
                totalPages: 1,
                pageSize: 12,
                hasConfiguredDirectory: true,
                hasConfiguredAggregatedSources: true,
                isScanning: false,
                isLoadingPage: false,
                scanErrorMessage: null,
              ),
              playback: SongBookPlaybackViewModel(
                queuedSongs: <Song>[pausedSong],
              ),
            ),
            callbacks: buildSongBookCallbacks(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('浜戠姝屾墜 路 鍥借 路 宸叉殏鍋?), findsOneWidget);
    expect(
      find.byKey(
        ValueKey<String>('song-download-progress-${pausedSong.songId}'),
      ),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.vertical_align_top_rounded), findsNothing);
    expect(find.byIcon(Icons.delete_outline_rounded), findsOneWidget);
  });

  testWidgets('failed queued downloads hide pin action and show failed state', (
    WidgetTester tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(932, 430);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final TextEditingController searchController = TextEditingController();
    addTearDown(searchController.dispose);

    final Song failedSong = Song(
      songId: buildAggregateSongId(title: '澶辫触涓嬭浇姝屾洸', artist: '浜戠姝屾墜'),
      sourceId: 'baidu_pan',
      sourceSongId: 'fsid-failed',
      title: '澶辫触涓嬭浇姝屾洸',
      artist: '浜戠姝屾墜',
      languages: const <String>['鍥借'],
      searchIndex: '澶辫触涓嬭浇姝屾洸 浜戠姝屾墜',
      mediaPath: '',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SongBookPage(
            controller: _TestPlayerController(),
            searchController: searchController,
            viewModel: SongBookViewModel(
              navigation: const SongBookNavigationViewModel(
                route: KtvRoute.queueList,
                songBookMode: SongBookMode.songs,
                libraryScope: LibraryScope.aggregated,
                selectedArtist: null,
                breadcrumbLabel: '涓婚〉 / 宸茬偣',
              ),
              library: SongBookLibraryViewModel(
                searchQuery: '',
                selectedLanguage: '鍏ㄩ儴',
                songs: const <Song>[],
                artists: const <Artist>[],
                favoriteSongIds: const <String>[],
                downloadableSourceIds: const <String>{'baidu_pan'},
                downloadingSongIds: <String>{failedSong.songId},
                downloadingSongProgressByKey: const <String, double>{
                  'baidu_pan::fsid-failed': 0.6,
                },
                downloadTaskStatusByKey: const <String, DownloadTaskStatus>{
                  'baidu_pan::fsid-failed': DownloadTaskStatus.failed,
                },
                downloadedSongKeys: const <String>{},
                totalCount: 0,
                pageIndex: 0,
                totalPages: 1,
                pageSize: 12,
                hasConfiguredDirectory: true,
                hasConfiguredAggregatedSources: true,
                isScanning: false,
                isLoadingPage: false,
                scanErrorMessage: null,
              ),
              playback: SongBookPlaybackViewModel(
                queuedSongs: <Song>[failedSong],
              ),
            ),
            callbacks: buildSongBookCallbacks(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('浜戠姝屾墜 路 鍥借 路 涓嬭浇澶辫触'), findsOneWidget);
    expect(
      find.byKey(
        ValueKey<String>('song-download-progress-${failedSong.songId}'),
      ),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.vertical_align_top_rounded), findsNothing);
    expect(find.byIcon(Icons.delete_outline_rounded), findsOneWidget);
  });

  testWidgets(
    'queued paused download tile taps request callback in queue list',
    (WidgetTester tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(932, 430);
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final TextEditingController searchController = TextEditingController();
      addTearDown(searchController.dispose);

      final Song pausedSong = Song(
        songId: buildAggregateSongId(title: '鍙户缁笅杞芥瓕鏇?, artist: '浜戠姝屾墜'),
        sourceId: 'baidu_pan',
        sourceSongId: 'fsid-resume-tap',
        title: '鍙户缁笅杞芥瓕鏇?,
        artist: '浜戠姝屾墜',
        languages: const <String>['鍥借'],
        searchIndex: '鍙户缁笅杞芥瓕鏇?浜戠姝屾墜',
        mediaPath: '',
      );
      int requestCallCount = 0;
      Song? requestedSong;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SongBookPage(
              controller: _TestPlayerController(),
              searchController: searchController,
              viewModel: SongBookViewModel(
                navigation: const SongBookNavigationViewModel(
                  route: KtvRoute.queueList,
                  songBookMode: SongBookMode.songs,
                  libraryScope: LibraryScope.aggregated,
                  selectedArtist: null,
                  breadcrumbLabel: '涓婚〉 / 宸茬偣',
                ),
                library: SongBookLibraryViewModel(
                  searchQuery: '',
                  selectedLanguage: '鍏ㄩ儴',
                  songs: const <Song>[],
                  artists: const <Artist>[],
                  favoriteSongIds: const <String>[],
                  downloadableSourceIds: const <String>{'baidu_pan'},
                  downloadingSongIds: <String>{pausedSong.songId},
                  downloadingSongProgressByKey: const <String, double>{
                    'baidu_pan::fsid-resume-tap': 0.5,
                  },
                  downloadTaskStatusByKey: const <String, DownloadTaskStatus>{
                    'baidu_pan::fsid-resume-tap': DownloadTaskStatus.paused,
                  },
                  downloadedSongKeys: const <String>{},
                  totalCount: 0,
                  pageIndex: 0,
                  totalPages: 1,
                  pageSize: 12,
                  hasConfiguredDirectory: true,
                  hasConfiguredAggregatedSources: true,
                  isScanning: false,
                  isLoadingPage: false,
                  scanErrorMessage: null,
                ),
                playback: SongBookPlaybackViewModel(
                  queuedSongs: <Song>[pausedSong],
                ),
              ),
              callbacks: SongBookCallbacks(
                navigation: SongBookNavigationCallbacks(
                  onBackPressed: () {},
                  onQueuePressed: () {},
                  onSelectArtist: (_) {},
                  onSettingsPressed: () {},
                ),
                library: SongBookLibraryCallbacks(
                  onLanguageSelected: (_) {},
                  onAppendSearchToken: (_) {},
                  onRemoveSearchCharacter: () {},
                  onClearSearch: () {},
                  onRequestLibraryPage: (_, _) {},
                  onRequestSong: (Song song) {
                    requestCallCount += 1;
                    requestedSong = song;
                  },
                  onToggleFavorite: (_) {},
                  onDownloadSong: (_) {},
                ),
                playback: SongBookPlaybackCallbacks(
                  onPrioritizeQueuedSong: (_) {},
                  onRemoveQueuedSong: (_) {},
                  onToggleAudioMode: () {},
                  onTogglePlayback: () {},
                  onRestartPlayback: () {},
                  onSkipSong: () {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('鍙户缁笅杞芥瓕鏇?));
      await tester.pumpAndSettle();

      expect(requestCallCount, 1);
      expect(requestedSong, pausedSong);
    },
  );

  testWidgets('phone-height song grid uses bottom space to fit one more row', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 430,
            height: 430,
            child: SongBookRightColumn(
              controller: _TestPlayerController(),
              viewModel: SongBookViewModel(
                navigation: const SongBookNavigationViewModel(
                  route: KtvRoute.songBook,
                  songBookMode: SongBookMode.songs,
                  libraryScope: LibraryScope.aggregated,
                  selectedArtist: null,
                  breadcrumbLabel: '涓婚〉 / 姝屽悕',
                ),
                library: SongBookLibraryViewModel(
                  searchQuery: '',
                  selectedLanguage: '鍏ㄩ儴',
                  songs: List<Song>.generate(
                    11,
                    (int index) => Song(
                      songId: buildAggregateSongId(
                        title: '姝屾洸$index',
                        artist: '姝屾墜$index',
                      ),
                      sourceId: 'local',
                      sourceSongId: buildLocalSourceSongId(
                        fingerprint: buildLocalMetadataFingerprint(
                          locator: '/tmp/phone_song_$index.mp4',
                        ),
                      ),
                      title: '姝屾洸$index',
                      artist: '姝屾墜$index',
                      languages: const <String>['鍥借'],
                      searchIndex: 'gequ$index geshou$index',
                      mediaPath: '/tmp/phone_song_$index.mp4',
                    ),
                  ),
                  artists: const <Artist>[],
                  favoriteSongIds: const <String>[],
                  downloadableSourceIds: const <String>{},
                  downloadingSongIds: <String>{},
                  downloadedSongKeys: const <String>{},
                  totalCount: 11,
                  pageIndex: 0,
                  totalPages: 2,
                  pageSize: 11,
                  hasConfiguredDirectory: true,
                  hasConfiguredAggregatedSources: true,
                  isScanning: false,
                  isLoadingPage: false,
                  scanErrorMessage: null,
                ),
                playback: const SongBookPlaybackViewModel(
                  queuedSongs: <Song>[],
                ),
              ),
              callbacks: buildSongBookCallbacks(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('1/1'), findsOneWidget);
  });

  testWidgets('opens fullscreen preview and toggles overlay controls on tap', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const KtvApp());
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey<String>('preview-tap-target')));
    await tester.pumpAndSettle();

    expect(find.text('杩斿洖鐐规瓕'), findsNothing);

    final Finder fullscreenScaffold = find.byType(Scaffold).last;
    await tester.tapAt(tester.getCenter(fullscreenScaffold));
    await tester.pumpAndSettle();

    expect(find.text('杩斿洖鐐规瓕'), findsOneWidget);
    expect(find.text('浼村敱'), findsAtLeastNWidgets(1));
    expect(find.text('鎾斁'), findsAtLeastNWidgets(1));
    expect(find.text('閲嶅敱'), findsAtLeastNWidgets(1));
    expect(find.text('鍒囨瓕'), findsAtLeastNWidgets(1));

    await tester.tapAt(tester.getCenter(fullscreenScaffold));
    await tester.pumpAndSettle();

    expect(find.text('杩斿洖鐐规瓕'), findsNothing);
  });

  testWidgets('tapping non-fullscreen progress bar does not enter fullscreen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const KtvApp());
    await tester.pump();

    final Finder slider = find.byType(Slider).first;
    final Rect sliderRect = tester.getRect(slider);

    await tester.tapAt(Offset(sliderRect.center.dx, sliderRect.bottom - 8));
    await tester.pumpAndSettle();

    expect(find.text('杩斿洖鐐规瓕'), findsNothing);
    expect(
      find.byKey(const ValueKey<String>('preview-tap-target')),
      findsOneWidget,
    );
  });

  testWidgets(
    'dragging non-fullscreen preview seeks without entering fullscreen',
    (WidgetTester tester) async {
      final _TestPlayerController controller = _TestPlayerController();
      int enterFullscreenCount = 0;
      controller.setProgress(
        position: const Duration(seconds: 30),
        duration: const Duration(minutes: 2),
        mediaPath: '/tmp/sample.mp4',
      );

      await tester.pumpWidget(
        _PreviewViewportTestApp(
          controller: controller,
          isFullscreen: false,
          onEnterFullscreen: () {
            enterFullscreenCount += 1;
          },
        ),
      );

      await tester.drag(
        find.byKey(const ValueKey<String>('preview-tap-target')),
        const Offset(60, 0),
      );
      await tester.pumpAndSettle();

      expect(enterFullscreenCount, 0);
      expect(controller.lastSeekProgress, isNotNull);
      expect(controller.lastSeekProgress!, greaterThan(0.25));
      expect(controller.lastSeekProgress!, lessThan(1.0));
    },
  );

  testWidgets('dragging fullscreen preview seeks and reveals controls', (
    WidgetTester tester,
  ) async {
    final _TestPlayerController controller = _TestPlayerController();
    controller.setProgress(
      position: const Duration(seconds: 30),
      duration: const Duration(minutes: 2),
      mediaPath: '/tmp/sample.mp4',
    );

    await tester.pumpWidget(
      _PreviewViewportTestApp(controller: controller, isFullscreen: true),
    );

    expect(find.text('杩斿洖鐐规瓕'), findsNothing);

    await tester.drag(
      find.byKey(const ValueKey<String>('fullscreen-preview-gesture-target')),
      const Offset(60, 0),
    );
    await tester.pumpAndSettle();

    expect(controller.lastSeekProgress, isNotNull);
    expect(controller.lastSeekProgress!, greaterThan(0.25));
    expect(controller.lastSeekProgress!, lessThan(1.0));
    expect(find.text('杩斿洖鐐规瓕'), findsOneWidget);
  });

  testWidgets(
    'player progress track rebuilds when controller progress changes',
    (WidgetTester tester) async {
      final _TestPlayerController controller = _TestPlayerController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 240,
              child: PlayerProgressTrack(
                controller: controller,
                thickness: 6,
                barHeight: 28,
              ),
            ),
          ),
        ),
      );

      Slider slider = tester.widget<Slider>(find.byType(Slider));
      expect(slider.value, 0);

      controller.setProgress(
        position: const Duration(seconds: 30),
        duration: const Duration(minutes: 2),
        mediaPath: '/tmp/sample.mp4',
      );
      await tester.pump();

      slider = tester.widget<Slider>(find.byType(Slider));
      expect(slider.value, closeTo(0.25, 0.001));
    },
  );

  testWidgets('player progress track defers seek until drag ends', (
    WidgetTester tester,
  ) async {
    final _TestPlayerController controller = _TestPlayerController();
    controller.setProgress(
      position: Duration.zero,
      duration: const Duration(minutes: 2),
      mediaPath: '/tmp/sample.mp4',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 240,
            child: PlayerProgressTrack(
              controller: controller,
              thickness: 6,
              barHeight: 28,
            ),
          ),
        ),
      ),
    );

    final Slider slider = tester.widget<Slider>(find.byType(Slider));
    expect(slider.onChanged, isNotNull);
    expect(slider.onChangeEnd, isNotNull);

    slider.onChanged!(0.5);
    await tester.pump();

    expect(controller.lastSeekProgress, isNull);

    slider.onChangeEnd!(0.5);
    await tester.pump();

    expect(controller.lastSeekProgress, 0.5);
  });

  testWidgets('player progress bar previews dragged position before seek', (
    WidgetTester tester,
  ) async {
    final _TestPlayerController controller = _TestPlayerController();
    controller.setProgress(
      position: const Duration(seconds: 10),
      duration: const Duration(minutes: 2),
      mediaPath: '/tmp/sample.mp4',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: PlayerProgressBar(controller: controller)),
      ),
    );

    expect(find.text('00:10'), findsOneWidget);

    final Slider slider = tester.widget<Slider>(find.byType(Slider));
    slider.onChangeStart?.call(0.75);
    slider.onChanged!(0.75);
    await tester.pump();

    expect(find.text('01:30'), findsOneWidget);
    expect(controller.lastSeekProgress, isNull);

    slider.onChangeEnd!(0.75);
    await tester.pump();

    expect(controller.lastSeekProgress, 0.75);
  });
}

class _TestPlayerController extends PlayerController {
  PlayerState _state = const PlayerState();
  double? lastSeekProgress;

  @override
  PlayerState get state => _state;

  void setProgress({
    required Duration position,
    required Duration duration,
    required String mediaPath,
  }) {
    _state = PlayerState(
      currentMediaPath: mediaPath,
      playbackPosition: position,
      playbackDuration: duration,
    );
    notifyListeners();
  }

  @override
  Future<void> applyAudioOutputMode(AudioOutputMode mode) async {}

  @override
  Widget? buildVideoView() => null;

  @override
  Future<void> openMedia(MediaSource source) async {}

  @override
  Future<void> seekToProgress(double progress) async {
    lastSeekProgress = progress;
  }

  @override
  Future<void> togglePlayback() async {}
}

class _PreviewViewportTestApp extends StatelessWidget {
  const _PreviewViewportTestApp({
    required this.controller,
    required this.isFullscreen,
    this.onEnterFullscreen,
  });

  final PlayerController controller;
  final bool isFullscreen;
  final VoidCallback? onEnterFullscreen;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Stack(
          children: <Widget>[
            PreviewViewportHost(
              controller: controller,
              previewSurface: const ColoredBox(color: Colors.black),
              rect: const Rect.fromLTWH(0, 0, 300, 200),
              isFullscreen: isFullscreen,
              onEnterFullscreen: onEnterFullscreen ?? () {},
              onBackToSongBook: () {},
              onToggleAudioMode: () {},
              onTogglePlayback: () {},
              onRestartPlayback: () {},
              onSkipSong: () {},
            ),
          ],
        ),
      ),
    );
  }
}

