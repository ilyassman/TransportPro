import 'package:dio/dio.dart';
import 'utils/dio_client.dart';

class TwoFactorService {
  final Dio _dio;

  TwoFactorService({String? token}) : _dio = DioClient.create(token: token);

  /// Activer la 2FA pour un utilisateur
  Future<Map<String, dynamic>> enableTwoFactor(String username) async {
    try {
      final response = await _dio.post(
        '/api/2fa/enable',
        queryParameters: {'username': username},
      );
      
      return response.data;
    } on DioException catch (e) {
      print('Erreur lors de l\'activation 2FA: ${e.message}');
      print('Status code: ${e.response?.statusCode}');
      print('Response data: ${e.response?.data}');
      throw Exception('Erreur lors de l\'activation 2FA');
    }
  }

  /// Vérifier le code TOTP pour finaliser l'activation
  Future<Map<String, dynamic>> verifyActivation(String username, int code) async {
    try {
      print('Envoi de la requête de vérification: username=$username, code=$code');
      final response = await _dio.post(
        '/api/2fa/verify-activation',
        data: {
          'username': username,
          'code': code,
        },
      );
      
      print('Réponse de vérification: ${response.data}');
      return response.data;
    } on DioException catch (e) {
      print('Erreur lors de la vérification 2FA: ${e.message}');
      print('Status code: ${e.response?.statusCode}');
      print('Response data: ${e.response?.data}');
      if (e.response?.statusCode == 400) {
        throw Exception('Code invalide');
      }
      throw Exception('Erreur lors de la vérification 2FA');
    }
  }

  /// Vérifier le code TOTP pour la connexion
  Future<Map<String, dynamic>> verifyLoginCode(String username, int code) async {
    try {
      final response = await _dio.post(
        '/api/2fa/verify-login',
        data: {
          'username': username,
          'code': code,
        },
      );
      
      return response.data;
    } on DioException catch (e) {
      print('Erreur lors de la vérification login 2FA: ${e.message}');
      if (e.response?.statusCode == 400) {
        throw Exception('Code invalide');
      }
      throw Exception('Erreur lors de la vérification login 2FA');
    }
  }

  /// Finaliser la connexion avec 2FA
  Future<Map<String, dynamic>> finalizeLogin(String username, int code) async {
    try {
      final response = await _dio.post(
        '/api/2fa/finalize-login',
        data: {
          'username': username,
          'code': code,
        },
      );
      
      return response.data;
    } on DioException catch (e) {
      print('Erreur lors de la finalisation login 2FA: ${e.message}');
      if (e.response?.statusCode == 400) {
        throw Exception('Code invalide');
      }
      throw Exception('Erreur lors de la finalisation login 2FA');
    }
  }

  /// Désactiver la 2FA
  Future<Map<String, dynamic>> disableTwoFactor(String username) async {
    try {
      final response = await _dio.post(
        '/api/2fa/disable',
        queryParameters: {'username': username},
      );
      
      return response.data;
    } on DioException catch (e) {
      print('Erreur lors de la désactivation 2FA: ${e.message}');
      throw Exception('Erreur lors de la désactivation 2FA');
    }
  }

  /// Obtenir le statut 2FA
  Future<Map<String, dynamic>> getTwoFactorStatus() async {
    try {
      final response = await _dio.get('/api/2fa/status');
      return response.data;
    } on DioException catch (e) {
      print('Erreur lors de la récupération du statut 2FA: ${e.message}');
      throw Exception('Erreur lors de la récupération du statut 2FA');
    }
  }

  /// Debug: Obtenir le code TOTP actuel
  Future<Map<String, dynamic>> debugTOTP(String username) async {
    try {
      final response = await _dio.get(
        '/api/2fa/debug-totp',
        queryParameters: {'username': username},
      );
      
      return response.data;
    } on DioException catch (e) {
      print('Erreur lors du debug TOTP: ${e.message}');
      throw Exception('Erreur lors du debug TOTP');
    }
  }
} 