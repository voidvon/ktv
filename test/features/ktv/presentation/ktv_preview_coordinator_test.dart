import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ktv2/ktv2.dart';
import 'package:maimai_ktv/features/ktv/application/ktv_controller.dart';
import 'package:maimai_ktv/features/ktv/application/preview_fullscreen_delegate.dart';
import 'package:maimai_ktv/features/ktv/presentation/ktv_preview_coordinator.dart';

void main() {
  testWidgets('preview coordinator exposes preview surface and inert sync', (
    WidgetTester tester,
  ) async {
    final KtvPreviewCoordinator coordinator = KtvPreviewCoordinator(
      controller: _TestPlayerController(),
      routeResolver: () => KtvRoute.home,
    );
    addTearDown(() async {
      await coordinator.disposeCoordinator();
      coordinator.dispose();
    });

    expect(coordinator.isPreviewFullscreen, isFalse);
    expect(coordinator.previewViewportRect, isNull);
    expect(coordinator.sharedPreviewSurface, isA<Widget>());

    coordinator.schedulePreviewViewportSync();
    await tester.pump();
    expect(coordinator.isPreviewFullscreen, isFalse);
    expect(coordinator.previewViewportRect, isNull);
  });

  testWidgets('preview coordinator delegates fullscreen platform changes', (
    WidgetTester tester,
  ) async {
    final FakePreviewFullscreenDelegate fullscreenDelegate =
        FakePreviewFullscreenDelegate();
    final KtvPreviewCoordinator coordinator = KtvPreviewCoordinator(
      controller: _TestPlayerController(),
      routeResolver: () => KtvRoute.home,
      fullscreenDelegate: fullscreenDelegate,
    );
    addTearDown(() async {
      await coordinator.disposeCoordinator();
      coordinator.dispose();
    });

    await coordinator.enterPreviewFullscreen();
    await tester.pump();
    await coordinator.exitPreviewFullscreen();

    expect(fullscreenDelegate.values, <bool>[true, false]);
  });
}

class _TestPlayerController extends PlayerController {
  @override
  PlayerState get state => const PlayerState();

  @override
  Widget? buildVideoView() => const SizedBox.shrink();

  @override
  Future<void> openMedia(MediaSource source) async {}

  @override
  Future<void> seekToProgress(double progress) async {}

  @override
  Future<void> togglePlayback() async {}

  @override
  Future<void> applyAudioOutputMode(AudioOutputMode mode) async {}
}

class FakePreviewFullscreenDelegate extends PreviewFullscreenDelegate {
  final List<bool> values = <bool>[];

  @override
  Future<void> setVideoFullscreen({required bool enabled}) async {
    values.add(enabled);
  }
}

