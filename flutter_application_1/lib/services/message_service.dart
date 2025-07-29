import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/message_model.dart';
import 'utils/dio_client.dart';

class MessageService {
  
  // Envoyer un message
  Future<MessageModel> envoyerMessage(String contenu, int destinataireId, int reservationId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token') ?? '';
    final dio = DioClient.create(token: token);

    try {
      final response = await dio.post('/api/messages/send', data: {
        'contenu': contenu,
        'destinataireId': destinataireId,
        'reservationId': reservationId,
      });
      
      return MessageModel.fromJson(response.data);
    } on DioException catch (e) {
      print('Erreur lors de l\'envoi du message: ${e.message}');
      throw Exception('Erreur lors de l\'envoi du message');
    }
  }

  // Récupérer les messages d'une réservation
  Future<List<MessageModel>> getMessagesForReservation(int reservationId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token') ?? '';
    final dio = DioClient.create(token: token);

    try {
      final response = await dio.get('/api/messages/reservation/$reservationId');
      return (response.data as List)
          .map((json) => MessageModel.fromJson(json))
          .toList();
    } on DioException catch (e) {
      print('Erreur lors de la récupération des messages: ${e.message}');
      throw Exception('Erreur lors de la récupération des messages');
    }
  }

  // Marquer les messages comme lus
  Future<void> marquerMessagesCommeLus(int reservationId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token') ?? '';
    final dio = DioClient.create(token: token);

    try {
      await dio.put('/api/messages/reservation/$reservationId/read');
    } on DioException catch (e) {
      print('Erreur lors du marquage des messages: ${e.message}');
      throw Exception('Erreur lors du marquage des messages');
    }
  }

  // Compter les messages non lus
  Future<int> compterMessagesNonLus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token') ?? '';
    final dio = DioClient.create(token: token);

    try {
      final response = await dio.get('/api/messages/unread/count');
      return response.data['count'] ?? 0;
    } on DioException catch (e) {
      print('Erreur lors du comptage des messages: ${e.message}');
      return 0;
    }
  }
} 