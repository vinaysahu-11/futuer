import 'package:flutter/material.dart';
import 'config/theme.dart';
import 'screens/splash_gate.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const FutuerAgentApp());
}

class FutuerAgentApp extends StatelessWidget {
  const FutuerAgentApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Futuer Agent',
      debugShowCheckedModeBanner: false,
      theme: FutuerAgentTheme.lightTheme,
      darkTheme: FutuerAgentTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const SplashGate(),
    );
  }
}
