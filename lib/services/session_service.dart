import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Manages session tokens using flutter_secure_storage (encrypted on-device).
class SessionService {
  static const _keySessionToken = 'session_token';
  static const _keyUsername = 'session_username';
  static const _keyBiometricEnabled = 'biometric_enabled';
  static const _keyNotificationEnabled = 'notification_enabled';
  static const _keyReminderHour = 'notification_hour';
  static const _keyReminderMinute = 'notification_minute';
  static const _keyTimezoneCode = 'timezone_code';
  static const _keyTariffPlan = 'tariff_plan';
  static const _keyTariffRate = 'tariff_rate';
  static const _keyTariffFixedFee = 'tariff_fixed_fee';
  static const _keyTariffTaxPercent = 'tariff_tax_percent';
  static const _keyTariffIncludeTax = 'tariff_include_tax';
  static const _keyTariffIncludeFixedFee = 'tariff_include_fixed_fee';

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
