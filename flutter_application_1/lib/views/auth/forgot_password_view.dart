import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../services/translation_service.dart';
import '../../controllers/auth_controller.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  bool _isLoading = false;
  bool _isArabic = false;
  String? _errorMessage;
  String? _successMessage;
  String? _sentEmail; // Pour stocker l'email masqué
  bool _codeSent = false; // Pour savoir si le code a été envoyé
  final _codeController = TextEditingController();

  final AuthController authController = Get.put(AuthController());

  String _getText(String key) {
    return TranslationService.getText(key);
  }

  void _toggleLanguage() {
    setState(() {
      _isArabic = !_isArabic;
    });
  }

  Future<void> _handleForgotPassword() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final email = await authController.forgotPassword(_usernameController.text.trim());
      setState(() {
        _sentEmail = maskEmail(email ?? '');
        _successMessage = "${_getText('reset_link_sent')} $_sentEmail";
        _codeSent = true;
      });
    } catch (e) {
      setState(() {
        if (e.toString().contains('user_not_found')) {
          print("${e}not found");
          _errorMessage = _getText('user_not_found');
        } else {
            print("${e}login error");
          _errorMessage = _getText('login_error');
        }
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _handleVerifyCode() async {
    // Validation des champs
    if (_usernameController.text.trim().isEmpty || _codeController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = _getText('fields_required');
        _successMessage = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      await authController.verfierCode(
        _usernameController.text.trim(), 
        _codeController.text.trim()
      );
      setState(() {
        Get.toNamed('/reset_pass', arguments: _usernameController.text.trim());
        _errorMessage = null;
      });
    } catch (e) {
      print('Erreur dans _handleVerifyCode: $e');
      setState(() {
        String errorString = e.toString();
        if (errorString.contains('invalid_code') || errorString.contains('Code invalid')) {
          _errorMessage = _getText('invalid_code');
        } else if (errorString.contains('user_not_found')) {
          _errorMessage = _getText('user_not_found');
        } else if (errorString.contains('verification_error')) {
          _errorMessage = _getText('verification_error');
        } else {
          _errorMessage = _getText('general_error');
        }
        _successMessage = null;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
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
                  _buildHeader(),
                  const SizedBox(height: 20),
                  _buildForgotForm(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Text(
          _getText('forgot_password_title'),
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E3A8A),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          _getText('forgot_password_subtitle'),
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildForgotForm() {
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
              _getText('username_label'),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF374151),
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _usernameController,
              keyboardType: TextInputType.text,
              decoration: InputDecoration(
                hintText: _getText('username_hint'),
                prefixIcon: const Icon(Icons.person_outline, color: Color(0xFF6B7280)),
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
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return _getText('username_required');
                }
                if (value.length < 3) {
                  return _getText('username_length_error');
                }
                return null;
              },
            ),
            if (_codeSent) ...[
              const SizedBox(height: 20),
              Text(
                _getText('enter_code_label'),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF374151),
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _codeController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: _getText('code_hint'),
                  prefixIcon: const Icon(Icons.verified_user, color: Color(0xFF6B7280)),
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
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return _getText('code_required');
                  }
                  if (value.length != 6) {
                    return _getText('code_length_error');
                  }
                  return null;
                },
              ),
            ],
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
                onPressed: _isLoading
                    ? null
                    : _codeSent
                        ? _handleVerifyCode
                        : _handleForgotPassword,
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
                    : Text(_codeSent
                        ? _getText('verify_code_button')
                        : _getText('reset_password_button')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String maskEmail(String email) {
  final parts = email.split('@');
  if (parts.length != 2) return email;

  final username = parts[0];
  final domain = parts[1];

  // Masquer le username (garde 2 premiers et 2 derniers caractères)
  String maskedUsername;
  if (username.length <= 4) {
    maskedUsername = username[0] + '*' * (username.length - 2) + username[username.length - 1];
  } else {
    maskedUsername = username.substring(0, 2) +
        '*' * (username.length - 4) +
        username.substring(username.length - 2);
  }

  // Masquer le domaine (garde la première lettre et le TLD)
  final domainParts = domain.split('.');
  if (domainParts.length < 2) return '$maskedUsername@$domain';

  final domainName = domainParts[0];
  final tld = domainParts.sublist(1).join('.');

  String maskedDomain = domainName[0] + '*' * (domainName.length - 1);

  return '$maskedUsername@$maskedDomain.$tld';
} 