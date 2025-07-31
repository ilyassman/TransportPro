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
      
      // Vérifier si c'est l'erreur de camion non disponible
      if (errorMessage.contains("Votre camion n'est pas disponible")) {
        // Afficher un dialog avec option de réinitialiser la disponibilité
        final result = await Get.dialog<bool>(
          AlertDialog(
            title: const Text('Camion non disponible'),
            content: const Text(
              'Votre camion est actuellement marqué comme indisponible. '
              'Voulez-vous le remettre en disponibilité pour pouvoir proposer vos services ?'
            ),
            actions: [
              TextButton(
                onPressed: () => Get.back(result: false),
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Get.back(result: true);
                  // Réinitialiser la disponibilité du camion
                  final transporteurController = Get.put(TransporteurController());
                  final success = await transporteurController.resetCamionAvailability();
                  if (success) {
                    Get.snackbar(
                      'Camion remis en disponibilité',
                      'Votre camion est maintenant disponible. Vous pouvez réessayer de proposer vos services.',
                      backgroundColor: const Color(0xFF10B981),
                      colorText: Colors.white,
                      duration: const Duration(seconds: 4),
                      icon: const Icon(Icons.check_circle, color: Colors.white),
                    );
                  } else {
                    Get.snackbar(
                      'Erreur',
                      'Impossible de remettre le camion en disponibilité',
                      backgroundColor: Colors.red,
                      colorText: Colors.white,
                      duration: const Duration(seconds: 3),
                      icon: const Icon(Icons.error, color: Colors.white),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                ),
                child: const Text('Remettre en disponibilité'),
              ),
            ],
          ),
        );
        
        if (result == true) {
          return false; // L'utilisateur a choisi de réinitialiser, on retourne false pour permettre de réessayer
        }
      }
      
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
      // Utiliser la nouvelle méthode qui inclut les informations du chargeur
      final myReservations = await _service.getMyReservationsWithChargeurInfo(status);
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