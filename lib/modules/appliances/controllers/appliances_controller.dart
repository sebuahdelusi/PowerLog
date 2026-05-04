import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:powerlog/data/models/appliance_model.dart';
import 'package:powerlog/data/repositories/appliance_repository.dart';

class AppliancesController extends GetxController {
  final _repo = ApplianceRepository();

  final appliances = <ApplianceModel>[].obs;
  final isLoading = false.obs;

  final nameCtrl = TextEditingController();
  final wattCtrl = TextEditingController();
  final hoursCtrl = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    loadAppliances();
  }

  @override
  void onClose() {
    nameCtrl.dispose();
    wattCtrl.dispose();
    hoursCtrl.dispose();
    super.onClose();
  }

  Future<void> loadAppliances() async {
    isLoading.value = true;
    appliances.value = await _repo.fetchAllAppliances();
    isLoading.value = false;
  }

  Future<void> addAppliance() async {
    try {
      await _repo.addAppliance(nameCtrl.text, wattCtrl.text, hoursCtrl.text);
      nameCtrl.clear();
      wattCtrl.clear();
      hoursCtrl.clear();
      Get.back(); // close dialog
      await loadAppliances();
      Get.snackbar('Success', 'Appliance added successfully',
          snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar('Error', e.toString(),
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withValues(alpha: 0.8),
          colorText: Colors.white);
    }
  }

  Future<void> deleteAppliance(int id) async {
    await _repo.deleteAppliance(id);
    await loadAppliances();
  }

  double get totalMonthlyCost {
    return appliances.fold(0.0, (sum, item) => sum + _repo.calculateMonthlyCost(item));
  }

  double getMonthlyCost(ApplianceModel appliance) {
    return _repo.calculateMonthlyCost(appliance);
  }
}
