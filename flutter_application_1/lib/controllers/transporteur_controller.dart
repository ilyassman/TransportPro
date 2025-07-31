import 'package:get/get.dart';
import '../services/camion_service.dart';
import '../services/profile_service.dart';
import '../models/camion_model.dart';

class TransporteurController extends GetxController {
  final CamionService camionService = CamionService();
  final ProfileService profileService = ProfileService();
  
  var isLoading = false.obs;
  var hasCamion = false.obs;
  var camion = Rxn<Camion>();

  @override
  void onInit() {
    super.onInit();
    checkTransporteurCamion();
  }

  Future<void> checkTransporteurCamion() async {
    try {
      isLoading(true);
      
      // Récupérer le profil de l'utilisateur connecté
      final profile = await profileService.getProfile();
      final userId = profile['id'];
      
      if (userId != null) {
        // Vérifier si le transporteur a un camion
        final transporteurCamion = await camionService.getCamionByTransporteur(userId);
        
        if (transporteurCamion != null) {
          hasCamion(true);
          camion(transporteurCamion);
        } else {
          hasCamion(false);
        }
      }
    } catch (e) {
      print('Erreur lors de la vérification du camion: $e');
      hasCamion(false);
    } finally {
      isLoading(false);
    }
  }

  Future<bool> createCamion({
    required String marque,
    required String modele,
    required String immatriculation,
    required double capacite,
    required String type,
    required double latitude,
    required double longitude,
  }) async {
    try {
      isLoading(true);
      
      final profile = await profileService.getProfile();
      final userId = profile['id'];
      
      final camionData = {
        'marque': marque,
        'modele': modele,
        'immatriculation': immatriculation,
        'capacite': capacite,
        'type': type,
        'disponible': true,
        'latitude': latitude,
        'longitude': longitude,
        'transporteur': {
          'id': userId
        }
      };
      
      final newCamion = await camionService.createCamion(camionData);
      
      if (newCamion != null) {
        hasCamion(true);
        camion(newCamion);
        return true;
      }
      
      return false;
    } catch (e) {
      print('Erreur lors de la création du camion: $e');
      return false;
    } finally {
      isLoading(false);
    }
  }

  Future<bool> updateCamion({
    required String marque,
    required String modele,
    required String immatriculation,
    required double capacite,
    required String type,
    required double latitude,
    required double longitude,
  }) async {
    try {
      isLoading(true);
      
      print('Début de updateCamion');
      print('Camion actuel: ${camion.value}');
      print('ID du camion: ${camion.value?.id}');
      
      if (camion.value == null || camion.value!.id == null) {
        print('Erreur: Camion ou ID du camion est null');
        return false;
      }
      
      final camionData = {
        'marque': marque,
        'modele': modele,
        'immatriculation': immatriculation,
        'capacite': capacite,
        'type': type,
        'disponible': camion.value!.disponible,
        'latitude': latitude,
        'longitude': longitude,
      };
      
      print('Données à envoyer: $camionData');
      
      final updatedCamion = await camionService.updateCamion(camion.value!.id!, camionData);
      
      print('Camion mis à jour reçu: $updatedCamion');
      
      if (updatedCamion != null) {
        camion(updatedCamion);
        return true;
      }
      
      return false;
    } catch (e) {
      print('Erreur lors de la mise à jour du camion: $e');
      return false;
    } finally {
      isLoading(false);
    }
  }
  
  Future<bool> resetCamionAvailability() async {
    try {
      isLoading(true);
      
      if (camion.value == null || camion.value!.id == null) {
        print('Erreur: Camion ou ID du camion est null');
        return false;
      }
      
      final success = await camionService.resetCamionAvailability(camion.value!.id!);
      
      if (success) {
        // Mettre à jour le camion local
        final updatedCamion = await camionService.getCamionById(camion.value!.id!);
        if (updatedCamion != null) {
          camion(updatedCamion);
        }
        return true;
      }
      
      return false;
    } catch (e) {
      print('Erreur lors de la réinitialisation de la disponibilité: $e');
      return false;
    } finally {
      isLoading(false);
    }
  }
  
  Future<bool> resetMyCamionAvailability() async {
    try {
      isLoading(true);
      
      final success = await camionService.resetMyCamionAvailability();
      
      if (success) {
        // Mettre à jour le camion local
        await checkTransporteurCamion();
        return true;
      }
      
      return false;
    } catch (e) {
      print('Erreur lors de la réinitialisation de la disponibilité: $e');
      return false;
    } finally {
      isLoading(false);
    }
  }
  
  Future<Map<String, dynamic>?> getCamionAvailability() async {
    try {
      if (camion.value == null || camion.value!.id == null) {
        return null;
      }
      
      return await camionService.getCamionAvailability(camion.value!.id!);
    } catch (e) {
      print('Erreur lors de la récupération de la disponibilité: $e');
      return null;
    }
  }
} 