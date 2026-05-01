import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:powerlog/data/repositories/auth_repository.dart';
import 'package:powerlog/services/biometric_service.dart';

class AuthController extends GetxController {
  final _repo = AuthRepository();
  final _biometric = BiometricService();

  // ── Observable state ─────────────────────────────────────────────────────
  final isLoading = false.obs;
  final obscurePassword = true.obs;
  final errorMessage = ''.obs;
  final isRegistering = false.obs;
  final biometricAvailable = false.obs;

  // ── Form controllers ─────────────────────────────────────────────────────
  final usernameCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();
  final formKey = GlobalKey<FormState>();

  @override
  void onInit() {
    super.onInit();
    _checkBiometric();
  }

  @override
  void onClose() {
    usernameCtrl.dispose();
    passwordCtrl.dispose();
    super.onClose();
  }

  // ── Public actions ───────────────────────────────────────────────────────

  void toggleObscure() => obscurePassword.toggle();
  void toggleMode() {
    isRegistering.toggle();
    errorMessage.value = '';
  }

  Future<void> submit() async {
    if (!formKey.currentState!.validate()) return;
    isLoading.value = true;
    errorMessage.value = '';

    final username = usernameCtrl.text;
    final password = passwordCtrl.text;

    final error = isRegistering.value
        ? await _repo.register(username, password)
        : await _repo.login(username, password);

    isLoading.value = false;

    if (error != null) {
      errorMessage.value = error;
    } else {
      Get.offAllNamed('/dashboard');
    }
  }

  Future<void> loginWithBiometrics() async {
    if (!biometricAvailable.value) return;

    // Must have an active session to restore — biometric confirms identity
    final hasSession = await _repo.hasActiveSession();
    if (!hasSession) {
      errorMessage.value = 'No saved session. Please login with password first.';
      return;
    }

    isLoading.value = true;
    final authenticated = await _biometric.authenticate();
    isLoading.value = false;

    if (authenticated) {
      Get.offAllNamed('/dashboard');
    } else {
      errorMessage.value = 'Biometric authentication failed.';
    }
  }

  Future<void> _checkBiometric() async {
    biometricAvailable.value = await _biometric.isAvailable();
  }
}
