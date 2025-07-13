import 'package:shared_preferences/shared_preferences.dart';
import '../translations/fr.dart';
import '../translations/ar.dart';

class TranslationService {
  static bool _isArabic = false;
  static const String _languageKey = 'selected_language';

  static bool get isArabic => _isArabic;

  // Initialiser la langue au démarrage de l'app
  static Future<void> initializeLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLanguage = prefs.getString(_languageKey);
    
    if (savedLanguage != null) {
      _isArabic = savedLanguage == 'ar';
    } else {
      // Par défaut en français
      _isArabic = false;
    }
  }

  // Changer la langue et la sauvegarder
  static Future<void> toggleLanguage() async {
    _isArabic = !_isArabic;
    
    // Sauvegarder la langue choisie
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, _isArabic ? 'ar' : 'fr');
  }

  // Définir une langue spécifique
  static Future<void> setLanguage(bool isArabic) async {
    _isArabic = isArabic;
    
    // Sauvegarder la langue choisie
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, _isArabic ? 'ar' : 'fr');
  }

  static String getText(String key) {
    return _isArabic ? ar[key] ?? key : fr[key] ?? key;
  }
} 