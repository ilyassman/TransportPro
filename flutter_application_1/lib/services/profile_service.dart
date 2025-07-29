import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'utils/dio_client.dart';

class ProfileService {
  /// Récupérer les informations du profil utilisateur
  Future<Map<String, dynamic>> getProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token') ?? '';
    final dio = DioClient.create(token: token);
    try {
      print('Token utilisé pour ProfileService:');
      print(token);
      print('Headers envoyés:');
      print(dio.options.headers);
      final response = await dio.get('/profil');
      print('Réponse API profil:');
      print('Status code: ${response.statusCode}');
      print('Data: ${response.data}');
      return response.data;
    } on DioException catch (e) {
      print('Erreur lors de la récupération du profil: ${e.message}');
      print('Status code: ${e.response?.statusCode}');
      print('Response data: ${e.response?.data}');
      throw Exception('Erreur lors de la récupération du profil');
    }
  }

  /// Récupérer le username de l'utilisateur connecté
  Future<String?> getCurrentUsername() async {
    try {
      final profile = await getProfile();
      return profile['username'] as String?;
    } catch (e) {
      print('Erreur lors de la récupération du username: $e');
      return null;
    }
  }

  /// Récupérer le statut 2FA de l'utilisateur connecté
  Future<bool> isTwoFactorEnabled() async {
    try {
      final profile = await getProfile();
      return profile['twoFactorEnabled'] == true && profile['twoFactorVerified'] == true;
    } catch (e) {
      print('Erreur lors de la récupération du statut 2FA: $e');
      return false;
    }
  }

  /// Mettre à jour les informations du profil
  Future<Map<String, dynamic>> updateProfile({
    String? firstName,
    String? lastName,
    String? phone,
    String? companyName,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token') ?? '';
    final dio = DioClient.create(token: token);
    
    try {
      print('=== DÉBUT MISE À JOUR PROFIL ===');
      print('Token: $token');
      
      final updateData = <String, dynamic>{};
      if (firstName != null) updateData['firstName'] = firstName;
      if (lastName != null) updateData['lastName'] = lastName;
      if (phone != null) updateData['phone'] = phone;
      if (companyName != null) updateData['companyName'] = companyName;
      
      print('Données à mettre à jour: $updateData');
      
      final response = await dio.put('/update-profile', data: updateData);
      
      print('=== RÉPONSE API SUCCÈS ===');
      print('Status code: ${response.statusCode}');
      print('Data: ${response.data}');
      
      return response.data;
    } on DioException catch (e) {
      print('=== ERREUR DIO MISE À JOUR PROFIL ===');
      print('Message: ${e.message}');
      print('Status code: ${e.response?.statusCode}');
      print('Response data: ${e.response?.data}');
      
      if (e.response?.statusCode == 400) {
        final errorData = e.response?.data;
        if (errorData != null && errorData['message'] != null) {
          throw Exception(errorData['message']);
        }
        throw Exception('Erreur lors de la mise à jour du profil');
      }
      throw Exception('Erreur lors de la mise à jour du profil: ${e.message}');
    } catch (e) {
      print('=== ERREUR GÉNÉRALE MISE À JOUR PROFIL ===');
      print('Erreur: $e');
      throw Exception('Erreur lors de la mise à jour du profil: $e');
    }
  }
} 