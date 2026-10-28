import 'package:flutter/material.dart';
import '../services/enrollment_service.dart';
import '../services/insforge_service.dart';
import 'enrollment/welcome_screen.dart';
import 'home/agent_home_screen.dart';

class SplashGate extends StatefulWidget {
  const SplashGate({super.key});

  @override
  State<SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<SplashGate> {
  bool _isLoading = true;
  bool _isEnrolled = false;

  @override
  void initState() {
    super.initState();
    _initAgent();
  }

  Future<void> _initAgent() async {
    try {
      await InsforgeService.instance.initialize();
      final enrolled = await EnrollmentService.instance.checkEnrollment();
      if (mounted) {
        setState(() {
          _isEnrolled = enrolled;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Agent init error: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_isEnrolled) {
      return const AgentHomeScreen();
    } else {
      return const WelcomeScreen();
    }
  }
}
