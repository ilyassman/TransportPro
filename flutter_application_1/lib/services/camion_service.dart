import 'package:dio/dio.dart';

import '../models/camion_model.dart';
import 'utils/dio_client.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';

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

  Future<Camion?> getCamionByTransporteur(int transporteurId) async {
    try {
      final dio = await _getDioWithToken();
      final response = await dio.get('/api/camions/transporteur/$transporteurId');
      if (response.statusCode == 200) {
        return Camion.fromJson(response.data);
      }
      return null;
    } catch (e) {
      print('Erreur getCamionByTransporteur: $e');
      return null;
    }
  }
  
  Future<Camion?> getMyCamion() async {
    try {
      final dio = await _getDioWithToken();
      final response = await dio.get('/api/camions/my');
      if (response.statusCode == 200) {
        return Camion.fromJson(response.data);
      }
      return null;
    } catch (e) {
      print('Erreur getMyCamion: $e');
      return null;
    }
  }

  Future<Camion?> createCamion(Map<String, dynamic> camionData) async {
    try {
      final dio = await _getDioWithToken();
      final response = await dio.post('/api/camions', data: camionData);
      if (response.statusCode == 200) {
        return Camion.fromJson(response.data);
      }
      return null;
    } catch (e) {
      print('Erreur createCamion: $e');
      return null;
    }
  }

  Future<Camion?> updateCamion(int camionId, Map<String, dynamic> camionData) async {
    try {
      final dio = await _getDioWithToken();
      print('Tentative de mise à jour du camion $camionId avec les données: $camionData');
      
      final response = await dio.put('/api/camions/$camionId', data: camionData);
      print('Réponse du serveur: ${response.statusCode} - ${response.data}');
      
      if (response.statusCode == 200) {
        return Camion.fromJson(response.data);
      }
      return null;
    } catch (e) {
      print('Erreur updateCamion: $e');
      if (e is DioException) {
        print('DioException details: ${e.response?.statusCode} - ${e.response?.data}');
      }
      return null;
    }
  }
  
  Future<bool> resetCamionAvailability(int camionId) async {
    try {
      final dio = await _getDioWithToken();
      final response = await dio.put('/api/camions/$camionId/reset-availability');
      return response.statusCode == 200;
    } catch (e) {
      print('Erreur resetCamionAvailability: $e');
      return false;
    }
  }
  
  Future<bool> resetMyCamionAvailability() async {
    try {
      final dio = await _getDioWithToken();
      final response = await dio.put('/api/camions/my/reset-availability');
      return response.statusCode == 200;
    } catch (e) {
      print('Erreur resetMyCamionAvailability: $e');
      return false;
    }
  }
  
  Future<Map<String, dynamic>?> getCamionAvailability(int camionId) async {
    try {
      final dio = await _getDioWithToken();
      final response = await dio.get('/api/camions/$camionId/availability');
      if (response.statusCode == 200) {
        return response.data;
      }
      return null;
    } catch (e) {
      print('Erreur getCamionAvailability: $e');
      return null;
    }
  }
} 