import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:powerlog/data/repositories/auth_repository.dart';
import 'package:powerlog/services/biometric_service.dart';
import 'package:powerlog/services/session_service.dart';
import 'package:powerlog/utils/timezone_converter.dart';
import 'package:powerlog/services/notification_service.dart' as powerlog_notification;
import 'package:powerlog/data/repositories/log_repository.dart' as powerlog_log_repo;
import 'package:powerlog/data/repositories/appliance_repository.dart' as powerlog_app_repo;
import 'package:powerlog/services/pdf_service.dart' as powerlog_pdf_service;
import 'package:powerlog/services/tariff_service.dart';
import 'package:powerlog/services/exchange_rate_service.dart';
import 'package:powerlog/modules/home/controllers/home_controller.dart';
import 'package:powerlog/modules/analytics/controllers/analytics_controller.dart';
import 'package:powerlog/data/local/database_helper.dart';
import 'package:powerlog/app/theme/app_colors.dart';

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
  final isCustomReminderEnabled = false.obs;
  final customReminderDateTime = DateTime.now().obs;
  final selectedTimezoneIndex = 0.obs;
  final compassHeading = 0.0.obs;
  final isCompassAvailable = false.obs;

  // Tariff settings
  final tariffPlanCode = ''.obs;
  final ratePerKwh = 0.0.obs;
  final fixedFee = 0.0.obs;
  final taxPercent = 10.0.obs;
  final includeTax = true.obs;
  final includeFixedFee = false.obs;

  // Currency settings
  final currencyOptions = <String>[].obs;
  final selectedCurrencies = <String>[].obs;
  final defaultCurrency = ''.obs;
  final isCurrencyLoading = false.obs;
  final currencyError = RxnString();

  Timer? _clockTimer;
  StreamSubscription<MagnetometerEvent>? _magSub;

  @override
  void onInit() {
    super.onInit();
    _loadUsername();
    _startClock();
    _startCompass();
    _checkBiometric();
    _initSettings();
    _loadTariffSettings();
    _loadCurrencySettings();
    evaluateAchievements();
  }

  @override
  void onClose() {
    _clockTimer?.cancel();
    _magSub?.cancel();
    _magSub = null;
    super.onClose();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Future<void> _initSettings() async {
    await _loadNotificationSetting();
    await _loadReminderTime();
    await _loadCustomReminder();
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

  Future<void> _loadCurrencySettings() async {
    isCurrencyLoading.value = true;
    currencyError.value = null;
    try {
      final exchange = Get.find<ExchangeRateService>();
      final options = await exchange.getAvailableCurrencies();
      final selected = await exchange.getSelectedCurrencies();
      var defaultCode = await exchange.getDefaultCurrency();

      var availableOptions = options;
      if (availableOptions.isEmpty) {
        final rates = await exchange.getRates('idr');
        if (rates.isNotEmpty) {
          availableOptions = rates.keys.toList()..sort();
        }
      }
      currencyError.value = exchange.lastError;

      final filteredSelected =
          _filterSelectedCurrencies(availableOptions, selected);
      if (!filteredSelected.contains(defaultCode)) {
        defaultCode = filteredSelected.first;
        await exchange.setDefaultCurrency(defaultCode);
      }

      if (availableOptions.isEmpty) {
        currencyOptions.assignAll(filteredSelected);
      } else {
        currencyOptions.assignAll(availableOptions);
      }
      selectedCurrencies.assignAll(filteredSelected);
      defaultCurrency.value = defaultCode;
    } catch (_) {
      if (selectedCurrencies.isEmpty) {
        selectedCurrencies.assignAll(['USD', 'EUR', 'GBP']);
        defaultCurrency.value = 'USD';
      }
      if (currencyOptions.isEmpty) {
        currencyOptions.assignAll(selectedCurrencies);
      }
      currencyError.value =
          currencyError.value ?? 'Failed to load currency list.';
    } finally {
      isCurrencyLoading.value = false;
    }
  }

  Future<void> refreshCurrencyOptions() async {
    isCurrencyLoading.value = true;
    currencyError.value = null;
    try {
      final exchange = Get.find<ExchangeRateService>();
      var options = await exchange.getAvailableCurrencies(forceRefresh: true);
      if (options.isEmpty) {
        final rates = await exchange.getRates('idr', forceRefresh: true);
        if (rates.isNotEmpty) {
          options = rates.keys.toList()..sort();
        }
      }
      currencyError.value = exchange.lastError;
      if (options.isNotEmpty) {
        currencyOptions.assignAll(options);
      }
    } catch (_) {
      if (currencyOptions.isEmpty) {
        currencyOptions.assignAll(selectedCurrencies);
      }
      currencyError.value =
          currencyError.value ?? 'Failed to refresh currency list.';
    } finally {
      isCurrencyLoading.value = false;
    }
  }

  List<String> _filterSelectedCurrencies(
    List<String> options,
    List<String> selected,
  ) {
    final allowed = options.isEmpty
        ? selected
        : selected.where((code) => options.contains(code)).toList();
    if (allowed.isNotEmpty) return allowed;

    final fallback = ['USD', 'EUR', 'GBP'];
    final valid = options.isEmpty
        ? fallback
        : fallback.where((code) => options.contains(code)).toList();
    return valid.isNotEmpty ? valid : (options.isNotEmpty ? [options.first] : []);
  }

  Future<void> toggleCurrencySelection(String code, bool enabled) async {
    final exchange = Get.find<ExchangeRateService>();
    final updated = selectedCurrencies.toList();
    if (enabled) {
      if (!updated.contains(code)) updated.add(code);
    } else {
      if (updated.length <= 1) return;
      updated.remove(code);
    }
    updated.sort();
    selectedCurrencies.assignAll(updated);
    await exchange.setSelectedCurrencies(updated);

    if (!updated.contains(defaultCurrency.value)) {
      defaultCurrency.value = updated.first;
      await exchange.setDefaultCurrency(defaultCurrency.value);
    }
  }

  Future<void> setDefaultCurrency(String code) async {
    defaultCurrency.value = code;
    await Get.find<ExchangeRateService>().setDefaultCurrency(code);
  }

  Future<void> _loadNotificationSetting() async {
    isNotificationEnabled.value = await _repo.isNotificationEnabled();
  }

  Future<void> _loadReminderTime() async {
    final hour = await _session.getReminderHour();
    final minute = await _session.getReminderMinute();
    reminderTime.value = TimeOfDay(hour: hour, minute: minute);
  }

  Future<void> _loadCustomReminder() async {
    isCustomReminderEnabled.value = await _session.isCustomReminderEnabled();
    final stored = await _session.getCustomReminderDateTime();
    customReminderDateTime.value = stored ?? _defaultCustomDateTime();
  }

  Future<void> _loadTimezone() async {
    final code = await _session.getTimezoneCode();
    final index = timezones.indexWhere((tz) => tz.code == code);
    selectedTimezoneIndex.value = index >= 0 ? index : 0;
    _applyTimezoneSelection();
  }

  Future<void> _syncNotificationSchedule() async {
    await _syncAutoReminder();
    await _syncCustomReminder();
  }

  Future<void> _syncAutoReminder() async {
    try {
      final notifService =
          Get.find<powerlog_notification.NotificationService>();

      if (!isNotificationEnabled.value) {
        await notifService.scheduleTokenReminder(enable: false);
        await notifService.scheduleDailyReminder(enable: false);
        return;
      }

      if (Get.isRegistered<AnalyticsController>()) {
        final analytics = Get.find<AnalyticsController>();
        final estimate = analytics.estimatedEndDateTime;
        if (estimate != null) {
          // Use token-based estimation reminder
          await notifService.scheduleTokenReminder(
            enable: true,
            scheduledAt: estimate,
          );
          // Cancel daily reminder if we have token-based
          await notifService.scheduleDailyReminder(enable: false);
          return;
        }
      }

      // Fallback to daily if no estimation or analytics not available
      await notifService.scheduleDailyReminder(
        enable: true,
        hour: reminderTime.value.hour,
        minute: reminderTime.value.minute,
      );
    } catch (_) {}
  }

  Future<void> _syncCustomReminder() async {
    if (!isCustomReminderEnabled.value) return;
    try {
      final notifService = Get.find<powerlog_notification.NotificationService>();
      await notifService.scheduleCustomReminder(
        enable: true,
        scheduledAt: customReminderDateTime.value,
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
      await _syncAutoReminder();
      await _repo.setNotificationEnabled(val);
    } catch (e) {
      isNotificationEnabled.value = previous;
      await _repo.setNotificationEnabled(previous);
      Get.snackbar('Notification Error', 'Failed to update reminder schedule.');
    }
  }

  Future<void> toggleCustomReminder(bool val) async {
    final previous = isCustomReminderEnabled.value;
    isCustomReminderEnabled.value = val;
    await _session.setCustomReminderEnabled(val);

    try {
      final notifService = Get.find<powerlog_notification.NotificationService>();
      await notifService.scheduleCustomReminder(
        enable: val,
        scheduledAt: customReminderDateTime.value,
      );
    } catch (e) {
      isCustomReminderEnabled.value = previous;
      await _session.setCustomReminderEnabled(previous);
      Get.snackbar('Notification Error', 'Failed to update custom reminder.');
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

  Future<void> setCustomReminderDateTime(DateTime dateTime) async {
    final previous = customReminderDateTime.value;
    customReminderDateTime.value = dateTime;
    await _session.setCustomReminderDateTime(dateTime);

    if (!isCustomReminderEnabled.value) return;
    try {
      final notifService = Get.find<powerlog_notification.NotificationService>();
      await notifService.scheduleCustomReminder(
        enable: true,
        scheduledAt: dateTime,
      );
    } catch (e) {
      customReminderDateTime.value = previous;
      await _session.setCustomReminderDateTime(previous);
      Get.snackbar('Notification Error', 'Failed to reschedule custom reminder.');
    }
  }

  void _startClock() {
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      currentTime.value = DateTime.now();
    });
  }

  void _startCompass() {
    if (_magSub != null) return;
    _magSub = magnetometerEventStream(
      samplingPeriod: SensorInterval.gameInterval,
    ).listen(
      _onMagnetometer,
      onError: (_) {
        isCompassAvailable.value = false;
      },
    );
  }

  void _onMagnetometer(MagnetometerEvent event) {
    final heading = atan2(event.y, event.x) * (180 / pi);
    var deg = heading;
    if (deg < 0) deg += 360;
    compassHeading.value = deg;
    isCompassAvailable.value = true;
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

  String get customReminderLabel {
    return DateFormat('EEE, d MMM yyyy • HH:mm')
        .format(customReminderDateTime.value);
  }

  String get autoReminderSubtitle {
    if (!Get.isRegistered<AnalyticsController>()) {
      return 'Daily at ${reminderTime.value.hour.toString().padLeft(2, '0')}:${reminderTime.value.minute.toString().padLeft(2, '0')} (auto)';
    }
    final analytics = Get.find<AnalyticsController>();
    final label = analytics.estimatedEndDateLabel;
    if (label == '-') return 'Estimation unavailable (auto)';
    return 'Remind at $label (auto)';
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

    if (isCustomReminderEnabled.value) {
      try {
        final notifService = Get.find<powerlog_notification.NotificationService>();
        await notifService.scheduleCustomReminder(
          enable: true,
          scheduledAt: customReminderDateTime.value,
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

  DateTime _defaultCustomDateTime() {
    final now = DateTime.now();
    var dt = DateTime(now.year, now.month, now.day, 20, 0);
    if (dt.isBefore(now)) {
      dt = dt.add(const Duration(days: 1));
    }
    return dt;
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
      await Get.find<HomeController>().refreshEstimator();
    }
    if (Get.isRegistered<AnalyticsController>()) {
      await Get.find<AnalyticsController>().loadData();
    }
    await _syncAutoReminder();
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

  Future<void> seedMockLogs(String scenario) async {
    final logRepo = powerlog_log_repo.LogRepository();
    
    try {
      final db = DatabaseHelper.instance;
      final activeDb = await db.database;
      await activeDb.delete(DatabaseHelper.tableLogs);

      final now = DateTime.now();
      final df = DateFormat('yyyy-MM-dd');

      if (scenario == 'eco_saver') {
        await logRepo.addLog('3.2', date: df.format(now));
        Get.snackbar(
          'Scenario Loaded',
          'Eco Saver scenario initialized: 1 log (3.2 kWh) added.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.surface,
          colorText: AppColors.textPrimary,
        );
      } else if (scenario == 'streak') {
        for (var i = 0; i < 7; i++) {
          final date = now.subtract(Duration(days: i));
          await logRepo.addLog('4.2', date: df.format(date));
        }
        Get.snackbar(
          'Scenario Loaded',
          '7-Day Streak scenario initialized: 7 consecutive logs added.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.surface,
          colorText: AppColors.textPrimary,
        );
      } else if (scenario == 'heavy') {
        await logRepo.addLog('7.5', date: df.format(now));
        Get.snackbar(
          'Scenario Loaded',
          'Heavy Usage scenario initialized: 1 log (7.5 kWh) added.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.surface,
          colorText: AppColors.textPrimary,
        );
      } else if (scenario == 'clear') {
        Get.snackbar(
          'Logs Cleared',
          'All mock logs cleared.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.surface,
          colorText: AppColors.textPrimary,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to seed scenario: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withValues(alpha: 0.8),
        colorText: Colors.white,
      );
    }

    await evaluateAchievements();
  }

  Future<void> exportPdf() async {
    isExporting.value = true;
    try {
      final logRepo = powerlog_log_repo.LogRepository();
      final appRepo = powerlog_app_repo.ApplianceRepository();
      final pdfService = powerlog_pdf_service.PdfService();
      final exchange = Get.find<ExchangeRateService>();

      final logs = await logRepo.fetchAllLogs();
      final appliances = await appRepo.fetchAllAppliances();

      final currencyCode = await exchange.getDefaultCurrency();
      final rate = await exchange.getRate(from: 'IDR', to: currencyCode);
      final safeRate = rate ?? 1.0;
      final safeCode = rate == null || safeRate <= 0 ? 'IDR' : currencyCode;

      await pdfService.generateAndOpenMonthlyReport(
        username.value,
        logs,
        appliances,
        ratePerKwh.value,
        currencyCode: safeCode,
        currencyRate: safeRate,
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
