import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:insforge_flutter/insforge_flutter.dart';
import '../services/auth_service.dart';
import '../services/enrollment_service.dart';
import '../services/insforge_service.dart';
import '../services/role_service.dart';
import 'agent/home/agent_status_screen.dart';
import 'agent/intro/agent_intro_screen.dart';
import 'agent/pairing/agent_pairing_screen.dart';
import 'controller/auth/controller_auth_screen.dart';
import 'controller/dashboard/controller_dashboard_screen.dart';
import 'role_selection_screen.dart';

class SplashGate extends StatefulWidget {
  const SplashGate({super.key});

  @override
  State<SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<SplashGate> {
  bool _isInitializing = true;
  StreamSubscription<AuthState>? _authSubscription;

  @override
  void initState() {
    super.initState();
    _initApp();
    RoleService.instance.currentRoleNotifier.addListener(_onStateChanged);
  }

  @override
  void dispose() {
    RoleService.instance.currentRoleNotifier.removeListener(_onStateChanged);
    _authSubscription?.cancel();
    super.dispose();
  }

  void _onStateChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _initApp() async {
    try {
      // 1. Initialize backend connection
      await InsforgeService.instance.initializeFromSavedOrConfig();

      // Check for returning OAuth callback (Google Login redirect)
      if (kIsWeb) {
        await AuthService.instance.handleOAuthCallbackIfPresent(Uri.base);
      }

      // 2. Load configured role
      await RoleService.instance.loadConfiguredRole();

      // 3. Check enrollment state for agent
      await EnrollmentService.instance.checkEnrollment();

      // 4. Subscribe to auth changes
      _authSubscription = AuthService.instance.onAuthStateChange?.listen((_) {
        if (mounted) setState(() {});
      });
    } catch (e) {
      debugPrint('Initialization error in SplashGate: $e');
    } finally {
      if (mounted) {
        setState(() => _isInitializing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final role = RoleService.instance.currentRole;
    final isAuth = AuthService.instance.isAuthenticated;
    final isDeviceEnrolled = EnrollmentService.instance.cachedDeviceId != null;

    // A: No role configured yet -> Show Welcome & Role Selection
    if (role == FutuerRole.none) {
      return const RoleSelectionScreen();
    }

    // B: Controller Flow
    if (role == FutuerRole.controller) {
      if (isAuth) {
        return const ControllerDashboardScreen();
      } else {
        return const ControllerAuthScreen();
      }
    }

    // C: Managed Device (Agent) Flow
    if (role == FutuerRole.agent) {
      if (isDeviceEnrolled) {
        return const AgentStatusScreen();
      } else if (isAuth) {
        return const AgentPairingScreen();
      } else {
        return const AgentIntroScreen();
      }
    }

    return const RoleSelectionScreen();
  }
}
