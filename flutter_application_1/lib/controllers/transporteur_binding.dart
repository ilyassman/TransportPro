import 'package:get/get.dart';
import 'transporteur_controller.dart';

class TransporteurBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<TransporteurController>(TransporteurController());
  }
} 