import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:powerlog/data/models/appliance_model.dart';
import 'package:powerlog/data/models/token_model.dart';
import 'package:powerlog/data/repositories/appliance_repository.dart';
import 'package:powerlog/data/repositories/token_repository.dart';
import 'package:powerlog/modules/dashboard/controllers/dashboard_controller.dart';
import 'package:powerlog/modules/analytics/controllers/analytics_controller.dart';
import 'package:powerlog/services/notification_service.dart'
  as powerlog_notification;
import 'package:powerlog/services/sensor_service.dart';
import 'package:powerlog/services/session_service.dart';
import 'package:powerlog/services/tariff_service.dart';

class HomeController extends GetxController {
  final _sensors = SensorService();
  final _applianceRepo = ApplianceRepository();
  final _tokenRepo = TokenRepository();
  final _tariff = Get.find<TariffService>();
  final _session = SessionService();

  // ── State ────────────────────────────────────────────────────────────────
  final appliances = <ApplianceModel>[].obs;
  final isAppliancesLoading = false.obs;
  final tokenInput = ''.obs;
  final tariffPlanCode = ''.obs;
  final tokenDate = DateTime.now().obs;
  final isConfirming = false.obs;

  // ── Gyroscope ─────────────────────────────────────────────────────────────
  final gyroX = 0.0.obs; // angular velocity x-axis
  final gyroY = 0.0.obs; // angular velocity y-axis

  // ── Torch indicator ───────────────────────────────────────────────────────
  final isTorchOn = false.obs;

  // ── Form ──────────────────────────────────────────────────────────────────
  final tokenCtrl = TextEditingController();

  // ── Subscriptions ─────────────────────────────────────────────────────────
  StreamSubscription<void>? _shakeSub;
  StreamSubscription<GyroscopeEvent>? _gyroSub;
  bool _sensorsReady = false;

  @override
  void onInit() {
    super.onInit();
    tokenCtrl.addListener(() {
      tokenInput.value = tokenCtrl.text;
      _session.setTokenAmount(_parseInt(tokenCtrl.text));
    });
    resumeSensors();
    loadAppliances();
    _loadLatestToken();
    _loadTariffPlan();
  }

  @override
  void onClose() {
    tokenCtrl.dispose();
    pauseSensors();
    _sensors.dispose();
    super.onClose();
  }

  // ── Sensor init ───────────────────────────────────────────────────────────

  Future<void> resumeSensors() async {
    if (!_sensorsReady) {
      await _sensors.init();
      _sensorsReady = true;
    }

    _sensors.resume();

    _shakeSub ??= _sensors.onShake.listen((_) {
      isTorchOn.value = _sensors.isTorchOn;
      Get.snackbar(
        isTorchOn.value ? '🔦 Torch ON' : '🔦 Torch OFF',
        'Shake detected!',
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 1),
        margin: const EdgeInsets.all(12),
      );
    });

