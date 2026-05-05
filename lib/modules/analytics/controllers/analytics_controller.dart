import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:powerlog/data/models/appliance_model.dart';
import 'package:powerlog/data/models/token_model.dart';
import 'package:powerlog/data/repositories/appliance_repository.dart';
import 'package:powerlog/data/repositories/token_repository.dart';
import 'package:powerlog/services/tariff_service.dart';

class AnalyticsController extends GetxController {
  final _applianceRepo = ApplianceRepository();
  final _tokenRepo = TokenRepository();
  final _tariff = Get.find<TariffService>();

  final appliances = <ApplianceModel>[].obs;
  final isLoading = false.obs;
  final latestToken = Rxn<TokenModel>();

  static const Map<String, int> _planVaMin = {
    'R1_900': 900,
    'R1_1300': 1300,
    'R1_2200': 2200,
    'R2_3500': 3500,
    'R3_6600': 6600,
    'B1': 450,
    'I1': 450,
    'CUSTOM': 0,
  };

  static const Map<String, String> _planVaLabel = {
    'R1_900': '900 VA',
    'R1_1300': '1300 VA',
    'R1_2200': '2200 VA',
    'R2_3500': '3500-5500 VA',
    'R3_6600': '> 6600 VA',
    'B1': '450-5500 VA',
    'I1': '450-14000 VA',
    'CUSTOM': 'Custom',
  };

  @override
  void onInit() {
    super.onInit();
    loadData();
  }

  Future<void> loadData() async {
    isLoading.value = true;
    appliances.value = await _applianceRepo.fetchAllAppliances();
    latestToken.value = await _tokenRepo.fetchLatestToken();
    isLoading.value = false;
  }

  TariffConfig get tariffConfig => _tariff.config.value;

  String get planCode =>
      latestToken.value?.planCode ?? tariffConfig.planCode;

  TariffPlan? get tariffPlan => _tariff.getPlan(planCode);

  String get tariffPlanLabel => tariffPlan?.label ?? planCode;

  double get totalDailyKwh {
    return appliances.fold(0.0, (sum, item) => sum + item.dailyKwh);
  }

  double get totalWatt {
    return appliances.fold(0.0, (sum, item) => sum + item.wattage);
  }

  int get meterVaValue => _planVaMin[planCode] ?? 0;

  String get meterCapacityLabel => _planVaLabel[planCode] ?? '-';

  String get capacityCheckNote {
    final code = planCode;
    if (code == 'CUSTOM') {
      return 'Capacity check disabled for Custom plan.';
    }
    const ranged = {'R2_3500', 'R3_6600', 'B1', 'I1'};
    if (ranged.contains(code)) {
      return 'Capacity check uses the minimum of the plan range.';
    }
    return '';
  }

  double get tokenIdr => latestToken.value?.amountIdr ?? 0.0;

  String get tokenDateLabel {
    final token = latestToken.value;
    if (token == null) return '-';
    return _formatDate(token.date);
  }

  String get estimatedEndDateLabel {
    final end = estimatedEndDateTime;
    if (end == null) return '-';
    return DateFormat('EEE, d MMM yyyy').format(end);
  }

  DateTime? get estimatedEndDateTime {
    if (latestToken.value == null) return null;
    if (estimatedDays <= 0) return null;
    final start = _parseDate(latestToken.value!.date);
    final minutes = (estimatedDays * 24 * 60).round();
    return start.add(Duration(minutes: minutes));
  }

  double get effectiveRatePerKwh {
    final token = latestToken.value;
    var rate = token?.ratePerKwh ?? tariffConfig.ratePerKwh;
    final includeTax = token?.includeTax ?? tariffConfig.includeTax;
    final taxPercent = token?.taxPercent ?? tariffConfig.taxPercent;
    if (includeTax) {
      rate *= (1 + taxPercent / 100.0);
    }
    return rate;
  }

  double get tokenKwh {
    var available = tokenIdr;
    final token = latestToken.value;
    final includeFee = token?.includeFixedFee ?? tariffConfig.includeFixedFee;
    final fixedFee = token?.fixedFee ?? tariffConfig.fixedFee;
    if (includeFee && fixedFee > 0) {
      available -= fixedFee;
    }
    if (available <= 0 || effectiveRatePerKwh <= 0) return 0;
    return available / effectiveRatePerKwh;
  }

  double get estimatedDays {
    if (totalDailyKwh <= 0 || tokenKwh <= 0) return 0;
    return tokenKwh / totalDailyKwh;
  }

  String get estimatedDurationLabel {
    return _formatDuration(estimatedDays);
  }

  bool get isOverCapacity {
    return meterVaValue > 0 && totalWatt > meterVaValue;
  }

  List<ApplianceModel> get sortedAppliances {
    final list = appliances.toList();
    list.sort((a, b) => b.dailyKwh.compareTo(a.dailyKwh));
    return list;
  }

  DateTime _parseDate(String value) {
    try {
      return DateTime.parse(value);
    } catch (_) {
      return DateTime.now();
    }
  }

  String _formatDate(String value) {
    try {
      return DateFormat('EEE, d MMM yyyy').format(DateTime.parse(value));
    } catch (_) {
      return value;
    }
  }

  String _formatDuration(double days) {
    if (days <= 0) return '';
    final totalMinutes = (days * 24 * 60).round();
    if (totalMinutes <= 0) return '';
    final dayCount = totalMinutes ~/ (24 * 60);
    final hourCount = (totalMinutes % (24 * 60)) ~/ 60;
    final minuteCount = totalMinutes % 60;

    if (dayCount > 0) {
      return hourCount > 0 ? '${dayCount}d ${hourCount}h' : '${dayCount}d';
    }
    if (hourCount > 0) {
      return minuteCount > 0 ? '${hourCount}h ${minuteCount}m' : '${hourCount}h';
    }
    return '${minuteCount}m';
  }
}
