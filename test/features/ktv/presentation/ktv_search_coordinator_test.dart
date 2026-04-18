import 'package:flutter_test/flutter_test.dart';
import 'package:maimai_ktv/features/ktv/presentation/ktv_search_coordinator.dart';

void main() {
  testWidgets('syncFromQuery updates text without re-emitting query changes', (
    WidgetTester tester,
  ) async {
    final List<String> emittedQueries = <String>[];
    final KtvSearchCoordinator coordinator = KtvSearchCoordinator(
      onQueryChanged: emittedQueries.add,
    );
    addTearDown(coordinator.dispose);

    coordinator.syncFromQuery('鍛ㄦ澃浼?);

    expect(coordinator.controller.text, '鍛ㄦ澃浼?);
    expect(emittedQueries, isEmpty);
  });

  testWidgets('append remove and clear forward query changes', (
    WidgetTester tester,
  ) async {
    final List<String> emittedQueries = <String>[];
    final KtvSearchCoordinator coordinator = KtvSearchCoordinator(
      onQueryChanged: emittedQueries.add,
    );
    addTearDown(coordinator.dispose);

    coordinator.appendToken('A');
    coordinator.appendToken('B');
    coordinator.removeLastCharacter();
    coordinator.clear();

    expect(emittedQueries, <String>['A', 'AB', 'A', '']);
    expect(coordinator.controller.text, isEmpty);
  });
}

