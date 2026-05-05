import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:powerlog/data/repositories/auth_repository.dart';
import 'package:powerlog/services/biometric_service.dart';
import 'package:powerlog/services/session_service.dart';
import 'package:powerlog/utils/timezone_converter.dart';
import 'package:powerlog/services/notification_service.dart' as powerlog_notification;
import 'package:powerlog/data/repositories/log_repository.dart' as powerlog_log_repo;
import 'package:powerlog/data/repositories/appliance_repository.dart' as powerlog_app_repo;
import 'package:powerlog/services/pdf_service.dart' as powerlog_pdf_service;
import 'package:powerlog/services/tariff_service.dart';
import 'package:powerlog/modules/home/controllers/home_controller.dart';
import 'package:powerlog/modules/analytics/controllers/analytics_controller.dart';

class ProfileController extends GetxController {
  final _session = SessionService();
  final _repo = AuthRepository();
  final _biometric = BiometricService();
  final _tariffService = Get.find<TariffService>();

  // ── State ─────────────────────────────────────────────────────────────────
  final username = ''.obs;
  final currentTime = DateTime.now().obs; // UTC, updated every second
  
  final isBiometricSupported = false.obs;
  final isBiometricEnabled = false.obs;
  final isNotificationEnabled = false.obs;
  final reminderTime = const TimeOfDay(hour: 20, minute: 0).obs;
  final selectedTimezoneIndex = 0.obs;

  // Tariff settings
  final tariffPlanCode = ''.obs;
  final ratePerKwh = 0.0.obs;
  final fixedFee = 0.0.obs;
  final taxPercent = 10.0.obs;
  final includeTax = true.obs;
  final includeFixedFee = false.obs;

  Timer? _clockTimer;

  @override
  void onInit() {
    super.onInit();
    _loadUsername();
    _startClock();
    _checkBiometric();
    _initSettings();
    _loadTariffSettings();
    evaluateAchievements();
  }

