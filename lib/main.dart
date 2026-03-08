import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:payparse/core/theme/app_theme.dart';
import 'package:payparse/features/splash/splash_screen.dart';
import 'package:payparse/services/storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize local storage (Hive)
  await StorageService.initialize();

  runApp(const ProviderScope(child: PayParseApp()));
}

class PayParseApp extends StatelessWidget {
  const PayParseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PayParse',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
    );
  }
}
