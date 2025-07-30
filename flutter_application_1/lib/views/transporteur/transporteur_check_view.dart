import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/transporteur_controller.dart';
import '../../services/translation_service.dart';

class TransporteurCheckView extends StatefulWidget {
  const TransporteurCheckView({super.key});

  @override
  State<TransporteurCheckView> createState() => _TransporteurCheckViewState();
}

class _TransporteurCheckViewState extends State<TransporteurCheckView> {
  String _getText(String key) {
    return TranslationService.getText(key);
  }

  @override
  void initState() {
    super.initState();
    _checkTransporteurStatus();
  }

  Future<void> _checkTransporteurStatus() async {
    try {
      // Initialiser le contrôleur directement
      final controller = Get.put(TransporteurController());
      
      // Attendre que la vérification soit terminée
      await Future.delayed(const Duration(seconds: 2));
      
      // Attendre que le contrôleur ait fini de vérifier
      while (controller.isLoading.value) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      
      // Vérifier si le transporteur a un camion
      if (controller.hasCamion.value) {
        // Rediriger vers la page principale
        Get.offAllNamed('/transporteur-main');
      } else {
        // Rediriger vers le formulaire d'enregistrement
        Get.offAllNamed('/transporteur-camion-form');
      }
    } catch (e) {
      print('Erreur lors de la vérification: $e');
      // En cas d'erreur, rediriger vers le formulaire
      Get.offAllNamed('/transporteur-camion-form');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Dégradé de fond subtil
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFF5F7FA), Color(0xFFE3E9F9), Color(0xFFD1D8F1)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 32),
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.85),
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1E3A8A).withOpacity(0.10),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
                border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icône de chargement
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E3A8A).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(40),
                    ),
                    child: const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1E3A8A)),
                      strokeWidth: 3,
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Titre
                  Text(
                    'Vérification en cours...',
                    style: const TextStyle(
                      color: Color(0xFF1E3A8A),
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Montserrat',
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Description
                  Text(
                    'Nous vérifions votre profil transporteur',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                      fontFamily: 'Montserrat',
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Indicateur de progression
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E3A8A).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Chargement...',
                      style: TextStyle(
                        color: const Color(0xFF1E3A8A),
                        fontSize: 14,
                        fontFamily: 'Montserrat',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
} 