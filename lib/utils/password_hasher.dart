import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';

/// PBKDF2-SHA256 password hashing with per-user salt.
/// Falls back to legacy SHA-256 for existing hashes.
class PasswordHasher {
  static const _legacySalt = 'powerlog_2025_salt!';
  static const _algo = 'pbkdf2_sha256';
  static const _iterations = 60000;
  static const _saltLength = 16; // bytes
  static const _dkLen = 32; // bytes

  static String hash(String plainPassword) {
    final salt = _randomBytes(_saltLength);
    final dk = _pbkdf2Sha256(plainPassword, salt, _iterations, _dkLen);
    return '$_algo\$$_iterations\$${base64Url.encode(salt)}\$${base64Url.encode(dk)}';
  }

  static bool verify(String plainPassword, String storedHash) {
    if (storedHash.startsWith('$_algo\$')) {
      final parts = storedHash.split('\$');
      if (parts.length != 4) return false;
      final iter = int.tryParse(parts[1]);
      if (iter == null || iter <= 0) return false;
      final salt = base64Url.decode(parts[2]);
      final expected = base64Url.decode(parts[3]);
      final actual = _pbkdf2Sha256(plainPassword, salt, iter, expected.length);
      return _constantTimeEquals(actual, expected);
    }
    return _legacyVerify(plainPassword, storedHash);
  }

  static bool needsRehash(String storedHash) {
    if (!storedHash.startsWith('$_algo\$')) return true;
    final parts = storedHash.split('\$');
    if (parts.length != 4) return true;
    final iter = int.tryParse(parts[1]) ?? 0;
    return iter < _iterations;
  }

  static String _legacyHash(String plainPassword) {
    final salted = '$_legacySalt:$plainPassword';
    final bytes = utf8.encode(salted);
    return sha256.convert(bytes).toString();
  }

  static bool _legacyVerify(String plainPassword, String storedHash) {
    return _legacyHash(plainPassword) == storedHash;
  }

  static List<int> _pbkdf2Sha256(
    String password,
    List<int> salt,
    int iterations,
    int dkLen,
  ) {
    final hmac = Hmac(sha256, utf8.encode(password));
    const hashLen = 32; // SHA-256 output
    final blocks = (dkLen / hashLen).ceil();
    final out = <int>[];

    for (var block = 1; block <= blocks; block++) {
      final blockBytes = _f(hmac, salt, iterations, block);
      out.addAll(blockBytes);
    }

    return out.sublist(0, dkLen);
  }

  static List<int> _f(
    Hmac hmac,
    List<int> salt,
    int iterations,
    int blockIndex,
  ) {
    final blockIndexBytes = ByteData(4)..setUint32(0, blockIndex, Endian.big);
    var u = hmac.convert([...salt, ...blockIndexBytes.buffer.asUint8List()]).bytes;
    final out = List<int>.from(u);

    for (var i = 1; i < iterations; i++) {
      u = hmac.convert(u).bytes;
      for (var j = 0; j < out.length; j++) {
        out[j] ^= u[j];
      }
    }

    return out;
  }

  static List<int> _randomBytes(int length) {
    final rand = Random.secure();
    return List<int>.generate(length, (_) => rand.nextInt(256));
  }

  static bool _constantTimeEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a[i] ^ b[i];
    }
    return diff == 0;
  }
}
