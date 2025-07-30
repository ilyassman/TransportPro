import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/two_factor_service.dart';

class TwoFactorController extends GetxController {
  final TwoFactorService twoFactorService;
  
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  final RxString qrCodeUrl = ''.obs;
  final RxString secretKey = ''.obs;
  final RxBool isTwoFactorEnabled = false.obs;
  final RxBool isTwoFactorVerified = false.obs;
  final RxBool isVerifying = false.obs;

  // Contrôleurs pour les formulaires
  final formKey = GlobalKey<FormState>();
  final codeController = TextEditingController();

  TwoFactorController({required this.twoFactorService});

  @override
  void onInit() {
    super.onInit();
    // Récupérer le username depuis les arguments
    final args = Get.arguments as Map<String, dynamic>?;
    final username = args?['username'];
    
    if (username == null) {
      Get.snackbar(
        'Erreur',
        'Nom d\'utilisateur non fourni',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      Get.back();
    }
  }

  @override
  void onClose() {
    codeController.dispose();
    super.onClose();
  }

  /// Activer la 2FA
  Future<void> enableTwoFactor() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      
      final args = Get.arguments as Map<String, dynamic>?;
      final username = args?['username'];
      
      if (username == null) return;
      
      final response = await twoFactorService.enableTwoFactor(username);
      
      if (response['success'] == true) {
        qrCodeUrl.value = response['qrCodeUrl'] ?? '';
        secretKey.value = response['secretKey'] ?? '';
      } else {
        errorMessage.value = response['message'] ?? 'Erreur lors de l\'activation';
      }
    } catch (e) {
      errorMessage.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  /// Vérifier l'activation 2FA
  Future<void> verifyCode() async {
    if (!formKey.currentState!.validate()) return;

    try {
      isVerifying.value = true;
      errorMessage.value = '';
      
      final args = Get.arguments as Map<String, dynamic>?;
      final username = args?['username'];
      
      if (username == null) return;
      
      print('Contrôleur: Vérification avec username=$username, code=${codeController.text}');
      final code = int.parse(codeController.text);
      final response = await twoFactorService.verifyActivation(username, code);
      
      print('Contrôleur: Réponse reçue: $response');
      
      if (response['success'] == true) {
        isTwoFactorVerified.value = true;
        // Afficher une boîte de dialogue de succès
        Get.dialog(
          AlertDialog(
            title: const Text('Succès'),
            content: const Text('2FA activée avec succès'),
            actions: [
              TextButton(
                onPressed: () {
                  Get.back(); // Fermer la boîte de dialogue
                  Get.back(); // Retourner à l'écran précédent
                },
                child: const Text('Confirmer'),
              ),
            ],
          ),
        );
      } else {
        errorMessage.value = response['message'] ?? 'Code invalide';
        Get.snackbar(
          'Erreur',
          errorMessage.value,
          backgroundColor: Colors.red,
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );
      }
    } catch (e) {
      print('Contrôleur: Erreur: $e');
      errorMessage.value = e.toString();
      Get.snackbar(
        'Erreur',
        errorMessage.value,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    } finally {
      isVerifying.value = false;
    }
  }

  /// Vérifier le code TOTP pour la connexion
  Future<bool> verifyLoginCode(String username, int code) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      
      final response = await twoFactorService.verifyLoginCode(username, code);
      
      if (response['success'] == true) {
        return true;
      } else {
        errorMessage.value = response['message'] ?? 'Code invalide';
        return false;
      }
    } catch (e) {
      errorMessage.value = e.toString();
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Finaliser la connexion avec 2FA
  Future<Map<String, dynamic>?> finalizeLogin(String username, int code) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      
      final response = await twoFactorService.finalizeLogin(username, code);
      
      if (response['access_token'] != null) {
        return response;
      } else {
        errorMessage.value = 'Erreur lors de la finalisation';
        return null;
      }
    } catch (e) {
      errorMessage.value = e.toString();
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  /// Désactiver la 2FA avec vérification du code
  Future<void> disableTwoFactorWithVerification() async {
    try {
      print('=== DÉBUT DÉSACTIVATION 2FA AVEC VÉRIFICATION ===');
      isVerifying.value = true;
      errorMessage.value = '';
      
      final args = Get.arguments as Map<String, dynamic>?;
      final username = args?['username'];
      
      print('Username depuis args: $username');
      print('Code depuis controller: ${codeController.text}');
      
      if (username == null) {
        print('Erreur: Username null');
        errorMessage.value = 'Nom d\'utilisateur manquant';
        return;
      }
      
      if (codeController.text.isEmpty) {
        print('Erreur: Code vide');
        errorMessage.value = 'Code requis';
        return;
      }
      
      final code = int.parse(codeController.text);
      print('Code parsé: $code');
      
      final response = await twoFactorService.disableTwoFactorWithVerification(username, code);
      print('Réponse du serveur: $response');
      
      if (response['success'] == true) {
        print('Désactivation réussie');
        
        // Retourner au profil
        Get.back(); // Fermer la vue de désactivation
        
        // Afficher le message de succès
        Get.snackbar(
          'Succès',
          '2FA désactivée avec succès',
          backgroundColor: const Color(0xFF10B981),
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
          snackPosition: SnackPosition.TOP,
          margin: const EdgeInsets.all(16),
          borderRadius: 8,
          icon: const Icon(
            Icons.check_circle,
            color: Colors.white,
          ),
        );
        
      } else {
        print('Erreur de désactivation: ${response['message']}');
        errorMessage.value = response['message'] ?? 'Erreur lors de la désactivation';
      }
    } catch (e) {
      print('=== ERREUR DÉSACTIVATION 2FA ===');
      print('Erreur: $e');
      errorMessage.value = e.toString();
    } finally {
      isVerifying.value = false;
      print('=== FIN DÉSACTIVATION 2FA AVEC VÉRIFICATION ===');
    }
  }

  /// Désactiver la 2FA sans vérification (pour les cas spéciaux)
  Future<void> disableTwoFactor() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      
      final args = Get.arguments as Map<String, dynamic>?;
      final username = args?['username'];
      
      if (username == null) return;
      
      final response = await twoFactorService.disableTwoFactor(username);
      
      if (response['success'] == true) {
        Get.snackbar(
          'Succès',
          '2FA désactivée avec succès',
          backgroundColor: const Color(0xFF10B981),
          colorText: Colors.white,
        );
        Get.back();
      } else {
        errorMessage.value = response['message'] ?? 'Erreur lors de la désactivation';
      }
    } catch (e) {
      errorMessage.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  /// Obtenir le statut 2FA
  Future<void> getTwoFactorStatus() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      
      final response = await twoFactorService.getTwoFactorStatus();
      
      if (response['success'] == true) {
        isTwoFactorEnabled.value = true;
        isTwoFactorVerified.value = true;
      } else {
        isTwoFactorEnabled.value = false;
        isTwoFactorVerified.value = false;
      }
    } catch (e) {
      errorMessage.value = e.toString();
      isTwoFactorEnabled.value = false;
      isTwoFactorVerified.value = false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Debug: Obtenir le code TOTP actuel
  Future<int?> debugTOTP(String username) async {
    try {
      final response = await twoFactorService.debugTOTP(username);
      return response['currentTOTP'] as int?;
    } catch (e) {
      errorMessage.value = e.toString();
      return null;
    }
  }

  /// Réinitialiser les valeurs
  void reset() {
    isLoading.value = false;
    errorMessage.value = '';
    qrCodeUrl.value = '';
    secretKey.value = '';
    isTwoFactorEnabled.value = false;
    isTwoFactorVerified.value = false;
    isVerifying.value = false;
  }
} 