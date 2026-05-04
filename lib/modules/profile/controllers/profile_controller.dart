import 'dart:async';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:powerlog/data/repositories/auth_repository.dart';
import 'package:powerlog/services/biometric_service.dart';
import 'package:powerlog/services/session_service.dart';
import 'package:powerlog/utils/timezone_converter.dart';
import 'package:powerlog/services/notification_service.dart' as powerlog_notification;

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

  Timer? _clockTimer;

  @override
  void onInit() {
    super.onInit();
    _loadUsername();
    _startClock();
    _checkBiometric();
    _loadNotificationSetting();
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
}
