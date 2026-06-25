import 'package:flutter_test/flutter_test.dart';
import 'package:saefra_run/core/constants/app_colors.dart';

void main() {
  test('AppColors primary matches design', () {
    expect(AppColors.primary.value, 0xFFEF4444);
  });
}
