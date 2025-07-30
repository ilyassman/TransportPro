import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/reservation_model.dart';
import 'utils/dio_client.dart';

class ReservationService {
  Future<Map<String, dynamic>> reserver(ReservationModel reservation) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token') ?? '';
    final dio = DioClient.create(token: token);

    try {
      final response = await dio.post(
        '/api/reservations',
        data: reservation.toJson(),
      );
      return response.data;
    } on DioException catch (e) {
      print('Erreur lors de la réservation: ${e.message}');
      throw Exception('Erreur lors de la réservation');
    }
  }

  Future<void> updateReservation(int reservationId, int camionId, bool isIgnore) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token') ?? '';
    final dio = DioClient.create(token: token);

    try {
      await dio.put(
        '/api/reservations/$reservationId/camion/$camionId/$isIgnore',
      );
    } on DioException catch (e) {
      print('Erreur lors de la mise à jour de la réservation: ${e.message}');
      throw Exception(e.response?.data ?? 'Erreur lors de la mise à jour de la réservation');
    }
  }

  // Récupérer toutes les réservations de l'utilisateur
  Future<List<Map<String, dynamic>>> getUserReservations() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token') ?? '';
    final dio = DioClient.create(token: token);

    try {
      final response = await dio.get('/api/reservations');
      return List<Map<String, dynamic>>.from(response.data);
    } on DioException catch (e) {
      print('Erreur lors de la récupération des réservations: ${e.message}');
      throw Exception('Erreur lors de la récupération des réservations');
    }
  }

  // Récupérer les réservations par statut
  Future<List<Map<String, dynamic>>> getUserReservationsByStatus(String status) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token') ?? '';
    final dio = DioClient.create(token: token);

    try {
      final response = await dio.get('/api/reservations/status/$status');
      return List<Map<String, dynamic>>.from(response.data);
    } on DioException catch (e) {
      print('Erreur lors de la récupération des réservations par statut: ${e.message}');
      throw Exception('Erreur lors de la récupération des réservations par statut');
    }
  }
  
  // Récupérer les statistiques du transporteur
  Future<Map<String, dynamic>> getTransporteurStatistics() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token') ?? '';
    final dio = DioClient.create(token: token);

    try {
      final response = await dio.get('/api/reservations/my/statistics');
      return Map<String, dynamic>.from(response.data);
    } on DioException catch (e) {
      print('Erreur lors de la récupération des statistiques: ${e.message}');
      throw Exception('Erreur lors de la récupération des statistiques');
    }
  }

  // Récupérer les récapitulatifs de réservations
  Future<List<Map<String, dynamic>>> getReservationRecapitulatif() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token') ?? '';
    final dio = DioClient.create(token: token);

    try {
      final response = await dio.get('/api/reservations/recapitulatif');
      return List<Map<String, dynamic>>.from(response.data);
    } on DioException catch (e) {
      print('Erreur lors de la récupération des récapitulatifs: ${e.message}');
      throw Exception('Erreur lors de la récupération des récapitulatifs');
    }
  }
} 