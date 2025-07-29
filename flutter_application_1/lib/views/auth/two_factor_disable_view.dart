import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../controllers/two_factor_controller.dart';
import '../../services/translation_service.dart';

class TwoFactorDisableView extends StatefulWidget {
  const TwoFactorDisableView({Key? key}) : super(key: key);

  @override
  State<TwoFactorDisableView> createState() => _TwoFactorDisableViewState();
}

class _TwoFactorDisableViewState extends State<TwoFactorDisableView> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final TwoFactorController twoFactorController = Get.find<TwoFactorController>();
  
  String? username;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    // Récupérer le username depuis les arguments
    final args = Get.arguments as Map<String, dynamic>?;
    username = args?['username'];
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  String _getText(String key) {
    return TranslationService.getText(key);
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (username == null) {
      setState(() {
        errorMessage = 'Nom d\'utilisateur manquant';
      });
      return;
    }

    try {
      setState(() {
        errorMessage = null; // Effacer les erreurs précédentes
      });
      
      final code = int.parse(_codeController.text);
      print('=== DÉBUT DÉSACTIVATION 2FA ===');
      print('Username: $username, Code: $code');
      
      // Passer le code au contrôleur
      twoFactorController.codeController.text = _codeController.text;
      
      await twoFactorController.disableTwoFactorWithVerification();
      
      print('=== FIN DÉSACTIVATION 2FA ===');
      
    } catch (e) {
      print('=== ERREUR DÉSACTIVATION 2FA ===');
      print('Erreur: $e');
      setState(() {
        if (e.toString().contains('Code invalide') || e.toString().contains('invalid')) {
          errorMessage = 'Code invalide. Veuillez réessayer.';
        } else {
          errorMessage = 'Erreur lors de la désactivation 2FA: ${e.toString()}';
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1E3A8A)),
          onPressed: () => Get.back(),
        ),
      ),
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
                  const SizedBox(height: 32),
                  _buildForm(),
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
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFEF4444).withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: const Icon(
            Icons.security,
            size: 40,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Désactiver 2FA',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E3A8A),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Entrez votre code 2FA pour confirmer la désactivation',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildForm() {
    return Container(
      padding: const EdgeInsets.all(24),
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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Code de vérification',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E3A8A),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _codeController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(6),
              ],
              decoration: InputDecoration(
                hintText: 'Entrez votre code 2FA',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF1E3A8A), width: 2),
                ),
                filled: true,
                fillColor: Colors.grey[50],
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Le code est requis';
                }
                if (value.length != 6) {
                  return 'Le code doit contenir 6 chiffres';
                }
                return null;
              },
            ),
            if (errorMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red[600], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        errorMessage!,
                        style: TextStyle(color: Colors.red[600]),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            Obx(() => ElevatedButton(
              onPressed: twoFactorController.isVerifying.value ? null : _handleSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              child: twoFactorController.isVerifying.value
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      'Désactiver 2FA',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            )),
            const SizedBox(height: 16),
            // Afficher les erreurs du contrôleur
            Obx(() => twoFactorController.errorMessage.value.isNotEmpty
                ? Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red[600], size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            twoFactorController.errorMessage.value,
                            style: TextStyle(color: Colors.red[600]),
                          ),
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink()),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Get.back(),
              child: Text(
                'Annuler',
                style: const TextStyle(
                  color: Color(0xFF1E3A8A),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 