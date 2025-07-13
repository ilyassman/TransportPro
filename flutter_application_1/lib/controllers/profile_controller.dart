import 'package:get/get.dart';
import '../services/profile_service.dart';

class ProfileController extends GetxController {
  final ProfileService profileService;
  
  var isLoading = false.obs;
  var userProfile = <String, dynamic>{}.obs;
  var currentUsername = ''.obs;
  var isTwoFactorEnabled = false.obs;

  ProfileController({required this.profileService});

  @override
  void onInit() {
    super.onInit();
    loadProfile();
  }

  Future<void> loadProfile() async {
    try {
      isLoading(true);
      final profile = await profileService.getProfile();
      userProfile.value = profile;
      currentUsername.value = profile['username'] ?? '';
      isTwoFactorEnabled.value = profile['twoFactorEnabled'] == true && profile['twoFactorVerified'] == true;
    } catch (e) {
      print('Erreur lors du chargement du profil: $e');
    } finally {
      isLoading(false);
    }
  }

  Future<String?> getCurrentUsername() async {
    try {
      return await profileService.getCurrentUsername();
    } catch (e) {
      print('Erreur lors de la récupération du username: $e');
      return null;
    }
  }

  Future<bool> checkTwoFactorStatus() async {
    try {
      return await profileService.isTwoFactorEnabled();
    } catch (e) {
      print('Erreur lors de la vérification du statut 2FA: $e');
      return false;
    }
  }
} 