import 'package:flutter/material.dart';
import '../../services/profile_service.dart';
import '../../controllers/auth_controller.dart';
import 'package:flutter_application_1/views/chargeur/reservation_view.dart';
import 'package:flutter_application_1/views/chargeur/suivre_view.dart';
import 'package:flutter_application_1/views/chargeur/documents_view.dart';
import 'package:flutter_application_1/views/chargeur/profile_view.dart';
import 'package:get/get.dart';
import '../../services/translation_service.dart';

class ChargeurHomeView extends StatefulWidget {
  const ChargeurHomeView({Key? key}) : super(key: key);

  @override
  State<ChargeurHomeView> createState() => _ChargeurHomeViewState();
}

class _ChargeurHomeViewState extends State<ChargeurHomeView> {
  int _selectedIndex = 0;

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
        return const ReservationView();
      case 2:
        return const SuivreView();
      case 3:
        return const DocumentsView();
      case 4:
        return const ProfileView();
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
                    Row(
                      children: [
                        _statCard(_getText('active_reservations'), '12', Icons.assignment_turned_in_outlined, color: const Color(0xFF4F8FFF)),
                        const SizedBox(width: 16),
                        _statCard(_getText('in_progress'), '8', Icons.flash_on, color: const Color(0xFFFFB300)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _statCard(_getText('completed'), '45', Icons.check_circle_outline, color: const Color(0xFF43D19E)),
                        const SizedBox(width: 16),
                        _statCard(_getText('total_amount'), '125 MAD', Icons.attach_money, color: const Color(0xFF7C5CFA)),
                      ],
                    ),
                    const SizedBox(height: 32),
                    // Actions rapides
                    Text(_getText('quick_actions'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, fontFamily: 'Montserrat')),
                    const SizedBox(height: 16),
                    _animatedButton(
                      icon: Icons.add,
                      label: _getText('new_reservation'),
                      color: const Color(0xFF1E3A8A),
                      onTap: () {},
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _animatedButton(
                            icon: Icons.location_on_outlined,
                            label: _getText('track'),
                            color: const Color(0xFF4F8FFF),
                            outlined: true,
                            onTap: () {},
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _animatedButton(
                            icon: Icons.insert_drive_file_outlined,
                            label: _getText('documents'),
                            color: const Color(0xFF7C5CFA),
                            outlined: true,
                            onTap: () {},
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    // Activité récente
                    Text(_getText('recent_activity'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, fontFamily: 'Montserrat')),
                    const SizedBox(height: 16),
                    Card(
                      elevation: 0,
                      color: const Color(0xFFFFF9C4),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      child: ListTile(
                        leading: Container(
                          decoration: BoxDecoration(
                            color: Colors.yellow[700],
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.all(8),
                          child: const Icon(Icons.flash_on, color: Colors.white, size: 28),
                        ),
                        title: Text(_getText('shipment_in_transit'), style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Montserrat')),
                        subtitle: Text(_getText('marrakech_to_fes'), style: const TextStyle(fontFamily: 'Montserrat')),
                      ),
                    ),
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
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: outlined ? color : Colors.white, size: 26),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: TextStyle(
                    color: outlined ? color : Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    fontFamily: 'Montserrat',
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
            icon: Icon(Icons.location_on, size: 28),
            label: _getText('Suivre'),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.insert_drive_file, size: 28),
            label: _getText('Documents'),
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