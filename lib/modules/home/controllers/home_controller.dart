import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:powerlog/data/models/log_model.dart';
import 'package:powerlog/data/repositories/log_repository.dart';

class HomeController extends GetxController {
  final _repo = LogRepository();

  // ── State ────────────────────────────────────────────────────────────────
  final logs = <LogModel>[].obs;
  final isLoading = false.obs;
  final isSaving = false.obs;
  final errorMessage = ''.obs;
  final kwhInput = ''.obs; // tracks live input for cost preview

  // ── Form ─────────────────────────────────────────────────────────────────
  final kwhCtrl = TextEditingController();
  final formKey = GlobalKey<FormState>();

  @override
  void onInit() {
    super.onInit();
    kwhCtrl.addListener(() => kwhInput.value = kwhCtrl.text);
    loadLogs();
  }

  @override
  void onClose() {
    kwhCtrl.dispose();
    super.onClose();
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  Future<void> loadLogs() async {
    isLoading.value = true;
    logs.value = await _repo.fetchAllLogs();
    isLoading.value = false;
  }

  Future<void> addLog() async {
    if (!formKey.currentState!.validate()) return;
    isSaving.value = true;
    errorMessage.value = '';

    final error = await _repo.addLog(kwhCtrl.text);

    if (error != null) {
      errorMessage.value = error;
    } else {
      kwhCtrl.clear();
      kwhInput.value = '';
      await loadLogs();
      Get.snackbar(
        '⚡ Log Saved',
        'Usage recorded successfully.',
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      );
    }
    isSaving.value = false;
  }

  Future<void> deleteLog(int id) async {
    await _repo.deleteLog(id);
    await loadLogs();
  }

  /// Preview estimated cost while user types.
  double get previewCost {
    final kwh = double.tryParse(kwhInput.value.trim()) ?? 0;
    return _repo.calculateCost(kwh);
  }
}
