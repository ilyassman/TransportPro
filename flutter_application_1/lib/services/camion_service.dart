import 'package:dio/dio.dart';
import '../models/camion_model.dart';
import 'utils/dio_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CamionService {
  Future<Dio> _getDioWithToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token') ?? '';
    return DioClient.create(token: token);
  }

  Future<List<Camion>> getCamionsProches({
    required double latitude,
    required double longitude,
    double rayonKm = 10,
  }) async {
    try {
      final dio = await _getDioWithToken();
      final response = await dio.get(
        '/api/camions/proches',
        queryParameters: {
          'latitude': latitude,
          'longitude': longitude,
          'rayonKm': rayonKm,
        },
      );
      final List data = response.data;
      return data.map((json) => Camion.fromJson(json)).toList();
    } catch (e) {
      print('Erreur getCamionsProches: $e');
      rethrow;
    }
  }

  Future<Camion?> getCamionById(int id) async {
    try {
      final dio = await _getDioWithToken();
      final response = await dio.get('/api/camions/$id');
      if (response.statusCode == 200) {
        return Camion.fromJson(response.data);
      }
      return null;
    } catch (e) {
      print('Erreur getCamionById: $e');
      return null;
    }
  }
} 