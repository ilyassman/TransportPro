import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../models/auth_model.dart';
import '../views/user_view.dart';
import '../services/utils/user_binding.dart';
import '../models/user_model.dart';

class AuthController extends GetxController {
  final AuthService authService = AuthService();
  var isLoading = false.obs;

  Future<void> login(String username, String password) async {
    try {
      isLoading(true);
      
      final response = await authService.login(username, password);
      
      // Vérifier si l'activation est requise
      if (response['requiresActivation'] == true) {
        // Rediriger vers la page d'activation
        Get.toNamed('/account-activation', arguments: {'username': username});
        return;
      }
      
      // Vérifier si la 2FA est requise
      if (response['requires2FA'] == true) {
        // Stocker le username pour la 2FA
        Get.toNamed('/two-factor-login', arguments: {'username': username});
        return;
      }
      
      final authResponse = AuthResponse.fromJson(response);
      
      // Sauvegarder les tokens
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('access_token', authResponse.accessToken);
      await prefs.setString('refresh_token', authResponse.refreshToken);
      
      // Rediriger vers la page users
      Get.offAll(
        () => UserView(),
         binding: UserBinding(authResponse.accessToken),
      );
      
    } catch (e) {
      rethrow;
    } finally {
      isLoading(false);
    }
  }

  Future<String?> verfierCode(String username, String code) async {
    try {
      isLoading(true);
      
      final response = await authService.VerifyCode(username, code);
      return response;
    } on Exception catch (e) {
      print('Exception dans verfierCode: $e');
      rethrow; // Relancer l'exception pour que la UI puisse la gérer
    } finally {
      isLoading(false);
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
    Get.offAllNamed('/login');
  } 

  Future<String?> forgotPassword(String username) async {
    try {
      isLoading(true);
      final email = await authService.sendResetCode(username);
      return email;
    } catch (e) {
      rethrow;
    } finally {
      isLoading(false);
    }
  }
   Future<void> updatePassword(UserModel user) async {
    try {
      print('=== DÉBUT AUTH CONTROLLER UPDATE PASSWORD ===');
      print('Username reçu: ${user.username}');
      isLoading(true);
      
      await authService.updatepassword(user);
      
      print('=== SUCCÈS AUTH CONTROLLER ===');
      print('Mot de passe mis à jour avec succès');
      
    } catch (e) {
      print('=== ERREUR AUTH CONTROLLER ===');
      print("Erreur update pass : $e");
      print('Type d\'erreur: ${e.runtimeType}');
      rethrow; // Relancer l'exception pour que la UI puisse la gérer
    } finally {
      isLoading(false);
      print('=== FIN AUTH CONTROLLER UPDATE PASSWORD ===');
    }
  }

  /// Finaliser la connexion avec 2FA
  Future<void> finalizeLoginWith2FA(String username, int code) async {
    try {
      isLoading(true);
      
      final response = await authService.finalizeLoginWith2FA(username, code);
      
      // Sauvegarder les tokens
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('access_token', response['access_token']);
      await prefs.setString('refresh_token', response['refresh_token']);
      
      // Rediriger vers la page users
      Get.offAll(
        () => UserView(),
         binding: UserBinding(response['access_token']),
      );
      
    } catch (e) {
      rethrow;
    } finally {
      isLoading(false);
    }
  }

  /// Renvoyer l'email d'activation
  Future<void> resendActivationEmail(String username) async {
    try {
      isLoading(true);
      await authService.resendActivationEmail(username);
    } catch (e) {
      rethrow;
    } finally {
      isLoading(false);
    }
  }

  /// Vérifier si un compte est activé
  Future<bool> checkAccountActivation(String username) async {
    try {
      isLoading(true);
      final response = await authService.checkAccountActivation(username);
      return response['isActivated'] ?? false;
    } catch (e) {
      rethrow;
    } finally {
      isLoading(false);
    }
  }
}