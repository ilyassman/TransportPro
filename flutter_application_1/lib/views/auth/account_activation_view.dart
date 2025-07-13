import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../services/translation_service.dart';
import '../../controllers/auth_controller.dart';

class AccountActivationView extends StatefulWidget {
  const AccountActivationView({Key? key}) : super(key: key);

  @override
  State<AccountActivationView> createState() => _AccountActivationViewState();
}

class _AccountActivationViewState extends State<AccountActivationView> {
  final AuthController authController = Get.put(AuthController());
  bool _isLoading = false;
  bool _isArabic = false;
  String? _errorMessage;
  String? _successMessage;
  String? _username;

  @override
  void initState() {
    super.initState();
    _username = Get.arguments?['username'];
    _checkLanguage();
  }

  void _checkLanguage() async {
    await TranslationService.initializeLanguage();
    setState(() {
      _isArabic = TranslationService.isArabic;
    });
  }

  String _getText(String key) {
    return TranslationService.getText(key);
  }

  Future<void> _resendActivationEmail() async {
    if (_username == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      await authController.resendActivationEmail(_username!);
      setState(() {
        _successMessage = _getText('activation_email_sent_message');
      });
    } catch (e) {
      setState(() {
        _errorMessage = _getText('general_error');
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _checkActivation() async {
    if (_username == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final isActivated = await authController.checkAccountActivation(_username!);
      if (isActivated) {
        setState(() {
          _successMessage = _getText('activation_success_message');
        });
        
        // Rediriger vers la page de connexion après un délai
        Future.delayed(const Duration(seconds: 2), () {
          Get.offAllNamed('/login');
        });
      } else {
        setState(() {
          _errorMessage = _getText('account_not_activated_message');
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = _getText('general_error');
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
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 20),
                  _buildActivationContent(),
                  const SizedBox(height: 20),
                  _buildFooter(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        children: [
          // Logo et titre
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1E3A8A).withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: const Icon(
              Icons.email_outlined,
              size: 35,
              color: Colors.white,
            ),
          ),
          
          const SizedBox(height: 12),
          
          Text(
            _getText('activation_required'),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E3A8A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivationContent() {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icône d'email
          Center(
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: const Color(0xFF1E3A8A).withOpacity(0.1),
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Icon(
                Icons.email_outlined,
                size: 30,
                color: Color(0xFF1E3A8A),
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Titre
          Text(
            _getText('check_email'),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E3A8A),
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 12),
          
          // Message
          Text(
            _getText('account_not_activated_message'),
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 24),
          
          // Messages d'erreur ou de succès
          if (_errorMessage != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Text(
                _errorMessage!,
                style: TextStyle(
                  color: Colors.red[700],
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          
          if (_successMessage != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Text(
                _successMessage!,
                style: TextStyle(
                  color: Colors.green[700],
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          
          const SizedBox(height: 24),
          
          // Boutons
          Column(
            children: [
              // Bouton pour vérifier l'activation
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _checkActivation,
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
                      : Text(
                          _getText('check_email'),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Bouton pour renvoyer l'email
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton(
                  onPressed: _isLoading ? null : _resendActivationEmail,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF1E3A8A),
                    side: const BorderSide(color: Color(0xFF1E3A8A)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _getText('resend_activation'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Lien de retour à la connexion
              Center(
                child: TextButton(
                  onPressed: () => Get.offAllNamed('/login'),
                  child: Text(
                    _getText('login_link'),
                    style: const TextStyle(
                      color: Color(0xFF3B82F6),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 30,
                height: 1,
                color: Colors.grey[300],
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  _getText('secured_by'),
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[500],
                  ),
                ),
              ),
              Container(
                width: 30,
                height: 1,
                color: Colors.grey[300],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.security,
                size: 14,
                color: Colors.grey[500],
              ),
              const SizedBox(width: 4),
              Text(
                _getText('2fa_auth'),
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[500],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _getText('compliance_text'),
            style: TextStyle(
              fontSize: 9,
              color: Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }
} 