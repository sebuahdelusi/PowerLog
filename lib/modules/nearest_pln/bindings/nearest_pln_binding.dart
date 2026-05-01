import 'package:get/get.dart';
import '../controllers/nearest_pln_controller.dart';

class NearestPlnBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => NearestPlnController());
  }
}
