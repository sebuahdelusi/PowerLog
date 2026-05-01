import 'package:get/get.dart';
import 'package:powerlog/data/repositories/auth_repository.dart';

class SplashController extends GetxController {
  final _repo = AuthRepository();

  @override
  void onReady() {
    super.onReady();
    _checkSession();
  }

  Future<void> _checkSession() async {
    // Brief delay to show splash branding
    await Future.delayed(const Duration(milliseconds: 1800));

    try {
      final hasSession = await _repo.hasActiveSession();
      if (hasSession) {
        Get.offAllNamed('/dashboard');
      } else {
        Get.offAllNamed('/login');
      }
    } catch (_) {
      Get.offAllNamed('/login');
    }
  }
}
