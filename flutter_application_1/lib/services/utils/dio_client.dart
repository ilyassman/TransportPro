import 'package:dio/dio.dart';

class DioClient {
  // Création de Dio avec ou sans token
  static Dio create({String? token}) {
    final headers = {
      'Content-Type': 'application/json',
    };

    // Si token est fourni, ajouter Authorization
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    return Dio(BaseOptions(
      baseUrl: 'http://192.168.100.19:8082',
      connectTimeout: Duration(seconds: 5),
      receiveTimeout: Duration(seconds: 5),
      headers: headers,
    ));
  }
}
