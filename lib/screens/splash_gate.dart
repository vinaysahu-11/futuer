import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:insforge_flutter/insforge_flutter.dart';
import '../services/auth_service.dart';
import '../services/enrollment_service.dart';
import '../services/insforge_service.dart';
import '../services/role_service.dart';
import 'link/home/link_status_screen.dart';
import 'link/intro/link_intro_screen.dart';
import 'link/pairing/link_pairing_screen.dart';
import 'owner/auth/owner_auth_screen.dart';
import 'owner/dashboard/owner_dashboard_screen.dart';
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
        final exchanged = await AuthService.instance.handleOAuthCallbackIfPresent(Uri.base);
        if (exchanged) {
          debugPrint('Google OAuth callback processed successfully.');
        }
      }

      // 2. Load configured role
      var role = await RoleService.instance.loadConfiguredRole();

      // 3. Check enrollment state for link
      await EnrollmentService.instance.checkEnrollment();

      // Ensure authenticated user never gets stranded on role selection
      if (AuthService.instance.isAuthenticated && role == FutuerRole.none) {
        if (EnrollmentService.instance.cachedDeviceId != null) {
          await RoleService.instance.setConfiguredRole(FutuerRole.link);
        } else {
          // An authenticated user logging in via Google/Email without existing link enrollment is an Owner
          await RoleService.instance.setConfiguredRole(FutuerRole.owner);
        }
      }

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

    // A: Enrolled Link device always goes directly to Link Status Screen
    if (isDeviceEnrolled) {
      return const LinkStatusScreen();
    }

    // B: Authenticated User routing
    if (isAuth) {
      if (role == FutuerRole.link) {
        return const LinkPairingScreen();
      }
      // Any authenticated user not enrolled as link device opens Owner Dashboard
      return const OwnerDashboardScreen();
    }

    // C: Unauthenticated configured roles
    if (role == FutuerRole.owner) {
      return const OwnerAuthScreen();
    }
    if (role == FutuerRole.link) {
      return const LinkIntroScreen();
    }

    // D: Default to Role Selection (Welcome Screen)
    return const RoleSelectionScreen();
  }
}
