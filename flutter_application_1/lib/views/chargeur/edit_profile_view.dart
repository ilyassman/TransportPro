import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../services/profile_service.dart';
import '../../services/translation_service.dart';
import 'profile_view.dart'; // Import correct pour ProfileView

class EditProfileView extends StatefulWidget {
  const EditProfileView({Key? key}) : super(key: key);

  @override
  State<EditProfileView> createState() => _EditProfileViewState();
}

class _EditProfileViewState extends State<EditProfileView> {
  final ProfileService _profileService = ProfileService();
  final _formKey = GlobalKey<FormState>();
  
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _companyNameController = TextEditingController();
  
  Map<String, dynamic>? _profileData;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _companyNameController.dispose();
    super.dispose();
  }

  Future<void> _loadProfileData() async {
    try {
      setState(() => _isLoading = true);
      final profile = await _profileService.getProfile();
      setState(() {
        _profileData = profile;
        _isLoading = false;
      });
      
      // Remplir les champs avec les données existantes
      _firstNameController.text = profile['firstName'] ?? '';
      _lastNameController.text = profile['lastName'] ?? '';
      _phoneController.text = profile['phone'] ?? '';
      _companyNameController.text = profile['companyName'] ?? '';
      
    } catch (e) {
      setState(() => _isLoading = false);
      print('Erreur lors du chargement du profil: $e');
    }
  }

  String _getText(String key) {
    return TranslationService.getText(key);
  }

  Future<void> _handleSave() async {
    print("=== DÉBUT _handleSave ===");
    
    if (!_formKey.currentState!.validate()) {
      print("Validation du formulaire échouée");
      return;
    }

    print("Validation du formulaire réussie");
    print("firstName: ${_firstNameController.text}");
    print("lastName: ${_lastNameController.text}");
    print("phone: ${_phoneController.text}");
    print("companyName: ${_companyNameController.text}");

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      print("Appel de _profileService.updateProfile");
      final response = await _profileService.updateProfile(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        phone: _phoneController.text.trim(),
        companyName: _companyNameController.text.trim(),
      );

      print("Réponse reçue: $response");

      if (response['success'] == true) {
        print("Succès - Affichage du snackbar");
        // Notifier que le profil a été mis à jour
        Get.snackbar(
          'Succès',
          'Profil mis à jour avec succès',
          backgroundColor: const Color(0xFF10B981),
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
          snackPosition: SnackPosition.TOP,
          margin: const EdgeInsets.all(16),
          borderRadius: 8,
          icon: const Icon(
            Icons.check_circle,
            color: Colors.white,
          ),
          onTap: (snack) {
            print("Snackbar tapé");
          },
        );
        
        print("Attente avant retour au profil");
        // Attendre un peu avant de retourner au profil
        await Future.delayed(const Duration(milliseconds: 500));
        
        print("Retour au profil avec succès");
        // Retourner au profil avec succès
        Get.back(result: true);
      } else {
        print("Erreur dans la réponse: ${response['message']}");
        setState(() {
          _errorMessage = response['message'] ?? 'Erreur lors de la mise à jour';
        });
      }
    } catch (e) {
      print("Exception capturée: $e");
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      print("Fin de _handleSave");
      setState(() {
        _isSaving = false;
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
        title: const Text(
          'Modifier le profil',
          style: TextStyle(
            color: Color(0xFF1E3A8A),
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (!_isLoading)
            TextButton(
              onPressed: _isSaving ? null : () {
                print("=== BOUTON ENREGISTRER CLIQUÉ ===");
                _handleSave();
              },
              child: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1E3A8A)),
                      ),
                    )
                  : const Text(
                      'Enregistrer',
                      style: TextStyle(
                        color: Color(0xFF1E3A8A),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1E3A8A)),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildProfileHeader(),
                    const SizedBox(height: 24),
                    _buildForm(),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 16),
                      _buildErrorMessage(),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E3A8A).withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
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
              Icons.edit,
              size: 40,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Modifier les informations',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E3A8A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Mettez à jour vos informations personnelles',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E3A8A).withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Informations personnelles',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E3A8A),
            ),
          ),
          const SizedBox(height: 20),
          
          // Prénom
          _buildTextField(
            controller: _firstNameController,
            label: 'Prénom',
            hint: 'Entrez votre prénom',
            icon: Icons.person_outline,
          ),
          
          const SizedBox(height: 16),
          
          // Nom
          _buildTextField(
            controller: _lastNameController,
            label: 'Nom',
            hint: 'Entrez votre nom',
            icon: Icons.person_outline,
          ),
          
          const SizedBox(height: 16),
          
          // Téléphone
          _buildTextField(
            controller: _phoneController,
            label: 'Téléphone',
            hint: 'Entrez votre numéro de téléphone',
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
          ),
          
          const SizedBox(height: 16),
          
          // Nom de l'entreprise
          _buildTextField(
            controller: _companyNameController,
            label: 'Nom de l\'entreprise',
            hint: 'Entrez le nom de votre entreprise',
            icon: Icons.business_outlined,
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E3A8A),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType ?? TextInputType.text,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(
              icon,
              color: const Color(0xFF1E3A8A),
            ),
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
            if (value == null || value.trim().isEmpty) {
              return '$label est requis';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildErrorMessage() {
    return Container(
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
              _errorMessage!,
              style: TextStyle(color: Colors.red[600]),
            ),
          ),
        ],
      ),
    );
  }
} 