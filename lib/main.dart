import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:permission_handler/permission_handler.dart';
import 'screens/onboarding_screen.dart';
import 'screens/dashboard_screen.dart';
import 'providers/app_provider.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb) {
    await Firebase.initializeApp();
    // Initialize local notifications
    await NotificationService().init();
    // Request microphone + phone-state permissions before any service starts.
    await [Permission.microphone, Permission.phone].request();
  }
  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => AppProvider())],
      child: const SafeCallApp(),
    ),
  );
}

class SafeCallApp extends StatelessWidget {
  const SafeCallApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Safe-Call AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1A73E8),
          brightness: Brightness.dark,
        ),
        textTheme: GoogleFonts.notoSansTextTheme(ThemeData.dark().textTheme),
        useMaterial3: true,
      ),
      home: const OnboardingScreen(),
      routes: {'/dashboard': (context) => const DashboardScreen()},
    );
  }
}
