import 'package:flutter/material.dart';
import 'package:flutter_application_1/views/add_user_view.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../controllers/user_controller.dart';
import '../controllers/auth_controller.dart';
import '../services/profile_service.dart';

class UserView extends StatelessWidget {
    final UserController userController = Get.find<UserController>();
    final AuthController authController = Get.put(AuthController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
  appBar: AppBar(
    title: const Text('Liste des utilisateurs'),
    actions: [
      IconButton(
        icon: const Icon(Icons.person),
        onPressed: () {
          Get.toNamed('/profile');
        },
        tooltip: 'Profil',
      ),
      IconButton(
        icon: const Icon(Icons.security),
        onPressed: () async {
          try {
            // Récupérer le token depuis SharedPreferences
            final prefs = await SharedPreferences.getInstance();
            final token = prefs.getString('access_token');
            
            if (token != null) {
              // Créer le service avec le token
              final profileService = ProfileService();
              final username = await profileService.getCurrentUsername();
              
              if (username != null) {
                Get.toNamed('/two-factor-setup', arguments: {'username': username});
              } else {
                Get.snackbar(
                  'Erreur',
                  'Impossible de récupérer les informations utilisateur',
                  backgroundColor: Colors.red,
                  colorText: Colors.white,
                );
              }
            } else {
              Get.snackbar(
                'Erreur',
                'Token d\'authentification non trouvé',
                backgroundColor: Colors.red,
                colorText: Colors.white,
              );
            }
          } catch (e) {
            Get.snackbar(
              'Erreur',
              'Erreur lors de la récupération du profil: $e',
              backgroundColor: Colors.red,
              colorText: Colors.white,
            );
          }
        },
        tooltip: 'Configuration 2FA',
      ),
      IconButton(
        icon: const Icon(Icons.logout),
        onPressed: () {
          authController.logout();
        },
        tooltip: 'Déconnexion',
      ),
    ],
  ),
  body: Obx(() {
    if (userController.isLoading.value) {
      return Center(child: CircularProgressIndicator());
    }

    return ListView.builder(
      itemCount: userController.userList.length,
      itemBuilder: (context, index) {
        final user = userController.userList[index];
        return ListTile(
          title: Text(user.username),
          subtitle: Text(user.email),
          leading: CircleAvatar(child: Text(user.id.toString())),
          onLongPress: () {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: Text('Supprimer l\'utilisateur'),
                  content: Text('Êtes-vous sûr de vouloir supprimer ${user.username} ?'),
                  actions: [
                    TextButton(
                      onPressed: () {
                        userController.deleteUser(user.id);
                        
                        Get.back();
                        Get.snackbar('Succès', 'Utilisateur ${user.username} supprimé avec succès',
                          snackPosition: SnackPosition.BOTTOM,
                          duration: Duration(seconds: 2),
                        ); // Fermer la boîte de dialogue
                      },
                      child: Text('Supprimer'),
                    ),
                    TextButton(
                      onPressed: () => Get.back(), // Fermer la boîte de dialogue
                      child: Text('Annuler'),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }),
  floatingActionButton: FloatingActionButton(
    onPressed: () {
      // Exemple : Naviguer vers un écran d'ajout d'utilisateur
      //Get.to(() => AddUserView()); 
    },
    child: const Icon(Icons.add),
  ),
);
}
}
