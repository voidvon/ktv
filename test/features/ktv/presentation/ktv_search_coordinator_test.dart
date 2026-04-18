import 'package:flutter_test/flutter_test.dart';
import 'package:maimai_ktv/features/ktv/presentation/ktv_search_coordinator.dart';

void main() {
  test('append and remove operations notify query changes', () {
    final List<String> queries = <String>[];
    final KtvSearchCoordinator coordinator = KtvSearchCoordinator(
      onQueryChanged: queries.add,
    );
    addTearDown(coordinator.dispose);

    coordinator.appendToken('周');
    coordinator.appendToken('杰');
    coordinator.removeLastCharacter();
    coordinator.clear();

    expect(queries, <String>['周', '周杰', '周', '']);
  });

  test('syncFromQuery updates the text field without echoing callbacks', () {
    final List<String> queries = <String>[];
    final KtvSearchCoordinator coordinator = KtvSearchCoordinator(
      onQueryChanged: queries.add,
    );
    addTearDown(coordinator.dispose);

    coordinator.syncFromQuery('abc');

    expect(coordinator.controller.text, 'abc');
    expect(queries, isEmpty);
  });
}
