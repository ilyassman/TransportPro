import 'package:dio/dio.dart';
import 'utils/dio_client.dart';
import '../models/user_model.dart';
import 'two_factor_service.dart';
class AuthService {
  final Dio _dio;
  final TwoFactorService _twoFactorService;

  AuthService() : _dio = DioClient.create(), _twoFactorService = TwoFactorService();

  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final response = await _dio.post(
        '/login',
        data: {
          'username': username,
          'password': password,
        },
      );
      
      // Vérifier si la 2FA est requise
      if (response.data['requires2FA'] == true) {
        return {
          'requires2FA': true,
          'username': username,
          'message': '2FA required',
        };
      }
      
      return response.data;
    } on DioException catch (e) {
      // Vérifier si le compte n'est pas activé
      if (e.response?.statusCode == 401 && e.response?.data['requiresActivation'] == true) {
        return {
          'requiresActivation': true,
          'username': username,
          'message': 'Account not activated',
        };
      }
      throw Exception('Erreur de connexion: $e');
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }

  /// Finaliser la connexion avec 2FA
  Future<Map<String, dynamic>> finalizeLoginWith2FA(String username, int code) async {
    try {
      return await _twoFactorService.finalizeLogin(username, code);
    } catch (e) {
      throw Exception('Erreur lors de la finalisation 2FA: $e');
    }
  }

  Future<String> VerifyCode(String username, String code) async {
    try {
      final response = await _dio.post(
        '/verify-reset-code',
        data: {
          'username': username,
          'code': code,
        },
      );
      
      return response.data.toString();
    } on DioException catch (e) {
      print('DioException dans VerifyCode: ${e.message}');
      print('Status code: ${e.response?.statusCode}');
      print('Response data: ${e.response?.data}');
      
      // Gestion spécifique des erreurs
      if (e.response?.statusCode == 401) {
        throw Exception('invalid_code');
      } else if (e.response?.statusCode == 404) {
        throw Exception('user_not_found');
      } else {
        throw Exception('verification_error');
      }
    } catch (e) {
      print('Erreur générale dans VerifyCode: $e');
      throw Exception('general_error');
    }
  }
 
  Future<String> sendResetCode(String username) async {
    try {
      final response = await _dio.post('/send-reset-code/$username');
      print('Send Reset Code Response: ${response.statusCode} - ${response.data}');
      
      if (response.statusCode == 200 && response.data != null) {
        return response.data.toString();
      } else {
        throw Exception('send_code_error');
      }
    } on DioException catch (e) {
      print('DioException dans sendResetCode: ${e.message}');
      print('Status code: ${e.response?.statusCode}');
      
      if (e.response?.statusCode == 404) {
        throw Exception('user_not_found');
      } else if (e.response?.statusCode == 403) {
        throw Exception('access_forbidden');
      } else {
        throw Exception('send_code_error');
      }
    } catch (e) {
      print('Erreur générale dans sendResetCode: $e');
      throw Exception('general_error');
    }
  }
  Future<void> updatepassword(UserModel user) async {
    try {
      print('=== DÉBUT UPDATE PASSWORD ===');
      print('Username: ${user.username}');
      print('Password: ${user.password}');
      
      // Utiliser Dio sans token pour cet endpoint
      print('URL: ${_dio.options.baseUrl}/userupdatePassword');
      print('Headers: ${_dio.options.headers}');
      
      final response = await _dio.put('/userupdatePassword', data: {
        'username': user.username,
        'password': user.password
      });
      
      print('=== RÉPONSE API SUCCÈS ===');
      print('Status Code: ${response.statusCode}');
      print('Response Data: ${response.data}');
      print('Response Headers: ${response.headers}');
      print('=== FIN UPDATE PASSWORD ===');
      
    } on DioException catch (e) {
      print('=== ERREUR DIO EXCEPTION ===');
      print('Message: ${e.message}');
      print('Type: ${e.type}');
      print('Status Code: ${e.response?.statusCode}');
      print('Response Data: ${e.response?.data}');
      print('Response Headers: ${e.response?.headers}');
      print('Request Data: ${e.requestOptions.data}');
      print('Request URL: ${e.requestOptions.uri}');
      print('Request Method: ${e.requestOptions.method}');
      print('=== FIN ERREUR DIO ===');
      
      if (e.response?.statusCode == 404) {
        throw Exception('user_not_found');
      } else if (e.response?.statusCode == 400) {
        throw Exception('invalid_password');
      } else {
        throw Exception('update_password_error');
      }
    } catch (e) {
      print('=== ERREUR GÉNÉRALE ===');
      print('Erreur: $e');
      print('Type d\'erreur: ${e.runtimeType}');
      print('=== FIN ERREUR GÉNÉRALE ===');
      throw Exception('general_error');
    }
  }

  /// Renvoyer l'email d'activation
  Future<Map<String, dynamic>> resendActivationEmail(String username) async {
    try {
      final response = await _dio.post(
        '/resend-activation',
        data: {
          'username': username,
        },
      );
      
      return response.data;
    } on DioException catch (e) {
      print('Erreur lors du renvoi de l\'email d\'activation: ${e.message}');
      throw Exception('Erreur lors du renvoi de l\'email d\'activation');
    } catch (e) {
      throw Exception('Erreur générale: $e');
    }
  }

  /// Vérifier si un compte est activé
  Future<Map<String, dynamic>> checkAccountActivation(String username) async {
    try {
      final response = await _dio.get('/check-activation/$username');
      return response.data;
    } on DioException catch (e) {
      print('Erreur lors de la vérification de l\'activation: ${e.message}');
      throw Exception('Erreur lors de la vérification de l\'activation');
    } catch (e) {
      throw Exception('Erreur générale: $e');
    }
  }
}