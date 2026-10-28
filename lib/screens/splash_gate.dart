import 'dart:async';
import 'package:flutter/material.dart';
import 'package:insforge_flutter/insforge_flutter.dart';
import '../services/auth_service.dart';
import '../services/insforge_service.dart';
import 'auth_screen.dart';
import 'connection_screen.dart';
import 'home_screen.dart';

/// Gatekeeper widget that dynamically routes between:
/// 1. ConnectionScreen (when no InsForge ID / credentials provided)
/// 2. AuthScreen (when connected to InsForge, but user is logged out)
/// 3. HomeScreen (when connected and user is logged in)
class SplashGate extends StatefulWidget {
  const SplashGate({super.key});

  @override
  State<SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<SplashGate> {
  bool _isChecking = true;
  StreamSubscription<AuthState>? _authSubscription;

  @override
  void initState() {
    super.initState();
    _initGate();
    InsforgeService.instance.isConnectedNotifier.addListener(_onConnectionChanged);
  }

  @override
  void dispose() {
    InsforgeService.instance.isConnectedNotifier.removeListener(_onConnectionChanged);
    _authSubscription?.cancel();
    super.dispose();
  }

  void _onConnectionChanged() {
    _subscribeToAuth();
    if (mounted) setState(() {});
  }

  Future<void> _initGate() async {
    await InsforgeService.instance.initializeFromSavedOrConfig();
    _subscribeToAuth();
    if (mounted) {
      setState(() {
        _isChecking = false;
      });
    }
  }

  void _subscribeToAuth() {
    _authSubscription?.cancel();
    _authSubscription = AuthService.instance.onAuthStateChange?.listen((state) {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final isConnected = InsforgeService.instance.isConnected;

    // 1. Not connected or no ID supplied yet
    if (!isConnected) {
      return const ConnectionScreen();
    }

    // 2. Connected: Check auth state
    final isAuthenticated = AuthService.instance.isAuthenticated;
    if (isAuthenticated) {
      return const HomeScreen();
    } else {
      return const AuthScreen();
    }
  }
}
