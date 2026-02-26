import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart' as app_auth;
import 'providers/listing_provider.dart';
import 'services/auth_service.dart';
import 'services/listing_service.dart';
import 'services/review_service.dart';
import 'utils/constants.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/email_verification_screen.dart';
import 'screens/home/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const KigaliCityDirectoryApp());
}

class KigaliCityDirectoryApp extends StatelessWidget {
  const KigaliCityDirectoryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<app_auth.AuthProvider>(
          create: (_) => app_auth.AuthProvider(AuthService()),
        ),
        ChangeNotifierProvider<ListingProvider>(
          create: (_) => ListingProvider(ListingService(), ReviewService()),
        ),
      ],
      child: MaterialApp(
        title: 'Kigali City Directory',
        debugShowCheckedModeBanner: false,
        theme: appTheme(),
        home: const AppRouter(),
      ),
    );
  }
}

class AppRouter extends StatelessWidget {
  const AppRouter({super.key});

  @override
  Widget build(BuildContext context) {
    final authProv = context.watch<app_auth.AuthProvider>();

    switch (authProv.status) {
      case app_auth.AuthStatus.unknown:
        return const _SplashScreen();

      case app_auth.AuthStatus.unauthenticated:
        return const LoginScreen();

      case app_auth.AuthStatus.unverified:
        return EmailVerificationScreen(
          email: authProv.userModel?.email ?? 'your registered email',
        );

      case app_auth.AuthStatus.authenticated:
        return const HomeScreen();
    }
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.15),
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(
                Icons.location_city_rounded,
                color: AppColors.accent,
                size: 50,
              ),
            ),
            const SizedBox(height: 24),
            const Text('Kigali City Directory', style: AppTextStyles.heading1),
            const SizedBox(height: 8),
            const Text(
              'Discover services near you',
              style: AppTextStyles.bodySecondary,
            ),
            const SizedBox(height: 40),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.accent),
              strokeWidth: 2.5,
            ),
          ],
        ),
      ),
    );
  }
}
