import 'package:flutter_test/flutter_test.dart';
import 'package:powerlog/modules/profile/controllers/profile_controller.dart';

void main() {
  test('computeStreakDays counts consecutive days', () {
    final dates = ['2026-05-05', '2026-05-04', '2026-05-03'];
    expect(ProfileController.computeStreakDays(dates), 3);
  });

  test('computeStreakDays stops on gaps', () {
    final dates = ['2026-05-05', '2026-05-03', '2026-05-02'];
    expect(ProfileController.computeStreakDays(dates), 1);
  });

  test('computeStreakDays ignores same-day duplicates', () {
    final dates = ['2026-05-05', '2026-05-05', '2026-05-04'];
    expect(ProfileController.computeStreakDays(dates), 2);
  });
}
