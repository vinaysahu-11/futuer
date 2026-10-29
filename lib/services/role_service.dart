import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'auth_service.dart';
import 'enrollment_service.dart';

enum FutuerRole {
  none,
  owner, // Futuer Owner (controls and manages enrolled devices)
  link,  // Futuer Link (device that is enrolled and managed by an authorized Owner)
}

class RoleService {
  RoleService._();
  static final RoleService instance = RoleService._();

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      resetOnError: true,
    ),
  );
  static const String _keyConfiguredRole = 'futuer_configured_role';

  final ValueNotifier<FutuerRole> currentRoleNotifier = ValueNotifier<FutuerRole>(FutuerRole.none);

  FutuerRole get currentRole => currentRoleNotifier.value;
  bool get hasRole => currentRole != FutuerRole.none;
  bool get isOwner => currentRole == FutuerRole.owner;
  bool get isLink => currentRole == FutuerRole.link;

  // Legacy aliases for backward compatibility during refactoring
  bool get isController => isOwner;
  bool get isAgent => isLink;

  /// Loads the stored role from secure storage with safe timeout
  Future<FutuerRole> loadConfiguredRole() async {
    try {
      final roleStr = await _storage
          .read(key: _keyConfiguredRole)
          .timeout(const Duration(seconds: 2), onTimeout: () => null);
      if (roleStr == 'owner' || roleStr == 'controller') {
        currentRoleNotifier.value = FutuerRole.owner;
      } else if (roleStr == 'link' || roleStr == 'agent') {
        currentRoleNotifier.value = FutuerRole.link;
      } else {
        currentRoleNotifier.value = FutuerRole.none;
      }
    } catch (e) {
      debugPrint('Failed to read configured role: $e');
      currentRoleNotifier.value = FutuerRole.none;
    }
    return currentRoleNotifier.value;
  }

  /// Sets and persists the configured role immediately in memory, then writes to storage with safe timeout
  Future<void> setConfiguredRole(FutuerRole role) async {
    currentRoleNotifier.value = role;
    try {
      if (role == FutuerRole.owner) {
        await _storage
            .write(key: _keyConfiguredRole, value: 'owner')
            .timeout(const Duration(seconds: 2), onTimeout: () {});
      } else if (role == FutuerRole.link) {
        await _storage
            .write(key: _keyConfiguredRole, value: 'link')
            .timeout(const Duration(seconds: 2), onTimeout: () {});
      } else {
        await _storage
            .delete(key: _keyConfiguredRole)
            .timeout(const Duration(seconds: 2), onTimeout: () {});
      }
    } catch (e) {
      debugPrint('Warning: Failed to persist configured role: $e');
    }
  }

  /// Safely clears the role, signing out and clearing device credentials
  Future<void> resetRole() async {
    currentRoleNotifier.value = FutuerRole.none;
    try {
      await AuthService.instance.signOut();
      await EnrollmentService.instance.unpair();
      await _storage
          .delete(key: _keyConfiguredRole)
          .timeout(const Duration(seconds: 2), onTimeout: () {});
    } catch (e) {
      debugPrint('Error resetting role: $e');
    }
  }
}
