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

  @override
  void onInit() {
    super.onInit();
    kwhCtrl.addListener(() => kwhInput.value = kwhCtrl.text);
    _initSensors();
    loadLogs();
  }

  @override
  void onClose() {
    kwhCtrl.dispose();
    _shakeSub?.cancel();
    _gyroSub?.cancel();
    _sensors.dispose();
    super.onClose();
  }

  // ── Sensor init ───────────────────────────────────────────────────────────

  Future<void> _initSensors() async {
    await _sensors.init();

    // Listen for shake events (sensor toggles torch internally)
    _shakeSub = _sensors.onShake.listen((_) {
      isTorchOn.value = _sensors.isTorchOn;
      Get.snackbar(
        isTorchOn.value ? '🔦 Torch ON' : '🔦 Torch OFF',
        'Shake detected!',
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 1),
        margin: const EdgeInsets.all(12),
      );
    });

    // Listen for gyroscope events for tilt UI effect
    _gyroSub = _sensors.gyroscopeStream.listen((event) {
      gyroX.value = event.x.clamp(-5.0, 5.0);
      gyroY.value = event.y.clamp(-5.0, 5.0);
    });
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

  double get previewCost {
    final kwh = double.tryParse(kwhInput.value.trim()) ?? 0;
    return _repo.calculateCost(kwh);
  }

  // ── Navigation ────────────────────────────────────────────────────────────

  void goToNearestPln() => Get.toNamed('/nearest_pln');
}
