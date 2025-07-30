import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/user_controller.dart';
import '../models/user_model.dart';

class AddUserView extends StatelessWidget {
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final userController = Get.find<UserController>();
  final _passwordController = TextEditingController();

  AddUserView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Ajouter un utilisateur")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(labelText: 'Nom d\'utilisateur'),
            ),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: 'Mot de passe'),
              obscureText: true,
            ),
            SizedBox(height: 20),
            Obx(() => userController.isLoading.value
                ? CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: () {
                      final user = UserModel(
                        id: 0,
                        username: _usernameController.text,
                        email: _emailController.text,
                        password: _passwordController.text,
                      );
                      userController.addUser(user);
                      Get.back();
                    },
                    child: Text("Ajouter"),
                  )),
          ],
        ),
      ),
    );
  }
}