    _gyroSub ??= _sensors.gyroscopeStream.listen((event) {
      gyroX.value = event.x.clamp(-5.0, 5.0);
      gyroY.value = event.y.clamp(-5.0, 5.0);
    });
  }

  void pauseSensors() {
    _shakeSub?.cancel();
    _shakeSub = null;
    _gyroSub?.cancel();
    _gyroSub = null;
    _sensors.pause();
  }

  // ── Data ─────────────────────────────────────────────────────────────────

  Future<void> loadAppliances() async {
    isAppliancesLoading.value = true;
    appliances.value = await _applianceRepo.fetchAllAppliances();
    isAppliancesLoading.value = false;
  }

  Future<void> refreshEstimator() async {
    await loadAppliances();
    await _loadLatestToken();
  }

  Future<void> _loadTokenAmount() async {
    final amount = await _session.getTokenAmount();
    if (amount > 0 && tokenCtrl.text.trim().isEmpty) {
      tokenCtrl.text = amount.toString();
      tokenInput.value = tokenCtrl.text;
    }
  }

  Future<void> _loadLatestToken() async {
    final latest = await _tokenRepo.fetchLatestToken();
    if (latest != null) {
      tokenDate.value = _parseDate(latest.date);
      if (tokenCtrl.text.trim().isEmpty) {
        tokenCtrl.text = latest.amountIdr.toStringAsFixed(0);
        tokenInput.value = tokenCtrl.text;
      }
    } else {
      await _loadTokenAmount();
    }
  }

  // ── Token estimation ─────────────────────────────────────────────────────

  List<TariffPlan> get tariffPlans => TariffService.plans;

  TariffConfig get tariffConfig => _tariff.config.value;

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

  Future<void> setTariffPlan(String code) async {
    tariffPlanCode.value = code;
    final plan = _tariff.getPlan(code);
    var nextRate = tariffConfig.ratePerKwh;
    if (plan != null && plan.code != 'CUSTOM') {
      nextRate = plan.defaultRate;
    }
    await _tariff.updateConfig(
      tariffConfig.copyWith(planCode: code, ratePerKwh: nextRate),
    );
  }

  double get totalDailyKwh {
    return appliances.fold(0.0, (sum, item) => sum + item.dailyKwh);
  }

  double get totalWatt {
    return appliances.fold(0.0, (sum, item) => sum + item.wattage);
  }

  int get meterVaValue => _planVaMin[tariffPlanCode.value] ?? 0;

  String get meterCapacityLabel =>
      _planVaLabel[tariffPlanCode.value] ?? '-';

  String get capacityCheckNote {
    final code = tariffPlanCode.value;
    if (code == 'CUSTOM') {
      return 'Capacity check disabled for Custom plan.';
    }
    const ranged = {'R2_3500', 'R3_6600', 'B1', 'I1'};
    if (ranged.contains(code)) {
      return 'Capacity check uses the minimum of the plan range.';
    }
    return '';
  }

  double get tokenIdr => _parseInt(tokenInput.value).toDouble();

  double get effectiveRatePerKwh {
    var rate = tariffConfig.ratePerKwh;
    if (tariffConfig.includeTax) {
      rate *= (1 + tariffConfig.taxPercent / 100.0);
    }
    return rate;
  }

  double get tokenKwh {
    var available = tokenIdr;
    if (tariffConfig.includeFixedFee && tariffConfig.fixedFee > 0) {
      available -= tariffConfig.fixedFee;
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

  Future<void> confirmToken() async {
    if (isConfirming.value) return;
    final amount = tokenIdr;
    if (amount <= 0) {
      Get.snackbar(
        'Missing Token Amount',
        'Please enter your token amount in IDR.',
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
      );
      return;
    }

    isConfirming.value = true;
    try {
      final cfg = tariffConfig;
      final token = TokenModel(
        date: tokenDateIso,
        amountIdr: amount,
        planCode: cfg.planCode,
        ratePerKwh: cfg.ratePerKwh,
        taxPercent: cfg.taxPercent,
        includeTax: cfg.includeTax,
        fixedFee: cfg.fixedFee,
        includeFixedFee: cfg.includeFixedFee,
      );

      await _tokenRepo.addOrUpdateToken(token);
      await _syncAutoReminder();

      if (Get.isRegistered<AnalyticsController>()) {
        await Get.find<AnalyticsController>().loadData();
      }

      Get.snackbar(
        'Token Saved',
        'Token data saved successfully.',
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      Get.snackbar(
        'Save Failed',
        'Failed to save token: $e',
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
      );
    } finally {
      isConfirming.value = false;
    }
  }

  Future<void> _syncAutoReminder() async {
    if (estimatedDays <= 0) return;

    final now = DateTime.now();
    final start = DateTime(
      tokenDate.value.year,
      tokenDate.value.month,
      tokenDate.value.day,
      now.hour,
      now.minute,
    );
    final totalMinutes = (estimatedDays * 24 * 60).round();
    final end = start.add(Duration(minutes: totalMinutes));

    await _session.setReminderTime(end.hour, end.minute);

    final enabled = await _session.isNotificationEnabled();
    if (!enabled) return;

    try {
      final notif = Get.find<powerlog_notification.NotificationService>();
      await notif.scheduleDailyReminder(
        enable: true,
        hour: end.hour,
        minute: end.minute,
      );
    } catch (_) {}
  }

  String get tokenDateLabel {
    return DateFormat('EEEE, d MMM yyyy').format(tokenDate.value);
  }

  String get tokenDateIso {
    return DateFormat('yyyy-MM-dd').format(tokenDate.value);
  }

  void setTokenDate(DateTime date) {
    tokenDate.value = date;
  }

  void _loadTariffPlan() {
    tariffPlanCode.value = tariffConfig.planCode;
  }

  int _parseInt(String input) {
    final cleaned = input.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(cleaned) ?? 0;
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

  DateTime _parseDate(String value) {
    try {
      return DateTime.parse(value);
    } catch (_) {
      return DateTime.now();
    }
  }

  // ── Navigation ────────────────────────────────────────────────────────────

  void goToNearestPln() => Get.toNamed('/nearest_pln');

  void goToAppliances() {
    if (Get.isRegistered<DashboardController>()) {
      Get.find<DashboardController>().changePage(2);
      return;
    }
    Get.toNamed('/dashboard');
  }
}
