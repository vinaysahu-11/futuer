import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'auth_service.dart';
import 'enrollment_service.dart';

enum FutuerRole {
  none,
  controller,
  agent,
}

class RoleService {
  RoleService._();
  static final RoleService instance = RoleService._();

  static const _storage = FlutterSecureStorage();
  static const String _keyConfiguredRole = 'futuer_configured_role';

  final ValueNotifier<FutuerRole> currentRoleNotifier = ValueNotifier<FutuerRole>(FutuerRole.none);

  FutuerRole get currentRole => currentRoleNotifier.value;
  bool get hasRole => currentRole != FutuerRole.none;
  bool get isController => currentRole == FutuerRole.controller;
  bool get isAgent => currentRole == FutuerRole.agent;

  /// Loads the stored role from secure storage
  Future<FutuerRole> loadConfiguredRole() async {
    try {
      final roleStr = await _storage.read(key: _keyConfiguredRole);
      if (roleStr == 'controller') {
        currentRoleNotifier.value = FutuerRole.controller;
      } else if (roleStr == 'agent') {
        currentRoleNotifier.value = FutuerRole.agent;
      } else {
        currentRoleNotifier.value = FutuerRole.none;
      }
    } catch (e) {
      debugPrint('Failed to read configured role: $e');
      currentRoleNotifier.value = FutuerRole.none;
    }
    return currentRoleNotifier.value;
  }

  /// Sets and persists the configured role
  Future<void> setConfiguredRole(FutuerRole role) async {
    currentRoleNotifier.value = role;
    if (role == FutuerRole.controller) {
      await _storage.write(key: _keyConfiguredRole, value: 'controller');
    } else if (role == FutuerRole.agent) {
      await _storage.write(key: _keyConfiguredRole, value: 'agent');
    } else {
      await _storage.delete(key: _keyConfiguredRole);
    }
  }

  /// Safely clears the role, signing out and clearing device credentials
  Future<void> resetRole() async {
    try {
      await AuthService.instance.signOut();
      await EnrollmentService.instance.unpair();
      await _storage.delete(key: _keyConfiguredRole);
    } catch (e) {
      debugPrint('Error resetting role: $e');
    } finally {
      currentRoleNotifier.value = FutuerRole.none;
    }
  }
}
