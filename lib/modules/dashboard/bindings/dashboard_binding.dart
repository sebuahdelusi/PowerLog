import 'package:get/get.dart';
import '../controllers/dashboard_controller.dart';
import '../../home/bindings/home_binding.dart';
import '../../analytics/bindings/analytics_binding.dart';
import '../../appliances/bindings/appliances_binding.dart';
import '../../profile/bindings/profile_binding.dart';
import '../../feedback/bindings/feedback_binding.dart';

class DashboardBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => DashboardController());
    HomeBinding().dependencies();
    AnalyticsBinding().dependencies();
    AppliancesBinding().dependencies();
    ProfileBinding().dependencies();
    FeedbackBinding().dependencies();
  }
}
