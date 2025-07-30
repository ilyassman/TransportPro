import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../services/translation_service.dart';
import '../../controllers/auth_controller.dart';
import '../../models/user_model.dart';

class ResetPasswordPage extends StatefulWidget {
  final String username;
  const ResetPasswordPage({super.key, required this.username});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;
  bool _isObscured = true;
  bool _isObscuredConfirm = true;
  
  final AuthController authController = Get.put(AuthController());

  String _getText(String key) {
    return TranslationService.getText(key);
  }

  Future<void> _handleResetPassword() async {
    if (!_formKey.currentState!.validate()) return;
    
    print('=== DÉBUT RESET PASSWORD VIEW ===');
    print('Username reçu pour reset : ${widget.username}');
    print('Nouveau mot de passe : ${_passwordController.text}');
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      // Créer un UserModel avec le nouveau mot de passe
      final user = UserModel(
        id: 0, // L'ID n'est pas utilisé pour la mise à jour du mot de passe
        username: widget.username,
        email: '', // L'email n'est pas utilisé pour la mise à jour du mot de passe
        password: _passwordController.text,
      );

      print('UserModel créé: ${user.username}');

      // Appeler la méthode updatePassword du AuthController et attendre la réponse
      await authController.updatePassword(user);
      
      print('=== SUCCÈS RESET PASSWORD VIEW ===');
      print('Mot de passe mis à jour avec succès dans la vue');
      
      setState(() {
        _successMessage = _getText('password_reset_success');
        _errorMessage = null;
      });
      
      // Optionnel : rediriger vers la page de connexion après un délai
      Future.delayed(const Duration(seconds: 2), () {
        Get.offAllNamed('/login');
      });
      
    } catch (e) {
      print('=== ERREUR RESET PASSWORD VIEW ===');
      print('Erreur dans _handleResetPassword: $e');
      print('Type d\'erreur: ${e.runtimeType}');
      
      setState(() {
        String errorString = e.toString();
        if (errorString.contains('network_error')) {
          _errorMessage = _getText('network_error');
        } else if (errorString.contains('user_not_found')) {
          _errorMessage = _getText('user_not_found');
        } else if (errorString.contains('invalid_password')) {
          _errorMessage = _getText('invalid_password');
        } else if (errorString.contains('update_password_error')) {
          _errorMessage = _getText('update_password_error');
        } else if (errorString.contains('verification_error')) {
          _errorMessage = _getText('verification_error');
        } else {
          _errorMessage = _getText('general_error');
        }
        _successMessage = null;
      });
    } finally {
      print('=== FIN RESET PASSWORD VIEW ===');
      setState(() {
        _isLoading = false;
      });
    }
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return _getText('password_required');
    }
    if (value.length < 8) {
      return _getText('password_length_error');
    }
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return _getText('password_uppercase_error');
    }
    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return _getText('password_lowercase_error');
    }
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return _getText('password_digit_error');
    }
    if (!RegExp(r'[.!@#\$&*~]').hasMatch(value)) {
      return _getText('password_special_error');
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _getText('reset_password_title'),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E3A8A),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  _buildResetForm(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResetForm() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _getText('new_password_label'),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF374151),
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _passwordController,
              obscureText: _isObscured,
              decoration: InputDecoration(
                hintText: _getText('new_password_hint'),
                prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF6B7280)),
                suffixIcon: IconButton(
                  icon: Icon(_isObscured ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _isObscured = !_isObscured),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 2),
                ),
                filled: true,
                fillColor: Colors.grey[50],
                errorMaxLines: 3,
                errorStyle: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  height: 1.3,
                ),
              ),
              validator: _validatePassword,
            ),
            const SizedBox(height: 16),
            Text(
              _getText('confirm_password_label'),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF374151),
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _confirmController,
              obscureText: _isObscuredConfirm,
              decoration: InputDecoration(
                hintText: _getText('confirm_password_hint'),
                prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF6B7280)),
                suffixIcon: IconButton(
                  icon: Icon(_isObscuredConfirm ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _isObscuredConfirm = !_isObscuredConfirm),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 2),
                ),
                filled: true,
                fillColor: Colors.grey[50],
                errorMaxLines: 3,
                errorStyle: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  height: 1.3,
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return _getText('confirm_password_required');
                }
                if (value != _passwordController.text) {
                  return _getText('passwords_do_not_match');
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            if (_successMessage != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  _successMessage!,
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleResetPassword,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E3A8A),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(_getText('save_new_password_button')),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 