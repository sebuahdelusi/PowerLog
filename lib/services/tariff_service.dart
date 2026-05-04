import 'package:get/get.dart';
import 'session_service.dart';

class TariffPlan {
  final String code;
  final String label;
  final double defaultRate;

  const TariffPlan(this.code, this.label, this.defaultRate);
}

class TariffConfig {
  final String planCode;
  final double ratePerKwh;
  final double fixedFee;
  final double taxPercent;
  final bool includeTax;
  final bool includeFixedFee;

  const TariffConfig({
    required this.planCode,
    required this.ratePerKwh,
    required this.fixedFee,
    required this.taxPercent,
    required this.includeTax,
    required this.includeFixedFee,
  });

  TariffConfig copyWith({
    String? planCode,
    double? ratePerKwh,
    double? fixedFee,
    double? taxPercent,
    bool? includeTax,
    bool? includeFixedFee,
  }) {
    return TariffConfig(
      planCode: planCode ?? this.planCode,
      ratePerKwh: ratePerKwh ?? this.ratePerKwh,
      fixedFee: fixedFee ?? this.fixedFee,
      taxPercent: taxPercent ?? this.taxPercent,
      includeTax: includeTax ?? this.includeTax,
      includeFixedFee: includeFixedFee ?? this.includeFixedFee,
    );
  }
}

class TariffService extends GetxService {
  static const List<TariffPlan> plans = [
    TariffPlan('R1_900', 'R-1 900VA', 1352.0),
    TariffPlan('R1_1300', 'R-1 1300VA', 1444.7),
    TariffPlan('R1_2200', 'R-1 2200VA', 1444.7),
    TariffPlan('R2_3500', 'R-2 3500-5500VA', 1699.53),
    TariffPlan('R3_6600', 'R-3 >6600VA', 1699.53),
    TariffPlan('B1', 'B-1 450-5500VA', 1444.7),
    TariffPlan('I1', 'I-1 450-14kVA', 1444.7),
    TariffPlan('CUSTOM', 'Custom', 1500.0),
  ];

  final _session = SessionService();
  final config = const TariffConfig(
    planCode: 'R1_1300',
    ratePerKwh: 1444.7,
    fixedFee: 0.0,
    taxPercent: 10.0,
    includeTax: true,
    includeFixedFee: false,
  ).obs;

  Future<TariffService> init() async {
    final planCode = await _session.getTariffPlanCode();
    final plan = getPlan(planCode) ?? plans[1];

    final storedRate = await _session.getTariffRate();
    final ratePerKwh = storedRate > 0 ? storedRate : plan.defaultRate;

    final fixedFee = await _session.getTariffFixedFee();
    final taxPercent = await _session.getTariffTaxPercent();
    final includeTax = await _session.getTariffIncludeTax();
    final includeFixedFee = await _session.getTariffIncludeFixedFee();

    config.value = TariffConfig(
      planCode: plan.code,
      ratePerKwh: ratePerKwh,
      fixedFee: fixedFee,
      taxPercent: taxPercent,
      includeTax: includeTax,
      includeFixedFee: includeFixedFee,
    );

    return this;
  }

  TariffPlan? getPlan(String code) {
    for (final plan in plans) {
      if (plan.code == code) return plan;
    }
    return null;
  }

  Future<void> updateConfig(TariffConfig next) async {
    config.value = next;
    await _session.setTariffPlanCode(next.planCode);
    await _session.setTariffRate(next.ratePerKwh);
    await _session.setTariffFixedFee(next.fixedFee);
    await _session.setTariffTaxPercent(next.taxPercent);
    await _session.setTariffIncludeTax(next.includeTax);
    await _session.setTariffIncludeFixedFee(next.includeFixedFee);
  }

  double calculateCost(double kwh, {bool forMonthly = false}) {
    return computeCost(config.value, kwh, forMonthly: forMonthly);
  }

  static double computeCost(
    TariffConfig cfg,
    double kwh, {
    bool forMonthly = false,
  }) {
    var total = kwh * cfg.ratePerKwh;
    if (cfg.includeTax) {
      total += total * (cfg.taxPercent / 100.0);
    }
    if (forMonthly && cfg.includeFixedFee) {
      total += cfg.fixedFee;
    }
    return total;
  }
}
