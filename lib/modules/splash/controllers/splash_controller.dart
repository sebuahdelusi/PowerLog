import 'package:get/get.dart';
import 'package:powerlog/data/repositories/auth_repository.dart';
import 'package:powerlog/services/session_service.dart';

class SplashController extends GetxController {
  final _repo = AuthRepository();
  final _session = SessionService();

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
        // Restore cached username for data isolation
        final username = await _session.getSessionUsername();
        if (username != null) {
          // Trigger saveSession to set the cached username
          await _session.saveSession(username);
        }
        Get.offAllNamed('/dashboard');
      } else {
        Get.offAllNamed('/login');
      }
    } catch (_) {
      Get.offAllNamed('/login');
    }
  }
}
