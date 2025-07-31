import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/transporteur_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../models/camion_model.dart';
import '../../services/profile_service.dart';
import '../../services/translation_service.dart';
import '../../services/reservation_service.dart';
import 'available_reservations_view.dart';
import 'profile_view.dart';
import 'documents_view.dart';

class TransporteurMainView extends StatefulWidget {
  const TransporteurMainView({super.key});

  @override
  State<TransporteurMainView> createState() => _TransporteurMainViewState();
}

class _TransporteurMainViewState extends State<TransporteurMainView> {
  int _selectedIndex = 0;
  final ReservationService _reservationService = ReservationService();
  Map<String, dynamic> _statistics = {};
  bool _isLoadingStatistics = true;

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    try {
      setState(() {
        _isLoadingStatistics = true;
      });
      final statistics = await _reservationService.getTransporteurStatistics();
      setState(() {
        _statistics = statistics;
        _isLoadingStatistics = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingStatistics = false;
      });
      print('Erreur lors du chargement des statistiques: $e');
    }
  }

  void _onTabTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  String _getText(String key) {
    return TranslationService.getText(key);
  }

  @override
  Widget build(BuildContext context) {
    final AuthController authController = AuthController();
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
          _getBody(_selectedIndex, authController),
        ],
      ),
      bottomNavigationBar: _modernNavBar(),
    );
  }

  Widget _getBody(int selectedIndex, AuthController authController) {
    switch (selectedIndex) {
      case 0:
        return _mainHomeContent(authController);
      case 1:
        return const ReservationsPage();
      case 2:
        return const DocumentsView();
      case 3:
        return const ProfilPage();
      default:
        return _mainHomeContent(authController);
    }
  }

  Widget _mainHomeContent(AuthController authController) {
    return FutureBuilder<String?>(
      future: ProfileService().getCurrentUsername(),
      builder: (context, snapshot) {
        final username = snapshot.data;
        final isLoading = snapshot.connectionState == ConnectionState.waiting;
        return SingleChildScrollView(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).padding.bottom + 80,
          ),
          child: Column(
            children: [
              // Header glassmorphism
              Container(
                margin: const EdgeInsets.only(top: 36, left: 16, right: 16, bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.10),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                  border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
                  backgroundBlendMode: BlendMode.overlay,
                ),
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            radius: 32,
                            backgroundColor: Colors.white,
                            child: Text(
                              username != null && username.isNotEmpty ? username[0].toUpperCase() : '',
                              style: const TextStyle(fontSize: 32, color: Color(0xFF1E3A8A), fontWeight: FontWeight.bold, fontFamily: 'Montserrat'),
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _getText('TransportPro'),
                                  style: const TextStyle(color: Color(0xFF1E3A8A), fontWeight: FontWeight.bold, fontSize: 22, fontFamily: 'Montserrat'),
                                ),
                                Text(
                                  _getText('welcome').replaceFirst('@user', username ?? ''),
                                  style: const TextStyle(color: Color(0xFF1E3A8A), fontSize: 16, fontFamily: 'Montserrat'),
                                ),
                              ],
                            ),
                          ),
                          Stack(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.chat_bubble_outline, color: Color(0xFF1E3A8A), size: 30),
                                onPressed: () {},
                                splashRadius: 26,
                              ),
                              Positioned(
                                right: 6,
                                top: 6,
                                child: Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Text('3', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                                ),
                              ),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Icons.logout, color: Color(0xFF1E3A8A), size: 30),
                            tooltip: _getText('logout'),
                            onPressed: () {
                              authController.logout();
                            },
                            splashRadius: 26,
                          ),
                        ],
                      ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Statistiques
                    if (_isLoadingStatistics)
                      const Center(child: CircularProgressIndicator())
                    else ...[
                      Row(
                        children: [
                          _statCard(
                            'Missions terminées', 
                            '${_statistics['missionsTerminees'] ?? 0}', 
                            Icons.check_circle_outline, 
                            color: const Color(0xFF43D19E)
                          ),
                          const SizedBox(width: 16),
                          _statCard(
                            'Gains', 
                            '${_statistics['gainsTotaux']?.toStringAsFixed(0) ?? 0} MAD', 
                            Icons.attach_money, 
                            color: const Color(0xFF7C5CFA)
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          _statCard(
                            'Réservations en attente', 
                            '${_statistics['reservationsEnAttente'] ?? 0}', 
                            Icons.schedule, 
                            color: const Color(0xFFFFB300)
                          ),
                          const SizedBox(width: 16),
                          _statCard(
                            'Kilomètres parcourus', 
                            '${_statistics['kilometresParcourus']?.toStringAsFixed(0) ?? 0} km', 
                            Icons.route, 
                            color: const Color(0xFF4F8FFF)
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 32),
                    // Actions rapides
                    Text(_getText('quick_actions'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, fontFamily: 'Montserrat')),
                    const SizedBox(height: 16),
                    _animatedButton(
                      icon: Icons.search,
                      label: _getText('find_missions'),
                      color: const Color(0xFF1E3A8A),
                      onTap: () {
                        // Rediriger vers la page de réservation, section "Tous les réservations"
                        setState(() {
                          _selectedIndex = 1;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _animatedButton(
                            icon: Icons.edit,
                            label: 'Modifier Camion',
                            color: const Color(0xFF4F8FFF),
                            outlined: true,
                            onTap: () {
                              Get.toNamed('/transporteur-camion-form');
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _animatedButton(
                            icon: Icons.description,
                            label: 'Documents',
                            color: const Color(0xFF7C5CFA),
                            outlined: true,
                            onTap: () {
                              // TODO: Implémenter la navigation vers la page des documents
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Fonctionnalité Documents à venir'),
                                  backgroundColor: Colors.blue,
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    // Informations du camion
                    Obx(() {
                      final controller = Get.put(TransporteurController());
                      if (controller.isLoading.value) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      
                      if (controller.hasCamion.value && controller.camion.value != null) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_getText('camion_info'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, fontFamily: 'Montserrat')),
                            const SizedBox(height: 16),
                            _buildCamionCard(controller.camion.value!),
                          ],
                        );
                      } else {
                        return _animatedButton(
                          icon: Icons.add,
                          label: _getText('register_camion'),
                          color: const Color(0xFF1E3A8A),
                          onTap: () {
                            Get.toNamed('/transporteur-camion-form');
                          },
                        );
                      }
                    }),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCamionCard(Camion camion) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E3A8A).withOpacity(0.10),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1E3A8A).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(8),
                child: const Icon(Icons.local_shipping, color: Color(0xFF1E3A8A), size: 28),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _getText('my_camion'),
                  style: const TextStyle(fontSize: 16, color: Color(0xFF374151), fontWeight: FontWeight.w600, fontFamily: 'Montserrat'),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit, color: Color(0xFF1E3A8A)),
                onPressed: () {
                  Get.toNamed('/transporteur-camion-form');
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoRow(_getText('brand'), camion.marque),
          _buildInfoRow(_getText('model'), camion.modele),
          _buildInfoRow(_getText('plate'), camion.immatriculation),
          _buildInfoRow(_getText('capacity'), '${camion.capacite.toStringAsFixed(1)} tonnes'),
          _buildInfoRow(_getText('type'), camion.type),
          _buildInfoRow(_getText('status'), camion.disponible ? _getText('available') : _getText('busy')),
          if (!camion.disponible) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final controller = Get.put(TransporteurController());
                  final success = await controller.resetCamionAvailability();
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Camion remis en disponibilité avec succès !'),
                        backgroundColor: Colors.green,
                        duration: Duration(seconds: 3),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Erreur lors de la remise en disponibilité'),
                        backgroundColor: Colors.red,
                        duration: Duration(seconds: 3),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.refresh, color: Colors.white),
                label: const Text('Remettre en disponibilité', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 14,
              fontFamily: 'Montserrat',
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14,
              fontFamily: 'Montserrat',
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(String title, String value, IconData icon, {Color color = const Color(0xFF1E3A8A)}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.85),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.10),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(8),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontSize: 14, color: Color(0xFF374151), fontWeight: FontWeight.w600, fontFamily: 'Montserrat'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              value,
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: color, fontFamily: 'Montserrat'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _animatedButton({required IconData icon, required String label, required Color color, bool outlined = false, required VoidCallback onTap}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: outlined ? Colors.transparent : color,
        borderRadius: BorderRadius.circular(18),
        border: outlined ? Border.all(color: color, width: 2) : null,
        boxShadow: outlined
            ? []
            : [
                BoxShadow(
                  color: color.withOpacity(0.13),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: outlined ? color : Colors.white, size: 24),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: outlined ? color : Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      fontFamily: 'Montserrat',
                    ),
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _modernNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.10),
            blurRadius: 18,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: BottomNavigationBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onTabTapped,
        selectedItemColor: const Color(0xFF1E3A8A),
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        selectedLabelStyle: const TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.bold),
        unselectedLabelStyle: const TextStyle(fontFamily: 'Montserrat'),
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home, size: 28),
            label: _getText('Accueil'),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment, size: 28),
            label: _getText('Réservations'),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.description, size: 28),
            label: 'Documents',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person, size: 28),
            label: _getText('Profil'),
          ),
        ],
      ),
    );
  }
}

// Page des réservations
class ReservationsPage extends StatelessWidget {
  const ReservationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const AvailableReservationsView();
  }
}



// Page du profil
class ProfilPage extends StatelessWidget {
  const ProfilPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const ProfileView();
  }
} 