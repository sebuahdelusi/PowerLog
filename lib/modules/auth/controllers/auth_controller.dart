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

    isLoading.value = true;
    final authenticated = await _biometric.authenticate();

    if (authenticated) {
      final error = await _repo.loginWithSavedBiometric();
      isLoading.value = false;
      
      if (error != null) {
        errorMessage.value = error;
      } else {
        Get.offAllNamed('/dashboard');
      }
    } else {
      isLoading.value = false;
      errorMessage.value = 'Biometric authentication failed.';
    }
  }

  Future<void> _checkBiometric() async {
    final available = await _biometric.isAvailable();
    final enabled = await _repo.isBiometricEnabled();
    final username = await _repo.getSessionUsername();
    
    biometricAvailable.value = available && enabled && (username != null);
  }
}
