import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maimai_ktv/features/ktv/application/ktv_controller.dart';
import 'package:maimai_ktv/features/ktv/presentation/home_page.dart';
import 'package:maimai_ktv/features/ktv/presentation/ktv_shell.dart';
import 'package:maimai_ktv/features/ktv/presentation/songbook_page.dart';

import 'test_support/ktv_test_doubles.dart';

void main() {
  KtvController buildController() {
    return KtvController(
      mediaLibraryRepository: createTestMediaLibraryRepository(
        hasConfiguredAggregatedSources: true,
      ),
      aggregatedLibraryRepository: FakeAggregatedLibraryRepository(),
      playerController: FakePlayerController(),
      downloadTaskStore: MemoryDownloadTaskStore(),
      playbackSessionStore: MemoryPlaybackSessionStore(),
    );
  }

  testWidgets('renders the home shell with the main shortcuts', (
    WidgetTester tester,
  ) async {
    final KtvController controller = buildController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(home: KtvShell(controller: controller)),
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('麦麦KTV'), findsOneWidget);
    expect(find.text('歌名'), findsOneWidget);
    expect(find.text('歌星'), findsOneWidget);
    expect(find.text('设置'), findsWidgets);
  });

  testWidgets('opens the aggregated song book view from the home shell', (
    WidgetTester tester,
  ) async {
    final KtvController controller = buildController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(home: KtvShell(controller: controller)),
    );
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.text('歌名'));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('主页 / 歌名'), findsOneWidget);
    expect(find.byType(Scrollable), findsWidgets);
  });

  testWidgets(
    'uses the full portrait width for home shortcuts on larger screens',
    (WidgetTester tester) async {
      final KtvController controller = buildController();
      addTearDown(controller.dispose);

      tester.view.physicalSize = const Size(800, 1280);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(home: KtvShell(controller: controller)),
      );
      await tester.pump(const Duration(milliseconds: 300));

      final Finder songCard = find.ancestor(
        of: find.text('歌名'),
        matching: find.byType(Ink),
      );

      expect(songCard, findsOneWidget);
      expect(tester.getSize(songCard).width, greaterThan(200));
    },
  );

  testWidgets(
    'keeps the landscape song book panels balanced on larger screens',
    (WidgetTester tester) async {
      final KtvController controller = buildController();
      addTearDown(controller.dispose);

      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(home: KtvShell(controller: controller)),
      );
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text('歌名'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('主页 / 歌名'), findsOneWidget);

      final Size leftPanelSize = tester.getSize(
        find.byType(SongBookLeftColumn),
      );
      final Size rightPanelSize = tester.getSize(
        find.byType(SongBookRightColumn),
      );

      expect(leftPanelSize.width, greaterThan(320));
      expect(rightPanelSize.width, lessThanOrEqualTo(760));
    },
  );

  testWidgets(
    'centers the landscape song book preview and search controls vertically',
    (WidgetTester tester) async {
      final KtvController controller = buildController();
      addTearDown(controller.dispose);

      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(home: KtvShell(controller: controller)),
      );
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text('歌名'));
      await tester.pump(const Duration(milliseconds: 300));

      final Rect previewRect = tester.getRect(find.byType(HomePreviewCard));
      final Rect leftColumnRect = tester.getRect(
        find.byType(SongBookLeftColumn),
      );
      final Rect rightPanelRect = tester.getRect(
        find.byType(SongBookRightColumn),
      );
      final double leftGroupCenterY =
          (previewRect.top + leftColumnRect.bottom) / 2;

      expect(
        leftGroupCenterY,
        moreOrLessEquals(rightPanelRect.center.dy, epsilon: 8),
      );
    },
  );
}
