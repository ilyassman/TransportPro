import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/reservation_model.dart';
import 'utils/dio_client.dart';

class ReservationService {
  Future<void> reserver(ReservationModel reservation) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token') ?? '';
    final dio = DioClient.create(token: token);

    try {
      final response = await dio.post(
        '/api/reservations',
        data: reservation.toJson(),
      );
      // Tu peux traiter la réponse ici si besoin
    } on DioException catch (e) {
      print('Erreur lors de la réservation: ${e.message}');
      throw Exception('Erreur lors de la réservation');
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
} 