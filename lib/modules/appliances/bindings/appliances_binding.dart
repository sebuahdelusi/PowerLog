import 'package:get/get.dart';
import '../controllers/appliances_controller.dart';

class AppliancesBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => AppliancesController());
  }
}
