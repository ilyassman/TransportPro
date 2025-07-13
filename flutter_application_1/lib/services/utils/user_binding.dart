import 'package:flutter_application_1/controllers/user_controller.dart';
import 'package:flutter_application_1/services/user_service.dart';
import 'package:get/get.dart';

class UserBinding extends Bindings {
  final String token;
  UserBinding(this.token);

  @override
  void dependencies() {
        print('Token utilisé pour UserService: $token'); // Ajoute ce print

    Get.lazyPut<UserService>(() => UserService(token: token));
    Get.lazyPut<UserController>(() => UserController(userService: Get.find<UserService>()));
  }
}