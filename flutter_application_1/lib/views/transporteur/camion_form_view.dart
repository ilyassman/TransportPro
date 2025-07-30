import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/transporteur_controller.dart';
import '../chargeur/map_picker_view.dart';
import '../../services/translation_service.dart';
import '../../models/camion_model.dart';

class CamionFormView extends StatefulWidget {
  const CamionFormView({super.key});

  @override
  State<CamionFormView> createState() => _CamionFormViewState();
}

class _CamionFormViewState extends State<CamionFormView> {
  final _formKey = GlobalKey<FormState>();
  final _marqueController = TextEditingController();
  final _modeleController = TextEditingController();
  final _immatriculationController = TextEditingController();
  final _capaciteController = TextEditingController();
  final _adresseController = TextEditingController();
  String _selectedType = 'FTL';
  double? _latitude;
  double? _longitude;
  bool _isEditing = false;
  
  final List<String> _types = [
    'FTL', // Full Truck Load
    'LTL', // Less Than Truck Load
    'Frigorifique',
    'Plateau',
    'Benne',
    'Citerne'
  ];

  String _getText(String key) {
    return TranslationService.getText(key);
  }

  @override
  void initState() {
    super.initState();
    _loadExistingCamionData();
  }

  void _loadExistingCamionData() {
    final controller = Get.put(TransporteurController());
    
    // Attendre que le contrôleur soit initialisé
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (controller.hasCamion.value && controller.camion.value != null) {
        final existingCamion = controller.camion.value!;
        _isEditing = true;
        
        setState(() {
          _marqueController.text = existingCamion.marque;
          _modeleController.text = existingCamion.modele;
          _immatriculationController.text = existingCamion.immatriculation;
          _capaciteController.text = existingCamion.capacite.toString();
          _selectedType = existingCamion.type;
          _latitude = existingCamion.latitude;
          _longitude = existingCamion.longitude;
          _adresseController.text = 'Emplacement actuel'; // Vous pouvez améliorer cela avec un geocoding inverse
        });
      }
    });
  }

  @override
  void dispose() {
    _marqueController.dispose();
    _modeleController.dispose();
    _immatriculationController.dispose();
    _capaciteController.dispose();
    _adresseController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    // Vérifier que la localisation est sélectionnée
    if (_latitude == null || _longitude == null) {
      Get.snackbar(
        'Erreur',
        'Veuillez sélectionner l\'emplacement du camion sur la carte',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    try {
      final controller = Get.put(TransporteurController());
      bool success;
      
      if (_isEditing) {
        // Mise à jour du camion existant
        success = await controller.updateCamion(
          marque: _marqueController.text,
          modele: _modeleController.text,
          immatriculation: _immatriculationController.text,
          capacite: double.parse(_capaciteController.text),
          type: _selectedType,
          latitude: _latitude!,
          longitude: _longitude!,
        );
      } else {
        // Création d'un nouveau camion
        success = await controller.createCamion(
          marque: _marqueController.text,
          modele: _modeleController.text,
          immatriculation: _immatriculationController.text,
          capacite: double.parse(_capaciteController.text),
          type: _selectedType,
          latitude: _latitude!,
          longitude: _longitude!,
        );
      }

      if (success) {
        Get.snackbar(
          'Succès',
          _isEditing 
              ? 'Votre camion a été mis à jour avec succès'
              : 'Votre camion a été enregistré avec succès',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        Get.offAllNamed('/transporteur-main');
      } else {
        Get.snackbar(
          'Erreur',
          _isEditing 
              ? 'Erreur lors de la mise à jour du camion'
              : 'Erreur lors de l\'enregistrement du camion',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Une erreur est survenue: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Dégradé de fond subtil
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFF5F7FA), Color(0xFFE3E9F9), Color(0xFFD1D8F1)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          SingleChildScrollView(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 20,
              bottom: MediaQuery.of(context).padding.bottom + 100, // Augmenté pour éviter le débordement
            ),
            child: Column(
              children: [
                // Header glassmorphism
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.10),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                    border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
                    backgroundBlendMode: BlendMode.overlay,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Color(0xFF1E3A8A), size: 28),
                        onPressed: () => Get.back(),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          _isEditing ? 'Modifier votre camion' : 'Enregistrer votre camion',
                          style: const TextStyle(
                            color: Color(0xFF1E3A8A),
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                            fontFamily: 'Montserrat',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Formulaire
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1E3A8A).withOpacity(0.10),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Image ou icône
                        Container(
                          height: 100,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E3A8A).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Icon(
                            _isEditing ? Icons.edit : Icons.local_shipping,
                            size: 50,
                            color: const Color(0xFF1E3A8A),
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        Text(
                          _isEditing ? 'Modifier les informations' : 'Informations du camion',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E3A8A),
                            fontFamily: 'Montserrat',
                          ),
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Marque
                        _buildFormField(
                          controller: _marqueController,
                          label: 'Marque',
                          icon: Icons.branding_watermark,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Veuillez entrer la marque';
                            }
                            return null;
                          },
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Modèle
                        _buildFormField(
                          controller: _modeleController,
                          label: 'Modèle',
                          icon: Icons.directions_car,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Veuillez entrer le modèle';
                            }
                            return null;
                          },
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Immatriculation
                        _buildFormField(
                          controller: _immatriculationController,
                          label: 'Immatriculation',
                          icon: Icons.confirmation_number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Veuillez entrer l\'immatriculation';
                            }
                            return null;
                          },
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Capacité
                        _buildFormField(
                          controller: _capaciteController,
                          label: 'Capacité (tonnes)',
                          icon: Icons.scale,
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Veuillez entrer la capacité';
                            }
                            if (double.tryParse(value) == null) {
                              return 'Veuillez entrer un nombre valide';
                            }
                            return null;
                          },
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Type de camion
                        _buildDropdownField(),
                        
                        const SizedBox(height: 16),
                        
                        // Adresse et localisation
                        _buildFormField(
                          controller: _adresseController,
                          label: 'Adresse du camion',
                          icon: Icons.location_on,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Veuillez sélectionner l\'adresse';
                            }
                            return null;
                          },
                          readOnly: true,
                          onTap: _selectLocation,
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.map, color: Color(0xFF1E3A8A)),
                            onPressed: _selectLocation,
                          ),
                        ),
                        
                        if (_latitude != null && _longitude != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              'Coordonnées: ${_latitude!.toStringAsFixed(6)}, ${_longitude!.toStringAsFixed(6)}',
                              style: const TextStyle(
                                color: Colors.green,
                                fontSize: 12,
                                fontFamily: 'Montserrat',
                              ),
                            ),
                          ),
                        
                        const SizedBox(height: 24),
                        
                        // Bouton de soumission
                        Obx(() {
                          try {
                            final controller = Get.put(TransporteurController());
                            return _animatedButton(
                              onPressed: controller.isLoading.value ? null : _submitForm,
                              child: controller.isLoading.value
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : Text(
                                      _isEditing ? 'Mettre à jour le camion' : 'Enregistrer le camion',
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Montserrat'),
                                    ),
                            );
                          } catch (e) {
                            return _animatedButton(
                              onPressed: _submitForm,
                              child: Text(
                                _isEditing ? 'Mettre à jour le camion' : 'Enregistrer le camion',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Montserrat'),
                              ),
                            );
                          }
                        }),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String? Function(String?) validator,
    TextInputType? keyboardType,
    bool readOnly = false,
    VoidCallback? onTap,
    Widget? suffixIcon,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      readOnly: readOnly,
      onTap: onTap,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF1E3A8A)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: const Color(0xFF1E3A8A).withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF1E3A8A), width: 2),
        ),
        prefixIcon: Icon(icon, color: const Color(0xFF1E3A8A)),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.white.withOpacity(0.8),
        labelStyle: const TextStyle(
          color: Color(0xFF1E3A8A),
          fontFamily: 'Montserrat',
        ),
      ),
      style: const TextStyle(
        fontFamily: 'Montserrat',
        color: Color(0xFF1E3A8A),
      ),
      validator: validator,
    );
  }

  Widget _buildDropdownField() {
    return DropdownButtonFormField<String>(
      value: _selectedType,
      decoration: InputDecoration(
        labelText: 'Type de camion',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF1E3A8A)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: const Color(0xFF1E3A8A).withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF1E3A8A), width: 2),
        ),
        prefixIcon: const Icon(Icons.category, color: Color(0xFF1E3A8A)),
        filled: true,
        fillColor: Colors.white.withOpacity(0.8),
        labelStyle: const TextStyle(
          color: Color(0xFF1E3A8A),
          fontFamily: 'Montserrat',
        ),
      ),
      items: _types.map((String type) {
        return DropdownMenuItem<String>(
          value: type,
          child: Text(type, style: const TextStyle(fontFamily: 'Montserrat')),
        );
      }).toList(),
      onChanged: (String? newValue) {
        setState(() {
          _selectedType = newValue!;
        });
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Veuillez sélectionner un type';
        }
        return null;
      },
      style: const TextStyle(
        fontFamily: 'Montserrat',
        color: Color(0xFF1E3A8A),
      ),
    );
  }

  Widget _animatedButton({required VoidCallback? onPressed, required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16), // Ajout d'une marge en bas
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: const Color(0xFF1E3A8A),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1E3A8A).withOpacity(0.13),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: onPressed,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
              child: Center(child: child),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _selectLocation() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const MapPickerView(title: 'Sélectionner l\'emplacement du camion'),
      ),
    );
    
    if (result != null && result['address'] != null && result['latlng'] != null) {
      setState(() {
        _adresseController.text = result['address'];
        _latitude = result['latlng'].latitude;
        _longitude = result['latlng'].longitude;
      });
    }
  }
} 