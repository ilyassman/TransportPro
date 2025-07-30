import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../services/profile_service.dart';
import '../../services/translation_service.dart';
import '../../controllers/auth_controller.dart';
//import 'edit_profile_view.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({Key? key}) : super(key: key);

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  final ProfileService _profileService = ProfileService();
  final AuthController _authController = AuthController();
  
  Map<String, dynamic>? _profileData;
  bool _isLoading = true;
  String? _username;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  // Méthode pour recharger les données du profil
  void refreshProfile() {
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    try {
      setState(() => _isLoading = true);
      final profile = await _profileService.getProfile();
      final username = await _profileService.getCurrentUsername();
      setState(() {
        _profileData = profile;
        _username = username;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      print('Erreur lors du chargement du profil: $e');
    }
  }

  String _getText(String key) {
    return TranslationService.getText(key);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
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
                : _buildProfileContent(),
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

  Widget _buildProfileContent() {
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 20,
        bottom: MediaQuery.of(context).padding.bottom + 100,
      ),
      child: Column(
        children: [
          // Header avec photo de profil
          _buildProfileHeader(),
          const SizedBox(height: 24),
          
          // Informations du profil
          _buildProfileInfo(),
          const SizedBox(height: 24),
          
          // Actions
          _buildProfileActions(),
          const SizedBox(height: 24),
          
          // Section sécurité
          _buildSecuritySection(),
          const SizedBox(height: 24),
          
          // Bouton de déconnexion
          _buildLogoutButton(),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.blueGrey.withOpacity(0.15),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Photo de profil
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1E3A8A).withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Center(
              child: Text(
                _getInitials(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Montserrat',
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Nom complet
          Text(
            _getFullName(),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
              fontFamily: 'Montserrat',
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          
          // Username
          Text(
            '@${_username ?? 'transporteur'}',
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF64748B),
              fontFamily: 'Montserrat',
            ),
          ),
          const SizedBox(height: 12),
          
          // Badge transporteur
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF1E3A8A).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF1E3A8A).withOpacity(0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.local_shipping,
                  color: Color(0xFF1E3A8A),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Transporteur',
                  style: const TextStyle(
                    color: Color(0xFF1E3A8A),
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    fontFamily: 'Montserrat',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileInfo() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.blueGrey.withOpacity(0.15),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Titre de section
          Row(
            children: [
              const Icon(
                Icons.person_outline,
                color: Color(0xFF1E3A8A),
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Informations personnelles',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                  fontFamily: 'Montserrat',
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Informations
          _buildInfoRow('Nom', _profileData?['firstName'] ?? 'Non renseigné'),
          _buildInfoRow('Prénom', _profileData?['lastName'] ?? 'Non renseigné'),
          _buildInfoRow('Email', _profileData?['email'] ?? 'Non renseigné'),
          _buildInfoRow('Téléphone', _profileData?['phone'] ?? 'Non renseigné'),
          _buildInfoRow('Entreprise', _profileData?['companyName'] ?? 'Non renseigné'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF64748B),
                fontFamily: 'Montserrat',
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF1E293B),
                fontWeight: FontWeight.w500,
                fontFamily: 'Montserrat',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileActions() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.blueGrey.withOpacity(0.15),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Titre de section
          Row(
            children: [
              const Icon(
                Icons.settings_outlined,
                color: Color(0xFF1E3A8A),
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Actions',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                  fontFamily: 'Montserrat',
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Bouton modifier le profil
          _buildActionButton(
            icon: Icons.edit_outlined,
            title: 'Modifier le profil',
            subtitle: 'Modifier vos informations personnelles',
            onTap: () => _navigateToEditProfile(),
          ),
          const SizedBox(height: 12),
          
          // Bouton documents
          _buildActionButton(
            icon: Icons.description_outlined,
            title: 'Mes documents',
            subtitle: 'Gérer vos documents',
            onTap: () => _navigateToDocuments(),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E3A8A).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: const Color(0xFF1E3A8A),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E293B),
                          fontFamily: 'Montserrat',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF64748B),
                          fontFamily: 'Montserrat',
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  color: Color(0xFF64748B),
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSecuritySection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.blueGrey.withOpacity(0.15),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Titre de section
          Row(
            children: [
              const Icon(
                Icons.security_outlined,
                color: Color(0xFF1E3A8A),
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Sécurité',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                  fontFamily: 'Montserrat',
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Statut 2FA
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Authentification à deux facteurs',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E293B),
                        fontFamily: 'Montserrat',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _profileData?['twoFactorEnabled'] == true 
                          ? 'Activée'
                          : 'Non activée',
                      style: TextStyle(
                        fontSize: 14,
                        color: _profileData?['twoFactorEnabled'] == true 
                            ? Colors.green
                            : const Color(0xFF64748B),
                        fontFamily: 'Montserrat',
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _profileData?['twoFactorEnabled'] == true 
                      ? Colors.green.withOpacity(0.1)
                      : Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _profileData?['twoFactorEnabled'] == true 
                        ? Colors.green
                        : Colors.grey,
                  ),
                ),
                child: Text(
                  _profileData?['twoFactorEnabled'] == true 
                      ? 'Sécurisé'
                      : 'Non sécurisé',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _profileData?['twoFactorEnabled'] == true 
                        ? Colors.green
                        : Colors.grey,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _handleLogout,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.logout, size: 20),
              const SizedBox(width: 8),
              Text(
                'Se déconnecter',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Montserrat',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getInitials() {
    final firstName = _profileData?['firstName'] ?? '';
    final lastName = _profileData?['lastName'] ?? '';
    
    if (firstName.isNotEmpty && lastName.isNotEmpty) {
      return '${firstName[0]}${lastName[0]}'.toUpperCase();
    } else if (firstName.isNotEmpty) {
      return firstName[0].toUpperCase();
    } else if (lastName.isNotEmpty) {
      return lastName[0].toUpperCase();
    } else {
      return 'T';
    }
  }

  String _getFullName() {
    final firstName = _profileData?['firstName'] ?? '';
    final lastName = _profileData?['lastName'] ?? '';
    
    if (firstName.isNotEmpty && lastName.isNotEmpty) {
      return '$firstName $lastName';
    } else if (firstName.isNotEmpty) {
      return firstName;
    } else if (lastName.isNotEmpty) {
      return lastName;
    } else {
      return 'Transporteur';
    }
  }

  void _navigateToEditProfile() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const ProfileView(),
      ),
    ).then((_) {
      // Recharger les données après retour
      refreshProfile();
    });
  }

  void _navigateToDocuments() {
    // Navigation vers la page documents (à implémenter)
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Page documents en cours de développement'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _authController.logout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Déconnecter'),
          ),
        ],
      ),
    );
  }
} 