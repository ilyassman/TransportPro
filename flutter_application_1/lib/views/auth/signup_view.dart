import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../services/translation_service.dart';
import '../../services/signup_service.dart';
import '../../controllers/auth_controller.dart';

class TransportSignupPage extends StatefulWidget {
  const TransportSignupPage({Key? key}) : super(key: key);

  @override
  State<TransportSignupPage> createState() => _TransportSignupPageState();
}

class _TransportSignupPageState extends State<TransportSignupPage>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _companyNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  final AuthController authController = Get.put(AuthController());
  final SignupService signupService = SignupService();
  
  bool _isPasswordObscured = true;
  bool _isConfirmPasswordObscured = true;
  bool _isLoading = false;
  bool _isArabic = false;
  bool _acceptTerms = false;
  String? _errorMessage;
  String _userType = 'chargeur';
  
  // Variables pour la force du mot de passe
  bool _hasLength = false;
  bool _hasUppercase = false;
  bool _hasLowercase = false;
  bool _hasDigit = false;
  bool _hasSpecial = false;
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));
    
    _animationController.forward();
    
    // Écouter les changements du mot de passe
    _passwordController.addListener(_checkPasswordStrength);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _companyNameController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _toggleLanguage() async {
    await TranslationService.toggleLanguage();
    setState(() {
      _isArabic = TranslationService.isArabic;
    });
  }

  String _getText(String key) {
    return TranslationService.getText(key);
  }

  void _checkPasswordStrength() {
    final password = _passwordController.text;
    setState(() {
      _hasLength = password.length >= 8;
      _hasUppercase = password.contains(RegExp(r'[A-Z]'));
      _hasLowercase = password.contains(RegExp(r'[a-z]'));
      _hasDigit = password.contains(RegExp(r'[0-9]'));
      _hasSpecial = password.contains(RegExp(r'[.!@#$&*~]'));
    });
  }

  String _getPasswordStrength() {
    final requirements = [_hasLength, _hasUppercase, _hasLowercase, _hasDigit, _hasSpecial];
    final metRequirements = requirements.where((req) => req).length;
    
    if (metRequirements < 3) return _getText('password_strength_weak');
    if (metRequirements < 4) return _getText('password_strength_medium');
    if (metRequirements < 5) return _getText('password_strength_strong');
    return _getText('password_strength_very_strong');
  }

  Color _getPasswordStrengthColor() {
    final requirements = [_hasLength, _hasUppercase, _hasLowercase, _hasDigit, _hasSpecial];
    final metRequirements = requirements.where((req) => req).length;
    
    if (metRequirements < 3) return Colors.red;
    if (metRequirements < 4) return Colors.orange;
    if (metRequirements < 5) return Colors.yellow[700]!;
    return Colors.green;
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  bool _isValidPhone(String phone) {
    // Format international ou local marocain
    return RegExp(r'^(\+212|0)?[567]\d{8}$').hasMatch(phone.replaceAll(' ', ''));
  }

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_acceptTerms) {
      setState(() {
        _errorMessage = _getText('terms_required');
      });
      return;
    }
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      // Appel du service d'inscription
      final result = await signupService.signup(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        companyName: _companyNameController.text.trim(),
        username: _usernameController.text.trim(),
        password: _passwordController.text,
        userType: _userType,
      );
      
      // Succès avec message d'activation
      Get.snackbar(
        _getText('success'),
        _getText('activation_email_sent_message'),
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
      );
      
      // Navigation vers la page de connexion
      Get.offAllNamed('/login');
      
    } catch (e) {
      String errorMessage;
      
      // Gestion des erreurs spécifiques
      switch (e.toString()) {
        case 'Exception: username_already_exists':
          errorMessage = _getText('username_already_exists');
          break;
        case 'Exception: email_already_exists':
          errorMessage = _getText('email_already_exists');
          break;
        case 'Exception: user_already_exists':
          errorMessage = _getText('user_already_exists');
          break;
        case 'Exception: invalid_data':
          errorMessage = _getText('invalid_data');
          break;
        case 'Exception: validation_error':
          errorMessage = _getText('validation_error');
          break;
        case 'Exception: signup_error':
          errorMessage = _getText('signup_error');
          break;
        default:
          errorMessage = _getText('general_error');
      }
      
      setState(() {
        _errorMessage = errorMessage;
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
                  _buildSignupForm(),
                  _buildFooter(),
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
    return Container(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        children: [
          // Bouton de langue
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              GestureDetector(
                onTap: _toggleLanguage,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.language,
                        size: 16,
                        color: const Color(0xFF1E3A8A),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _isArabic ? 'العربية' : 'Français',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E3A8A),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 30),
          
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
              Icons.local_shipping,
              size: 35,
              color: Colors.white,
            ),
          ),
          
          const SizedBox(height: 12),
          
          Text(
            _getText('TransportPro'),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E3A8A),
            ),
          ),
          
          const SizedBox(height: 4),
          
          Text(
            _getText('platform_description'),
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignupForm() {
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
            // Titre d'inscription
            Text(
              _getText('signup_title'),
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E3A8A),
              ),
            ),
            
            const SizedBox(height: 6),
            
            Text(
              _getText('signup_subtitle'),
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Sélection du type d'utilisateur
            _buildUserTypeSelector(),
            
            const SizedBox(height: 20),
            
            // Champs personnels
            _buildPersonalInfoSection(),
            
            const SizedBox(height: 20),
            
            // Champs de connexion
            _buildLoginInfoSection(),
            
            const SizedBox(height: 20),
            
            // Conditions d'utilisation
            _buildTermsSection(),
            
            const SizedBox(height: 20),
            
            // Bouton d'inscription
            _buildSignupButton(),
            
            const SizedBox(height: 16),
            
            // Lien de connexion
            _buildLoginLink(),
            
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
          ],
        ),
      ),
    );
  }

  Widget _buildUserTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _getText('account_type'),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _userType = 'chargeur'),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: _userType == 'chargeur' 
                        ? const Color(0xFF1E3A8A) 
                        : Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _userType == 'chargeur' 
                          ? const Color(0xFF1E3A8A) 
                          : Colors.grey[300]!,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.business,
                        size: 18,
                        color: _userType == 'chargeur' 
                            ? Colors.white 
                            : Colors.grey[600],
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _getText('shipper'),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _userType == 'chargeur' 
                              ? Colors.white 
                              : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _userType = 'transporteur'),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: _userType == 'transporteur' 
                        ? const Color(0xFF1E3A8A) 
                        : Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _userType == 'transporteur' 
                          ? const Color(0xFF1E3A8A) 
                          : Colors.grey[300]!,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.local_shipping,
                        size: 18,
                        color: _userType == 'transporteur' 
                            ? Colors.white 
                            : Colors.grey[600],
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _getText('carrier'),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _userType == 'transporteur' 
                              ? Colors.white 
                              : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPersonalInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Informations personnelles',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 16),
        
        // Prénom et Nom
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: _firstNameController,
                label: _getText('first_name_label'),
                hint: _getText('first_name_hint'),
                icon: Icons.person_outline,
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
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTextField(
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
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Email
        _buildTextField(
          controller: _emailController,
          label: _getText('email_label'),
          hint: _getText('email_hint'),
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return _getText('email_required');
            }
            if (!_isValidEmail(value)) {
              return _getText('email_invalid');
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
          icon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return _getText('phone_required');
            }
            if (!_isValidPhone(value)) {
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
          icon: Icons.business_outlined,
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
      ],
    );
  }

  Widget _buildLoginInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Informations de connexion',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 16),
        
        // Nom d'utilisateur
        _buildTextField(
          controller: _usernameController,
          label: _getText('username_label'),
          hint: _getText('username_hint'),
          icon: Icons.person_outline,
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
        
        const SizedBox(height: 16),
        
        // Mot de passe
        _buildPasswordField(),
        
        const SizedBox(height: 12),
        
        // Indicateur de force du mot de passe
        _buildPasswordStrengthIndicator(),
        
        const SizedBox(height: 16),
        
        // Confirmation du mot de passe
        _buildConfirmPasswordField(),
      ],
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType ?? TextInputType.text,
          textDirection: TextDirection.ltr,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: const Color(0xFF6B7280)),
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
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _getText('password_label'),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _passwordController,
          obscureText: _isPasswordObscured,
          textDirection: TextDirection.ltr,
          decoration: InputDecoration(
            hintText: _getText('password_hint'),
            prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF6B7280)),
            suffixIcon: GestureDetector(
              onTap: () => setState(() => _isPasswordObscured = !_isPasswordObscured),
              child: Icon(
                _isPasswordObscured ? Icons.visibility_off : Icons.visibility,
                color: const Color(0xFF6B7280),
              ),
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
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return _getText('password_required');
            }
            if (!_hasLength) {
              return _getText('password_length_error');
            }
            if (!_hasUppercase) {
              return _getText('password_uppercase_error');
            }
            if (!_hasLowercase) {
              return _getText('password_lowercase_error');
            }
            if (!_hasDigit) {
              return _getText('password_digit_error');
            }
            if (!_hasSpecial) {
              return _getText('password_special_error');
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildPasswordStrengthIndicator() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                _getText('password_requirements'),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF374151),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getPasswordStrengthColor(),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _getPasswordStrength(),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildRequirementRow(_getText('password_requirement_length'), _hasLength),
          _buildRequirementRow(_getText('password_requirement_uppercase'), _hasUppercase),
          _buildRequirementRow(_getText('password_requirement_lowercase'), _hasLowercase),
          _buildRequirementRow(_getText('password_requirement_digit'), _hasDigit),
          _buildRequirementRow(_getText('password_requirement_special'), _hasSpecial),
        ],
      ),
    );
  }

  Widget _buildRequirementRow(String text, bool isMet) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            isMet ? Icons.check_circle : Icons.circle_outlined,
            size: 16,
            color: isMet ? Colors.green : Colors.grey[400],
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              color: isMet ? Colors.green[700] : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
          controller: _confirmPasswordController,
          obscureText: _isConfirmPasswordObscured,
          textDirection: TextDirection.ltr,
          decoration: InputDecoration(
            hintText: _getText('confirm_password_hint'),
            prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF6B7280)),
            suffixIcon: GestureDetector(
              onTap: () => setState(() => _isConfirmPasswordObscured = !_isConfirmPasswordObscured),
              child: Icon(
                _isConfirmPasswordObscured ? Icons.visibility_off : Icons.visibility,
                color: const Color(0xFF6B7280),
              ),
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
      ],
    );
  }

  Widget _buildTermsSection() {
    return Row(
      children: [
        Checkbox(
          value: _acceptTerms,
          onChanged: (value) => setState(() => _acceptTerms = value ?? false),
          activeColor: const Color(0xFF1E3A8A),
        ),
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _acceptTerms = !_acceptTerms),
            child: Text(
              _getText('terms_conditions'),
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF6B7280),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSignupButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleSignup,
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
                _getText('signup_button'),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  Widget _buildLoginLink() {
    return Center(
      child: RichText(
        text: TextSpan(
          text: _getText('already_have_account'),
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
          children: [
            WidgetSpan(
              child: GestureDetector(
                onTap: () {
                  Get.offAllNamed('/login');
                },
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