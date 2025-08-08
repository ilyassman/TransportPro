import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/available_reservation_model.dart';
import 'utils/dio_client.dart';

class AvailableReservationService {
  // Récupérer toutes les réservations disponibles
  Future<List<AvailableReservation>> getAvailableReservations() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token') ?? '';
    final dio = DioClient.create(token: token);

    try {
      final response = await dio.get('/api/reservations/available');
      return (response.data as List)
          .map((json) => AvailableReservation.fromJson(json))
          .toList();
    } on DioException catch (e) {
      print('Erreur lors de la récupération des réservations disponibles: ${e.message}');
      throw Exception('Erreur lors de la récupération des réservations disponibles');
    }
  }

  // Récupérer les réservations disponibles par statut
  Future<List<AvailableReservation>> getAvailableReservationsByStatus(String status) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token') ?? '';
    final dio = DioClient.create(token: token);

    try {
      print('🌐 Appel API: /api/reservations/available/status/$status');
      final response = await dio.get('/api/reservations/available/status/$status');
      print('📡 Réponse API reçue: ${response.data}');
      
      final List<AvailableReservation> reservations = (response.data as List)
          .map((json) => AvailableReservation.fromJson(json))
          .toList();
      
      print('📊 Réservations parsées: ${reservations.length}');
      return reservations;
    } on DioException catch (e) {
      print('❌ Erreur lors de la récupération des réservations par statut: ${e.message}');
      print('🔍 Détails de l\'erreur: ${e.response?.data}');
      throw Exception('Erreur lors de la récupération des réservations par statut');
    }
  }

  // Proposer pour une réservation (anciennement "accepter")
  Future<Map<String, dynamic>> proposeForReservation(int reservationId, {double? prixPropose}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token') ?? '';
    final dio = DioClient.create(token: token);

    try {
      print('Envoi de proposition pour la réservation $reservationId...');
      
      // Préparer le body avec le prix proposé si fourni
      Map<String, dynamic> body = {};
      if (prixPropose != null) {
        body['prixPropose'] = prixPropose;
        print('Prix proposé: $prixPropose');
      }
      
      final response = await dio.post('/api/reservations/$reservationId/accept', data: body);
      print('Proposition envoyée avec succès: ${response.data}');
      return response.data;
    } on DioException catch (e) {
      print('Erreur lors de l\'envoi de la proposition: ${e.message}');
      if (e.response?.data != null) {
        print('Détails de l\'erreur: ${e.response!.data}');
        throw Exception(e.response!.data.toString());
      }
      throw Exception('Erreur lors de l\'envoi de la proposition');
    }
  }
  
  // Méthodes pour les réservations du transporteur connecté
  Future<List<AvailableReservation>> getMyReservations() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token') ?? '';
    final dio = DioClient.create(token: token);

    try {
      final response = await dio.get('/api/reservations/my');
      final List data = response.data;
      return data.map((json) => AvailableReservation.fromJson(json)).toList();
    } on DioException catch (e) {
      print('Erreur lors de la récupération de mes réservations: ${e.message}');
      throw Exception('Erreur lors de la récupération de mes réservations');
    }
  }
  
  Future<List<AvailableReservation>> getMyReservationsByStatus(String status) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token') ?? '';
    final dio = DioClient.create(token: token);

    try {
      final response = await dio.get('/api/reservations/my/status/$status');
      final List data = response.data;
      return data.map((json) => AvailableReservation.fromJson(json)).toList();
    } on DioException catch (e) {
      print('Erreur lors de la récupération de mes réservations par statut: ${e.message}');
      throw Exception('Erreur lors de la récupération de mes réservations par statut');
    }
  }
  
  // Nouvelle méthode pour récupérer les réservations avec les informations du client
  Future<List<AvailableReservation>> getMyReservationsWithChargeurInfo(String status) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token') ?? '';
    final dio = DioClient.create(token: token);

    try {
      final response = await dio.get('/api/reservations/my/$status/with-chargeur');
      final List data = response.data;
      return data.map((json) => AvailableReservation.fromJson(json)).toList();
    } on DioException catch (e) {
      print('Erreur lors de la récupération de mes réservations avec info client: ${e.message}');
      throw Exception('Erreur lors de la récupération de mes réservations avec info client');
    }
  }
  
  // Récupérer toutes les réservations par statut (pas seulement les disponibles)
  Future<List<AvailableReservation>> getAllReservationsByStatus(String status) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token') ?? '';
    final dio = DioClient.create(token: token);

    try {
      print('🌐 Appel API: /api/reservations/all/status/$status');
      final response = await dio.get('/api/reservations/all/status/$status');
      print('📡 Réponse API reçue: ${response.data}');
      
      final List<AvailableReservation> reservations = (response.data as List)
          .map((json) => AvailableReservation.fromJson(json))
          .toList();
      
      print('📊 Réservations parsées: ${reservations.length}');
      return reservations;
    } on DioException catch (e) {
      print('❌ Erreur lors de la récupération de toutes les réservations par statut: ${e.message}');
      print('🔍 Détails de l\'erreur: ${e.response?.data}');
      throw Exception('Erreur lors de la récupération de toutes les réservations par statut');
    }
  }
  
  Future<Map<String, dynamic>> updateReservationStatus(int reservationId, String newStatus) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token') ?? '';
    final dio = DioClient.create(token: token);

    try {
      final response = await dio.put('/api/reservations/$reservationId/status?status=$newStatus');
      return response.data;
    } on DioException catch (e) {
      print('Erreur lors du changement de statut: ${e.message}');
      if (e.response?.data != null) {
        print('Détails de l\'erreur: ${e.response!.data}');
        throw Exception(e.response!.data.toString());
      }
      throw Exception('Erreur lors du changement de statut');
    }
  }
} 