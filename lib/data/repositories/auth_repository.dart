import '../local/database_helper.dart';
import '../models/user_model.dart';
import '../../utils/password_hasher.dart';
import '../../services/session_service.dart';

class AuthRepository {
  final _db = DatabaseHelper.instance;
  final _session = SessionService();

  /// Returns null on success, or an error message string on failure.
  Future<String?> login(String username, String password) async {
    try {
      final user = await _db.getUserByUsername(username.trim());
      if (user == null) return 'Username not found.';

      final valid = PasswordHasher.verify(password, user.encryptedPassword);
      if (!valid) return 'Incorrect password.';

      await _session.saveSession(username.trim());
      return null;
    } catch (e) {
      return 'Login error: $e';
    }
  }

  /// Registers a new user. Returns null on success, error string on failure.
  Future<String?> register(String username, String password) async {
    try {
      if (username.trim().isEmpty || password.isEmpty) {
        return 'Username and password cannot be empty.';
      }
      final exists = await _db.usernameExists(username.trim());
      if (exists) return 'Username already taken.';

      final hashed = PasswordHasher.hash(password);
      final user = UserModel(
        username: username.trim(),
        encryptedPassword: hashed,
      );
      await _db.insertUser(user);
      await _session.saveSession(username.trim());
      return null;
    } catch (e) {
      return 'Registration error: $e';
    }
  }

  Future<bool> hasActiveSession() => _session.hasActiveSession();
  Future<String?> getSessionUsername() => _session.getSessionUsername();
  Future<void> logout() => _session.clearSession();

  Future<bool> isBiometricEnabled() => _session.isBiometricEnabled();
  Future<void> setBiometricEnabled(bool enabled) => _session.setBiometricEnabled(enabled);

  Future<bool> isNotificationEnabled() => _session.isNotificationEnabled();
  Future<void> setNotificationEnabled(bool enabled) => _session.setNotificationEnabled(enabled);

  Future<String?> loginWithSavedBiometric() async {
    try {
      final username = await _session.getSessionUsername();
      if (username == null) return 'No saved user. Please login with password first.';
      
      final user = await _db.getUserByUsername(username);
      if (user == null) return 'User no longer exists.';
      
      await _session.saveSession(username);
      return null;
    } catch (e) {
      return 'Biometric login error: $e';
    }
  }
}
