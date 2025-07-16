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
        title: const Text('Accueil Transporteur'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Déconnexion',
            onPressed: () {
              authController.logout();
            },
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