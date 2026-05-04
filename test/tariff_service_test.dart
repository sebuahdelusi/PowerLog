import 'package:flutter_test/flutter_test.dart';
import 'package:powerlog/services/tariff_service.dart';

void main() {
  test('computeCost applies tax and fixed fee', () {
    const cfg = TariffConfig(
      planCode: 'TEST',
      ratePerKwh: 1500.0,
      fixedFee: 20000.0,
      taxPercent: 10.0,
      includeTax: true,
      includeFixedFee: true,
    );

    final cost = TariffService.computeCost(cfg, 10.0, forMonthly: true);
    expect(cost, closeTo(36500.0, 0.001));
  });

  test('computeCost ignores tax and fee when disabled', () {
    const cfg = TariffConfig(
      planCode: 'TEST',
      ratePerKwh: 1000.0,
      fixedFee: 5000.0,
      taxPercent: 10.0,
      includeTax: false,
      includeFixedFee: false,
    );

    final cost = TariffService.computeCost(cfg, 5.0, forMonthly: true);
    expect(cost, closeTo(5000.0, 0.001));
  });
}
