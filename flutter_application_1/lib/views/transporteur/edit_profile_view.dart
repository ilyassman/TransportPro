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
        Get.back(result: true);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_getText('profile_update_success')),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        print("Échec - Affichage de l'erreur");
        setState(() {
          _errorMessage = response['message'] ?? _getText('profile_update_error');
        });
      }
    } catch (e) {
      print("Exception lors de la mise à jour: $e");
      setState(() {
        _errorMessage = _getText('profile_update_error');
      });
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1E3A8A)),
          onPressed: () => Get.back(),
        ),
        title: Text(
          _getText('edit_profile'),
          style: const TextStyle(
            color: Color(0xFF1E3A8A),
            fontWeight: FontWeight.bold,
            fontFamily: 'Montserrat',
          ),
        ),
      ),
      body: Stack(
        children: [
          // Dégradé de fond
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFF5F7FA), Color(0xFFE3E9F9), Color(0xFFD1D8F1)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          SafeArea(
            child: _isLoading 
                ? _buildLoadingView()
                : _buildEditForm(),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1E3A8A)),
          ),
          SizedBox(height: 16),
          Text(
            'Chargement du profil...',
            style: TextStyle(
              color: Color(0xFF1E3A8A),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header avec avatar
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: const Color(0xFF1E3A8A),
                    child: Text(
                      _profileData?['firstName']?.toString().toUpperCase().substring(0, 1) ?? 'T',
                      style: const TextStyle(
                        fontSize: 40,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _getText('edit_profile_subtitle'),
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF64748B),
                      fontFamily: 'Montserrat',
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Formulaire
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Prénom
                  _buildTextField(
                    controller: _firstNameController,
                    label: _getText('first_name_label'),
                    hint: _getText('first_name_hint'),
                    icon: Icons.person,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return _getText('first_name_required');
                      }
                      if (value.length < 2) {
                        return _getText('first_name_length_error');
                      }
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Nom
                  _buildTextField(
                    controller: _lastNameController,
                    label: _getText('last_name_label'),
                    hint: _getText('last_name_hint'),
                    icon: Icons.person_outline,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return _getText('last_name_required');
                      }
                      if (value.length < 2) {
                        return _getText('last_name_length_error');
                      }
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Téléphone
                  _buildTextField(
                    controller: _phoneController,
                    label: _getText('phone_label'),
                    hint: _getText('phone_hint'),
                    icon: Icons.phone,
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return _getText('phone_required');
                      }
                      if (!RegExp(r'^[0-9+\-\s()]+$').hasMatch(value)) {
                        return _getText('phone_invalid');
                      }
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Nom de l'entreprise
                  _buildTextField(
                    controller: _companyNameController,
                    label: _getText('company_name_label'),
                    hint: _getText('company_name_hint'),
                    icon: Icons.business,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return _getText('company_name_required');
                      }
                      if (value.length < 3) {
                        return _getText('company_name_length_error');
                      }
                      return null;
                    },
                  ),
                  
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.withOpacity(0.3)),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 24),
                  
                  // Bouton de sauvegarde
                  SizedBox(
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _handleSave,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E3A8A),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 2,
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
                              _getText('save'),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Montserrat',
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: const Color(0xFF1E3A8A)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF1E3A8A), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }
} 