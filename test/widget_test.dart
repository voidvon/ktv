import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maimai_ktv/features/ktv/application/ktv_controller.dart';
import 'package:maimai_ktv/features/ktv/presentation/ktv_shell.dart';

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
}
