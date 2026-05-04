import 'dart:async';
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

class ProfileController extends GetxController {
  final _session = SessionService();
  final _repo = AuthRepository();
  final _biometric = BiometricService();

  // ── State ─────────────────────────────────────────────────────────────────
  final username = ''.obs;
  final currentTime = DateTime.now().obs; // UTC, updated every second
  
  final isBiometricSupported = false.obs;
  final isBiometricEnabled = false.obs;
  final isNotificationEnabled = false.obs;
  final selectedTimezoneIndex = 0.obs;

  Timer? _clockTimer;

  @override
  void onInit() {
    super.onInit();
    _loadUsername();
    _startClock();
    _checkBiometric();
    _loadNotificationSetting();
    evaluateAchievements();
  }

  @override
  void onClose() {
    _clockTimer?.cancel();
    super.onClose();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Future<void> _loadNotificationSetting() async {
    isNotificationEnabled.value = await _repo.isNotificationEnabled();
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
    isNotificationEnabled.value = val;
    await _repo.setNotificationEnabled(val);
    
    try {
      final notifService = Get.find<powerlog_notification.NotificationService>();
      await notifService.scheduleDailyReminder(val);
    } catch (e) {
      // Service not found
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

  // ── Phase 3: Achievements & Export ────────────────────────────────────────

  final has7DayStreak = false.obs;
  final isEcoSaver = false.obs;
  final isExporting = false.obs;

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
    if (logs.length >= 7) {
      int consecutiveDays = 1;
      for (int i = 0; i < logs.length - 1; i++) {
        final d1 = DateTime.parse(logs[i].date);
        final d2 = DateTime.parse(logs[i+1].date);
        final diff = d1.difference(d2).inDays;
        if (diff == 1) {
          consecutiveDays++;
        } else if (diff > 1) {
          break; // streak broken
        }
      }
      has7DayStreak.value = consecutiveDays >= 7;
    }
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
}
