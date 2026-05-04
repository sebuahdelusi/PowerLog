import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:powerlog/data/models/log_model.dart';
import 'package:powerlog/data/repositories/log_repository.dart';
import 'package:powerlog/services/sensor_service.dart';

class HomeController extends GetxController {
  final _repo = LogRepository();
  final _sensors = SensorService();

  // ── State ────────────────────────────────────────────────────────────────
  final logs = <LogModel>[].obs;
  final isLoading = false.obs;
  final isSaving = false.obs;
  final errorMessage = ''.obs;
  final kwhInput = ''.obs;
  final searchQuery = ''.obs;
  final selectedCurrency = 'USD'.obs;

  List<LogModel> get filteredLogs {
    final query = searchQuery.value.toLowerCase().trim();
    if (query.isEmpty) return logs;
    return logs.where((log) {
      final dateStr = log.date.toLowerCase();
      final costStr = log.estimatedCost.toStringAsFixed(0);
      final kwhStr = log.kwhUsage.toStringAsFixed(2);
      return dateStr.contains(query) || costStr.contains(query) || kwhStr.contains(query);
    }).toList();
  }

  // ── Gyroscope ─────────────────────────────────────────────────────────────
  final gyroX = 0.0.obs; // angular velocity x-axis
  final gyroY = 0.0.obs; // angular velocity y-axis

  // ── Torch indicator ───────────────────────────────────────────────────────
  final isTorchOn = false.obs;

  // ── Form ──────────────────────────────────────────────────────────────────
  final kwhCtrl = TextEditingController();
  final formKey = GlobalKey<FormState>();

  // ── Subscriptions ─────────────────────────────────────────────────────────
  StreamSubscription<void>? _shakeSub;
  StreamSubscription<GyroscopeEvent>? _gyroSub;
  bool _sensorsReady = false;

  @override
  void onInit() {
    super.onInit();
    kwhCtrl.addListener(() => kwhInput.value = kwhCtrl.text);
    resumeSensors();
    loadLogs();
  }

  @override
  void onClose() {
    kwhCtrl.dispose();
    pauseSensors();
    _sensors.dispose();
    super.onClose();
  }

  // ── Sensor init ───────────────────────────────────────────────────────────

  Future<void> resumeSensors() async {
    if (!_sensorsReady) {
      await _sensors.init();
      _sensorsReady = true;
    }

    _sensors.resume();

    _shakeSub ??= _sensors.onShake.listen((_) {
      isTorchOn.value = _sensors.isTorchOn;
      Get.snackbar(
        isTorchOn.value ? '🔦 Torch ON' : '🔦 Torch OFF',
        'Shake detected!',
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 1),
        margin: const EdgeInsets.all(12),
      );
    });

    _gyroSub ??= _sensors.gyroscopeStream.listen((event) {
      gyroX.value = event.x.clamp(-5.0, 5.0);
      gyroY.value = event.y.clamp(-5.0, 5.0);
    });
  }

  void pauseSensors() {
    _shakeSub?.cancel();
    _shakeSub = null;
    _gyroSub?.cancel();
    _gyroSub = null;
    _sensors.pause();
  }

  // ── CRUD ──────────────────────────────────────────────────────────────────

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

  Future<void> updateLog(LogModel log, String kwhInput) async {
    if (log.id == null) return;
    final error = await _repo.updateLog(log.id!, kwhInput);
    if (error != null) {
      Get.snackbar(
        'Update Failed',
        error,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
      );
      return;
    }

    await loadLogs();
    Get.snackbar(
      '✅ Log Updated',
      'Usage updated successfully.',
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 2),
    );
  }

  double get previewCost {
    final kwh = double.tryParse(kwhInput.value.trim()) ?? 0;
    return _repo.calculateCost(kwh);
  }

  // ── Navigation ────────────────────────────────────────────────────────────

  void goToNearestPln() => Get.toNamed('/nearest_pln');
}
