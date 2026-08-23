import 'package:flutter_test/flutter_test.dart';
import 'package:plan_e/features/plans/plans_screen.dart';

void main() {
  test('plans query tabs map to the consolidated status order', () {
    expect(planStatuses, ['confirmed', 'pending', 'completed', 'cancelled']);
    expect(planTabFromQuery(null), 0);
    expect(planTabFromQuery('drafts'), 1);
    expect(planTabFromQuery('past'), 2);
    expect(planTabFromQuery('cancelled'), 3);
    expect(planTabFromQuery('unknown'), 0);
  });
}
