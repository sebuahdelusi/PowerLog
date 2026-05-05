import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Manages session tokens using flutter_secure_storage (encrypted on-device).
class SessionService {
  static const _keySessionToken = 'session_token';
  static const _keyUsername = 'session_username';
  static const _keyBiometricEnabled = 'biometric_enabled';
  static const _keyNotificationEnabled = 'notification_enabled';
  static const _keyReminderHour = 'notification_hour';
  static const _keyReminderMinute = 'notification_minute';
  static const _keyCustomReminderEnabled = 'custom_reminder_enabled';
  static const _keyCustomReminderDateTime = 'custom_reminder_datetime';
  static const _keyAutoReminderDateTime = 'auto_reminder_datetime';
  static const _keyTimezoneCode = 'timezone_code';
  static const _keyTariffPlan = 'tariff_plan';
  static const _keyTariffRate = 'tariff_rate';
  static const _keyTariffFixedFee = 'tariff_fixed_fee';
  static const _keyTariffTaxPercent = 'tariff_tax_percent';
  static const _keyTariffIncludeTax = 'tariff_include_tax';
  static const _keyTariffIncludeFixedFee = 'tariff_include_fixed_fee';
  static const _keyMeterVa = 'meter_va';
  static const _keyTokenAmount = 'token_amount';

  final _storage = const FlutterSecureStorage();

  Future<void> saveSession(String username) async {
    // Token = base64(username:timestamp) — lightweight, local-only
    final token = _buildToken(username);
    await _storage.write(key: _keySessionToken, value: token);
    await _storage.write(key: _keyUsername, value: username);
  }

  Future<bool> hasActiveSession() async {
    final token = await _storage.read(key: _keySessionToken);
    return token != null && token.isNotEmpty;
  }

  Future<String?> getSessionUsername() async {
    return _storage.read(key: _keyUsername);
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    await _storage.write(key: _keyBiometricEnabled, value: enabled.toString());
  }

  Future<bool> isBiometricEnabled() async {
    final val = await _storage.read(key: _keyBiometricEnabled);
    return val == 'true';
  }

  Future<void> setNotificationEnabled(bool enabled) async {
    await _storage.write(key: _keyNotificationEnabled, value: enabled.toString());
  }

  Future<bool> isNotificationEnabled() async {
    final val = await _storage.read(key: _keyNotificationEnabled);
    return val == 'true';
  }

  Future<void> setReminderTime(int hour, int minute) async {
    await _storage.write(key: _keyReminderHour, value: hour.toString());
    await _storage.write(key: _keyReminderMinute, value: minute.toString());
  }

  Future<int> getReminderHour() async {
    final val = await _storage.read(key: _keyReminderHour);
    return int.tryParse(val ?? '') ?? 20;
  }

  Future<int> getReminderMinute() async {
    final val = await _storage.read(key: _keyReminderMinute);
    return int.tryParse(val ?? '') ?? 0;
  }

  Future<void> setCustomReminderEnabled(bool enabled) async {
    await _storage.write(
        key: _keyCustomReminderEnabled, value: enabled.toString());
  }

  Future<bool> isCustomReminderEnabled() async {
    final val = await _storage.read(key: _keyCustomReminderEnabled);
    return val == 'true';
  }

  Future<void> setCustomReminderDateTime(DateTime dateTime) async {
    await _storage.write(
      key: _keyCustomReminderDateTime,
      value: dateTime.toIso8601String(),
    );
  }

  Future<DateTime?> getCustomReminderDateTime() async {
    final val = await _storage.read(key: _keyCustomReminderDateTime);
    if (val == null || val.isEmpty) return null;
    return DateTime.tryParse(val);
  }

  Future<void> setAutoReminderDateTime(DateTime dateTime) async {
    await _storage.write(
      key: _keyAutoReminderDateTime,
      value: dateTime.toIso8601String(),
    );
  }

  Future<DateTime?> getAutoReminderDateTime() async {
    final val = await _storage.read(key: _keyAutoReminderDateTime);
    if (val == null || val.isEmpty) return null;
    return DateTime.tryParse(val);
  }

  Future<void> clearAutoReminderDateTime() async {
    await _storage.delete(key: _keyAutoReminderDateTime);
  }

  Future<void> setTimezoneCode(String code) async {
    await _storage.write(key: _keyTimezoneCode, value: code);
  }

  Future<String> getTimezoneCode() async {
    final val = await _storage.read(key: _keyTimezoneCode);
    return val ?? 'WIB';
  }

  Future<void> setTariffPlanCode(String code) async {
    await _storage.write(key: _keyTariffPlan, value: code);
  }

  Future<String> getTariffPlanCode() async {
    final val = await _storage.read(key: _keyTariffPlan);
    return val ?? 'R1_1300';
  }

  Future<void> setTariffRate(double rate) async {
    await _storage.write(key: _keyTariffRate, value: rate.toString());
  }

  Future<double> getTariffRate() async {
    final val = await _storage.read(key: _keyTariffRate);
    return double.tryParse(val ?? '') ?? 0.0;
  }

  Future<void> setTariffFixedFee(double fee) async {
    await _storage.write(key: _keyTariffFixedFee, value: fee.toString());
  }

  Future<double> getTariffFixedFee() async {
    final val = await _storage.read(key: _keyTariffFixedFee);
    return double.tryParse(val ?? '') ?? 0.0;
  }

  Future<void> setTariffTaxPercent(double percent) async {
    await _storage.write(key: _keyTariffTaxPercent, value: percent.toString());
  }

  Future<double> getTariffTaxPercent() async {
    final val = await _storage.read(key: _keyTariffTaxPercent);
    return double.tryParse(val ?? '') ?? 10.0;
  }

  Future<void> setTariffIncludeTax(bool enabled) async {
    await _storage.write(key: _keyTariffIncludeTax, value: enabled.toString());
  }

  Future<bool> getTariffIncludeTax() async {
    final val = await _storage.read(key: _keyTariffIncludeTax);
    return val != 'false';
  }

  Future<void> setTariffIncludeFixedFee(bool enabled) async {
    await _storage.write(
        key: _keyTariffIncludeFixedFee, value: enabled.toString());
  }

  Future<bool> getTariffIncludeFixedFee() async {
    final val = await _storage.read(key: _keyTariffIncludeFixedFee);
    return val == 'true';
  }

  Future<void> setMeterVa(int va) async {
    await _storage.write(key: _keyMeterVa, value: va.toString());
  }

  Future<int> getMeterVa() async {
    final val = await _storage.read(key: _keyMeterVa);
    return int.tryParse(val ?? '') ?? 0;
  }

  Future<void> setTokenAmount(int amount) async {
    await _storage.write(key: _keyTokenAmount, value: amount.toString());
  }

  Future<int> getTokenAmount() async {
    final val = await _storage.read(key: _keyTokenAmount);
    return int.tryParse(val ?? '') ?? 0;
  }

  Future<void> clearSession() async {
    await _storage.delete(key: _keySessionToken);
    final bio = await isBiometricEnabled();
    if (!bio) {
      await _storage.delete(key: _keyUsername);
    }
  }

  String _buildToken(String username) {
    final ts = DateTime.now().millisecondsSinceEpoch;
    return '$username:$ts';
  }
}
