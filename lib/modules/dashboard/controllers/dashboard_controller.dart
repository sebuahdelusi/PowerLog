import 'package:get/get.dart';
import 'package:powerlog/data/repositories/auth_repository.dart';
import '../../home/controllers/home_controller.dart';

class DashboardController extends GetxController {
  final currentIndex = 0.obs;
  final _repo = AuthRepository();

  void changePage(int index) {
    if (index == 5) {
      _handleLogout();
      return;
    }
    _handleHomeSensors(index);
    currentIndex.value = index;
  }

  void _handleHomeSensors(int index) {
    if (!Get.isRegistered<HomeController>()) return;
    final home = Get.find<HomeController>();
    if (index == 0) {
      home.resumeSensors();
      home.loadAppliances();
    } else {
      home.pauseSensors();
    }
  }

  void _handleLogout() {
    Get.defaultDialog(
      title: 'Logout',
      middleText: 'Are you sure you want to logout?',
      textConfirm: 'Yes',
      textCancel: 'Cancel',
      onConfirm: () async {
        if (Get.isRegistered<HomeController>()) {
          Get.find<HomeController>().pauseSensors();
        }
        await _repo.logout();
        Get.offAllNamed('/login');
      },
    );
  }
}
