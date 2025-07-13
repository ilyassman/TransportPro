import 'package:flutter_application_1/controllers/two_factor_controller.dart';
import 'package:flutter_application_1/services/two_factor_service.dart';
import 'package:get/get.dart';

class TwoFactorBinding extends Bindings {
  final String token;
  TwoFactorBinding(this.token);

  @override
  void dependencies() {
    print('Token utilisé pour TwoFactorService: $token');
    Get.lazyPut<TwoFactorService>(() => TwoFactorService(token: token));
    Get.lazyPut<TwoFactorController>(() => TwoFactorController(twoFactorService: Get.find<TwoFactorService>()));
  }
} 