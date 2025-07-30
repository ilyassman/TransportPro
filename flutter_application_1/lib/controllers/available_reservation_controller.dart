import 'package:get/get.dart';
import '../models/available_reservation_model.dart';
import '../services/available_reservation_service.dart';
import 'package:flutter/material.dart';

class AvailableReservationController extends GetxController {
  final AvailableReservationService _service = AvailableReservationService();
  
  var isLoading = false.obs;
  var reservations = <AvailableReservation>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadReservationsByStatus('en_attente');
  }

  Future<void> loadReservationsByStatus(String status) async {
    try {
      isLoading(true);
      final data = await _service.getAvailableReservationsByStatus(status);
      reservations.assignAll(data);
    } catch (e) {
      print('Erreur lors du chargement des réservations par statut: $e');
    } finally {
      isLoading(false);
    }
  }

  Future<bool> proposeForReservation(int reservationId, {double? prixPropose}) async {
    try {
      isLoading(true);
      await _service.proposeForReservation(reservationId, prixPropose: prixPropose);
      
      // Retirer la réservation de la liste (optionnel, car elle peut rester visible)
      // reservations.removeWhere((r) => r.id == reservationId);
      
      // Afficher un message de succès
      String message = prixPropose != null 
          ? 'Votre proposition avec tarif personnalisé (${prixPropose.toStringAsFixed(2)} DH) a été envoyée au chargeur !'
          : 'Votre proposition a été envoyée au chargeur avec succès !';
      
      Get.snackbar(
        'Proposition envoyée',
        message,
        backgroundColor: const Color(0xFF10B981),
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
        icon: const Icon(Icons.check_circle, color: Colors.white),
      );
      
      return true;
    } catch (e) {
      print('Erreur lors de l\'envoi de la proposition: $e');
      
      String errorMessage = e.toString().replaceAll('Exception: ', '');
      
      // Afficher un message d'erreur
      Get.snackbar(
        'Erreur',
        errorMessage,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
        icon: const Icon(Icons.error, color: Colors.white),
      );
      
      return false;
    } finally {
      isLoading(false);
    }
  }

  void refresh() {
    loadReservationsByStatus('en_attente');
  }
  
  // Méthodes pour les réservations du transporteur connecté
  Future<void> loadMyReservations() async {
    try {
      isLoading(true);
      final myReservations = await _service.getMyReservations();
      reservations.assignAll(myReservations);
    } catch (e) {
      print('Erreur lors du chargement de mes réservations: $e');
      Get.snackbar(
        'Erreur',
        'Impossible de charger vos réservations',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    } finally {
      isLoading(false);
    }
  }
  
  Future<void> loadMyReservationsByStatus(String status) async {
    try {
      isLoading(true);
      final myReservations = await _service.getMyReservationsByStatus(status);
      reservations.assignAll(myReservations);
    } catch (e) {
      print('Erreur lors du chargement de mes réservations par statut: $e');
      Get.snackbar(
        'Erreur',
        'Impossible de charger vos réservations',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    } finally {
      isLoading(false);
    }
  }
  
  Future<bool> updateReservationStatus(int reservationId, String newStatus) async {
    try {
      isLoading(true);
      await _service.updateReservationStatus(reservationId, newStatus);
      
      Get.snackbar(
        'Statut mis à jour',
        'Le statut a été changé vers $newStatus avec succès !',
        backgroundColor: const Color(0xFF10B981),
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
        icon: const Icon(Icons.check_circle, color: Colors.white),
      );
      
      // Recharger les réservations
      await loadMyReservations();
      
      return true;
    } catch (e) {
      print('Erreur lors du changement de statut: $e');
      
      String errorMessage = e.toString().replaceAll('Exception: ', '');
      
      Get.snackbar(
        'Erreur',
        errorMessage,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
        icon: const Icon(Icons.error, color: Colors.white),
      );
      
      return false;
    } finally {
      isLoading(false);
    }
  }
} 