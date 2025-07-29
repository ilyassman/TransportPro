import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../services/profile_service.dart';
import '../../controllers/auth_controller.dart';

class TransporteurHomeView extends StatefulWidget {
  const TransporteurHomeView({Key? key}) : super(key: key);

  @override
  State<TransporteurHomeView> createState() => _TransporteurHomeViewState();
}

class _TransporteurHomeViewState extends State<TransporteurHomeView> {
  String? username;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsername();
  }

  Future<void> _loadUsername() async {
    final profileService = ProfileService();
    final name = await profileService.getCurrentUsername();
    setState(() {
      username = name;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final AuthController authController = Get.put(AuthController());
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        title: const Text('Accueil Transporteur'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.logout, color: Color(0xFF1E3A8A)),
              label: const Text('Déconnexion', style: TextStyle(color: Color(0xFF1E3A8A))),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text('Confirmation'),
                      content: const Text('Voulez-vous vraiment vous déconnecter ?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Annuler'),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            authController.logout();
                          },
                          child: const Text('Déconnexion', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      body: Center(
        child: isLoading
            ? const CircularProgressIndicator()
            : Text(
                'Bonjour ${username ?? ''} le transporteur',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }
} 