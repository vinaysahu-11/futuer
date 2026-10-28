import 'package:flutter/material.dart';
import 'config/theme.dart';
import 'screens/splash_gate.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const FutuerApp());
}

class FutuerApp extends StatelessWidget {
  const FutuerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Futuer',
      debugShowCheckedModeBanner: false,
      theme: FutuerTheme.lightTheme,
      darkTheme: FutuerTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const SplashGate(),
    );
  }
}
