import 'package:dio/dio.dart';
import 'utils/dio_client.dart';

class SignupService {
  final Dio _dio;

  SignupService() : _dio = DioClient.create();

  Future<Map<String, dynamic>> signup({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String companyName,
    required String username,
    required String password,
    required String userType,
  }) async {
    try {
      // Préparer les données pour l'API
      final userData = {
        'username': username,
        'email': email,
        'password': password,
        // Ajouter les champs supplémentaires si l'API les supporte
        'firstName': firstName,
        'lastName': lastName,
        'phone': phone,
        'companyName': companyName,
        'userType': userType,
      };

      print('=== DÉBUT INSCRIPTION ===');
      print('URL: ${_dio.options.baseUrl}/user');
      print('Data: $userData');

      final response = await _dio.post('/user', data: userData);

      print('=== RÉPONSE API SUCCÈS ===');
      print('Status Code: ${response.statusCode}');
      print('Response Data: ${response.data}');
      print('=== FIN INSCRIPTION ===');

      return {
        'success': true,
        'user': response.data,
        'message': 'Compte créé avec succès',
      };

    } on DioException catch (e) {
      print('=== ERREUR DIO EXCEPTION ===');
      print('Message: ${e.message}');
      print('Type: ${e.type}');
      print('Status Code: ${e.response?.statusCode}');
      print('Response Data: ${e.response?.data}');
      print('Request Data: ${e.requestOptions.data}');
      print('Request URL: ${e.requestOptions.uri}');
      print('=== FIN ERREUR DIO ===');

      // Gestion spécifique des erreurs
      if (e.response?.statusCode == 400) {
        final responseData = e.response?.data;
        if (responseData != null) {
          if (responseData['error'] == 'username_already_exists') {
            throw Exception('username_already_exists');
          } else if (responseData['error'] == 'email_already_exists') {
            throw Exception('email_already_exists');
          } else if (responseData['error'] == 'invalid_data') {
            throw Exception('invalid_data');
          } else if (responseData['error'] == 'signup_error') {
            throw Exception('signup_error');
          }
        }
        throw Exception('invalid_data');
      } else if (e.response?.statusCode == 409) {
        throw Exception('user_already_exists');
      } else if (e.response?.statusCode == 422) {
        throw Exception('validation_error');
      } else {
        throw Exception('signup_error');
      }
    } catch (e) {
      print('=== ERREUR GÉNÉRALE ===');
      print('Erreur: $e');
      print('Type d\'erreur: ${e.runtimeType}');
      print('=== FIN ERREUR GÉNÉRALE ===');
      throw Exception('general_error');
    }
  }

  /// Vérifier si un nom d'utilisateur existe déjà
  Future<bool> checkUsernameAvailability(String username) async {
    try {
      // Cette fonction pourrait être implémentée si l'API le supporte
      // Pour l'instant, on retourne true (disponible)
      return true;
    } catch (e) {
      print('Erreur lors de la vérification du nom d\'utilisateur: $e');
      return false;
    }
  }

  /// Vérifier si un email existe déjà
  Future<bool> checkEmailAvailability(String email) async {
    try {
      // Cette fonction pourrait être implémentée si l'API le supporte
      // Pour l'instant, on retourne true (disponible)
      return true;
    } catch (e) {
      print('Erreur lors de la vérification de l\'email: $e');
      return false;
    }
  }
} 