  @override
  void onClose() {
    _clockTimer?.cancel();
    super.onClose();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Future<void> _initSettings() async {
    await _loadNotificationSetting();
    await _loadReminderTime();
    await _loadTimezone();
    await _syncNotificationSchedule();
  }

  void _loadTariffSettings() {
    final cfg = _tariffService.config.value;
    tariffPlanCode.value = cfg.planCode;
    ratePerKwh.value = cfg.ratePerKwh;
    fixedFee.value = cfg.fixedFee;
    taxPercent.value = cfg.taxPercent;
    includeTax.value = cfg.includeTax;
    includeFixedFee.value = cfg.includeFixedFee;
  }

  Future<void> _loadNotificationSetting() async {
    isNotificationEnabled.value = await _repo.isNotificationEnabled();
  }

  Future<void> _loadReminderTime() async {
    final hour = await _session.getReminderHour();
    final minute = await _session.getReminderMinute();
    reminderTime.value = TimeOfDay(hour: hour, minute: minute);
  }

  Future<void> _loadTimezone() async {
    final code = await _session.getTimezoneCode();
    final index = timezones.indexWhere((tz) => tz.code == code);
    selectedTimezoneIndex.value = index >= 0 ? index : 0;
    _applyTimezoneSelection();
  }

  Future<void> _syncNotificationSchedule() async {
    if (!isNotificationEnabled.value) return;
    try {
      final notifService = Get.find<powerlog_notification.NotificationService>();
      await notifService.scheduleDailyReminder(
        enable: true,
        hour: reminderTime.value.hour,
        minute: reminderTime.value.minute,
      );
    } catch (_) {}
  }

  Future<void> _loadUsername() async {
    final name = await _session.getSessionUsername();
    username.value = name ?? 'User';
  }

  Future<void> _checkBiometric() async {
    isBiometricSupported.value = await _biometric.isAvailable();
    if (isBiometricSupported.value) {
      isBiometricEnabled.value = await _repo.isBiometricEnabled();
    }
  }

  Future<void> toggleBiometric(bool val) async {
    if (val) {
      // Require auth to enable
      final auth = await _biometric.authenticate();
      if (!auth) {
        Get.snackbar('Failed', 'Biometric authentication failed.');
        return;
      }
    }
    isBiometricEnabled.value = val;
    await _repo.setBiometricEnabled(val);
  }

  Future<void> toggleNotification(bool val) async {
    final previous = isNotificationEnabled.value;
    isNotificationEnabled.value = val;

    try {
      final notifService = Get.find<powerlog_notification.NotificationService>();
      await notifService.scheduleDailyReminder(
        enable: val,
        hour: reminderTime.value.hour,
        minute: reminderTime.value.minute,
      );
      await _repo.setNotificationEnabled(val);
    } catch (e) {
      isNotificationEnabled.value = previous;
      await _repo.setNotificationEnabled(previous);
      Get.snackbar('Notification Error', 'Failed to update reminder schedule.');
    }
  }

  Future<void> setReminderTime(TimeOfDay time) async {
    final previous = reminderTime.value;
    reminderTime.value = time;
    await _session.setReminderTime(time.hour, time.minute);

    if (!isNotificationEnabled.value) return;
    try {
      final notifService = Get.find<powerlog_notification.NotificationService>();
      await notifService.scheduleDailyReminder(
        enable: true,
        hour: time.hour,
        minute: time.minute,
      );
    } catch (e) {
      reminderTime.value = previous;
      await _session.setReminderTime(previous.hour, previous.minute);
      Get.snackbar('Notification Error', 'Failed to reschedule reminder.');
    }
  }

  void _startClock() {
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      currentTime.value = DateTime.now();
    });
  }

  /// Returns formatted time for a given timezone info.
  String timeFor(TzInfo tz) {
    final converted = TimezoneConverter.toZone(tz, currentTime.value);
    return DateFormat('HH:mm:ss').format(converted);
  }

  String dateFor(TzInfo tz) {
    final converted = TimezoneConverter.toZone(tz, currentTime.value);
    return DateFormat('EEE, d MMM').format(converted);
  }

  List<TzInfo> get timezones => TimezoneConverter.zones;

  List<TariffPlan> get tariffPlans => TariffService.plans;

  Future<void> setTimezoneIndex(int index) async {
    if (index < 0 || index >= timezones.length) return;
    selectedTimezoneIndex.value = index;
    await _session.setTimezoneCode(timezones[index].code);
    _applyTimezoneSelection();

    if (isNotificationEnabled.value) {
      try {
        final notifService = Get.find<powerlog_notification.NotificationService>();
        await notifService.scheduleDailyReminder(
          enable: true,
          hour: reminderTime.value.hour,
          minute: reminderTime.value.minute,
        );
      } catch (_) {}
    }
  }

  void _applyTimezoneSelection() {
    try {
      final notifService = Get.find<powerlog_notification.NotificationService>();
      final code = timezones[selectedTimezoneIndex.value].code;
      notifService.setTimezoneCode(code);
    } catch (_) {}
  }

  Future<void> setTariffPlan(String code) async {
    tariffPlanCode.value = code;
    final plan = _tariffService.getPlan(code);
    if (plan != null && plan.code != 'CUSTOM') {
      ratePerKwh.value = plan.defaultRate;
    }
    await _saveTariff();
  }

  Future<void> updateRatePerKwh(double value) async {
    if (value <= 0) return;
    ratePerKwh.value = value;
    await _saveTariff();
  }

  Future<void> updateFixedFee(double value) async {
    if (value < 0) return;
    fixedFee.value = value;
    await _saveTariff();
  }

  Future<void> updateTaxPercent(double value) async {
    if (value < 0) return;
    taxPercent.value = value;
    await _saveTariff();
  }

  Future<void> toggleIncludeTax(bool value) async {
    includeTax.value = value;
    await _saveTariff();
  }

  Future<void> toggleIncludeFixedFee(bool value) async {
    includeFixedFee.value = value;
    await _saveTariff();
  }

  Future<void> _saveTariff() async {
    final cfg = TariffConfig(
      planCode: tariffPlanCode.value,
      ratePerKwh: ratePerKwh.value,
      fixedFee: fixedFee.value,
      taxPercent: taxPercent.value,
      includeTax: includeTax.value,
      includeFixedFee: includeFixedFee.value,
    );

    await _tariffService.updateConfig(cfg);
    await _recalculateLogCosts();
    await _refreshDashboardData();
    Get.snackbar('Tariff Updated', 'Log costs recalculated with new rates.');
  }

  Future<void> _recalculateLogCosts() async {
    final logRepo = powerlog_log_repo.LogRepository();
    await logRepo.recalculateAllCosts();
  }

  Future<void> _refreshDashboardData() async {
    if (Get.isRegistered<HomeController>()) {
      await Get.find<HomeController>().loadLogs();
    }
    if (Get.isRegistered<AnalyticsController>()) {
      await Get.find<AnalyticsController>().loadData();
    }
  }

  // ── Phase 3: Achievements & Export ────────────────────────────────────────

  final has7DayStreak = false.obs;
  final isEcoSaver = false.obs;
  final isExporting = false.obs;
  final isExportingCsv = false.obs;

  static int computeStreakDays(List<String> dateStrings) {
    if (dateStrings.isEmpty) return 0;

    final dates = <DateTime>[];
    for (final d in dateStrings) {
      try {
        dates.add(DateTime.parse(d));
      } catch (_) {}
    }
    if (dates.isEmpty) return 0;

    dates.sort((a, b) => b.compareTo(a));
    var streak = 1;

    for (var i = 0; i < dates.length - 1; i++) {
      final d1 = dates[i];
      final d2 = dates[i + 1];
      final diff = d1.difference(d2).inDays;
      if (diff == 0) {
        continue; // same day duplicate
      } else if (diff == 1) {
        streak++;
      } else if (diff > 1) {
        break;
      }
    }

    return streak;
  }

  Future<void> evaluateAchievements() async {
    final logRepo = powerlog_log_repo.LogRepository();
    final logs = await logRepo.fetchAllLogs();

    if (logs.isEmpty) {
      has7DayStreak.value = false;
      isEcoSaver.value = false;
      return;
    }

    // Check Eco Saver (last log < 5 kWh)
    if (logs.first.kwhUsage < 5.0) {
      isEcoSaver.value = true;
    } else {
      isEcoSaver.value = false;
    }

    // Check 7 Day Streak
    final streak = computeStreakDays(logs.map((e) => e.date).toList());
    has7DayStreak.value = streak >= 7;
  }

  Future<void> exportPdf() async {
    isExporting.value = true;
    try {
      final logRepo = powerlog_log_repo.LogRepository();
      final appRepo = powerlog_app_repo.ApplianceRepository();
      final pdfService = powerlog_pdf_service.PdfService();

      final logs = await logRepo.fetchAllLogs();
      final appliances = await appRepo.fetchAllAppliances();

      await pdfService.generateAndOpenMonthlyReport(
        username.value,
        logs,
        appliances,
      );
    } catch (e) {
      Get.snackbar('Export Failed', e.toString());
    } finally {
      isExporting.value = false;
    }
  }

  Future<void> exportCsv() async {
    isExportingCsv.value = true;
    try {
      final logRepo = powerlog_log_repo.LogRepository();
      final appRepo = powerlog_app_repo.ApplianceRepository();
      final pdfService = powerlog_pdf_service.PdfService();

      final logs = await logRepo.fetchAllLogs();
      final appliances = await appRepo.fetchAllAppliances();

      await pdfService.generateAndOpenMonthlyCsv(
        username.value,
        logs,
        appliances,
      );

      final hasAppliances = appliances.isNotEmpty;
      Get.snackbar(
        'CSV Exported',
        hasAppliances
            ? 'Saved PowerLog_Logs.csv and PowerLog_Appliances.csv'
            : 'Saved PowerLog_Logs.csv',
      );
    } catch (e) {
      Get.snackbar('Export Failed', e.toString());
    } finally {
      isExportingCsv.value = false;
    }
  }
}
