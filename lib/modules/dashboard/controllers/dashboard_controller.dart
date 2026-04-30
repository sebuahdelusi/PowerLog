import 'package:get/get.dart';

class DashboardController extends GetxController {
  final currentIndex = 0.obs;

  void changePage(int index) {
    if (index == 3) {
      // Logout — handled separately
      _handleLogout();
      return;
    }
    currentIndex.value = index;
  }

  void _handleLogout() {
    Get.defaultDialog(
      title: 'Logout',
      middleText: 'Are you sure you want to logout?',
      textConfirm: 'Yes',
      textCancel: 'Cancel',
      onConfirm: () {
        Get.back(); // close dialog
        Get.offAllNamed('/login');
      },
    );
  }
}
