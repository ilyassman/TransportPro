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
} 