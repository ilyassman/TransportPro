import 'package:flutter_application_1/controllers/profile_controller.dart';
import 'package:flutter_application_1/services/profile_service.dart';
import 'package:get/get.dart';

class ProfileBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ProfileService>(() => ProfileService());
    Get.lazyPut<ProfileController>(() => ProfileController(profileService: Get.find<ProfileService>()));
  }
} 