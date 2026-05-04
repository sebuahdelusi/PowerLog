import 'package:get/get.dart';
import 'package:powerlog/data/repositories/auth_repository.dart';

class DashboardController extends GetxController {
  final currentIndex = 0.obs;
  final _repo = AuthRepository();

  void changePage(int index) {
    if (index == 5) {
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
      onConfirm: () async {
        await _repo.logout();
        Get.offAllNamed('/login');
      },
    );
  }
}
