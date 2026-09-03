import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/theme.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase initialize notice: $e (Dev mode fallback enabled)');
  }
  runApp(const GemBidderApp());
}

class GemBidderApp extends StatelessWidget {
  const GemBidderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GeM Bidder Compliance Verification',
      debugShowCheckedModeBanner: false,
      theme: GemTheme.lightTheme,
      home: const SplashScreen(),
    );
  }
}
