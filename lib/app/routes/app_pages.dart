import 'package:get/get.dart';
import '../../modules/auth/views/login_view.dart';
import '../../modules/auth/bindings/auth_binding.dart';
import '../../modules/splash/views/splash_view.dart';
import '../../modules/splash/bindings/splash_binding.dart';
import '../../modules/dashboard/views/dashboard_view.dart';
import '../../modules/dashboard/bindings/dashboard_binding.dart';
import '../../modules/home/views/home_view.dart';
import '../../modules/home/bindings/home_binding.dart';
import '../../modules/profile/views/profile_view.dart';
import '../../modules/profile/bindings/profile_binding.dart';
import '../../modules/feedback/views/feedback_view.dart';
import '../../modules/feedback/bindings/feedback_binding.dart';

part 'app_routes.dart';

class AppPages {
  static const initial = Routes.splash;

  static final routes = [
    GetPage(
      name: Routes.splash,
      page: () => const SplashView(),
      binding: SplashBinding(),
    ),
    GetPage(
      name: Routes.login,
      page: () => const LoginView(),
      binding: AuthBinding(),
    ),
    GetPage(
      name: Routes.dashboard,
      page: () => const DashboardView(),
      binding: DashboardBinding(),
    ),
    GetPage(
      name: Routes.home,
      page: () => const HomeView(),
      binding: HomeBinding(),
    ),
    GetPage(
      name: Routes.profile,
      page: () => const ProfileView(),
      binding: ProfileBinding(),
    ),
    GetPage(
      name: Routes.feedback,
      page: () => const FeedbackView(),
      binding: FeedbackBinding(),
    ),
  ];
}
