import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Manages session tokens using flutter_secure_storage (encrypted on-device).
class SessionService {
  static const _keySessionToken = 'session_token';
  static const _keyUsername = 'session_username';

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

  Future<void> clearSession() async {
    await _storage.delete(key: _keySessionToken);
    await _storage.delete(key: _keyUsername);
  }

  String _buildToken(String username) {
    final ts = DateTime.now().millisecondsSinceEpoch;
    return '$username:$ts';
  }
}
