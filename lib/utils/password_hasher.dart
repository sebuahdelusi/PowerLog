import 'dart:convert';
import 'package:crypto/crypto.dart';

/// SHA-256 based password hashing.
/// Prepends a fixed app-level salt so the output is deterministic per app.
class PasswordHasher {
  static const _appSalt = 'powerlog_2025_salt!';

  static String hash(String plainPassword) {
    final salted = '$_appSalt:$plainPassword';
    final bytes = utf8.encode(salted);
    return sha256.convert(bytes).toString();
  }

  static bool verify(String plainPassword, String storedHash) {
    return hash(plainPassword) == storedHash;
  }
}
