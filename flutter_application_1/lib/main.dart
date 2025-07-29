import 'package:flutter/material.dart';
import 'package:flutter_application_1/services/utils/user_binding.dart';
import 'package:flutter_application_1/services/utils/profile_binding.dart';
import 'package:flutter_application_1/services/utils/two_factor_binding.dart';
import 'package:flutter_application_1/views/auth/login_view.dart';
import 'package:flutter_application_1/views/auth/reset_password_view.dart';
import 'package:get/get.dart';
import 'package:easy_localization/easy_localization.dart';
import 'services/translation_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_1/views/auth/forgot_password_view.dart';
import 'package:flutter_application_1/views/auth/two_factor_login_view.dart';
import 'package:flutter_application_1/views/auth/two_factor_setup_view.dart';
import 'package:flutter_application_1/views/auth/two_factor_disable_view.dart';
import 'package:flutter_application_1/views/chargeur/edit_profile_view.dart';
import 'package:flutter_application_1/views/auth/signup_view.dart';
import 'package:flutter_application_1/views/auth/account_activation_view.dart';
import 'package:flutter_application_1/views/profile_view.dart';
import 'views/chargeur/chargeur_home_view.dart';
import 'views/transporteur/transporteur_home_view.dart';
import 'services/profile_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await TranslationService.initializeLanguage();
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('access_token') ?? '';
  String initialRoute = '/login';
  if (token.isNotEmpty) {
    try {
      final profileService = ProfileService();
      final profile = await profileService.getProfile();
      final userType = profile['userType'];
      if (userType == 'chargeur') {
        initialRoute = '/chargeur-home';
      } else if (userType == 'transporteur') {
        initialRoute = '/transporteur-home';
      }
    } catch (e) {
      initialRoute = '/login';
    }
  }
  runApp(MyApp(initialRoute: initialRoute, token: token));
}

class MyApp extends StatefulWidget {
  final String initialRoute;
  final String token;
  const MyApp({Key? key, required this.initialRoute, required this.token}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Mon App',
      initialRoute: widget.initialRoute,
      getPages: [
        GetPage(
          name: '/login',
          page: () => TransportLoginPage(),
        ),
        GetPage(
          name: '/signup',
          page: () => const TransportSignupPage(),
        ),
        GetPage(
          name: '/account-activation',
          page: () => const AccountActivationView(),
        ),
        GetPage(
          name: '/forgot',
          page: () => ForgotPasswordPage(),
        ),
        // Pour reset_pass, il faut passer le username en argument
        GetPage(
          name: '/reset_pass',
          page: () {
            final args = Get.arguments;
            final username = args is String ? args : (args?['username'] ?? '');
            return ResetPasswordPage(username: username);
          },
        ),
        GetPage(
          name: '/two-factor-login',
          page: () => const TwoFactorLoginView(),
          binding: TwoFactorBinding(widget.token),
        ),
        GetPage(
          name: '/two-factor-setup',
          page: () => const TwoFactorSetupView(),
          binding: TwoFactorBinding(widget.token),
        ),
        GetPage(
          name: '/two-factor-disable',
          page: () => const TwoFactorDisableView(),
          binding: TwoFactorBinding(widget.token),
        ),
        GetPage(
          name: '/profile',
          page: () => const ProfileView(),
          binding: ProfileBinding(),
        ),
        GetPage(
          name: '/chargeur-home',
          page: () => const ChargeurHomeView(),
        ),
        GetPage(
          name: '/transporteur-home',
          page: () => const TransporteurHomeView(),
        ),
        GetPage(
          name: '/edit-profile',
          page: () => const EditProfileView(),
          binding: ProfileBinding(),
        ),

      ],
      locale: TranslationService.isArabic ? const Locale('ar') : const Locale('fr'),
      fallbackLocale: const Locale('fr'),
      debugShowCheckedModeBanner: false,
    );
  }
}
