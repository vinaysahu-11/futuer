import 'package:insforge_flutter/insforge_flutter.dart';
import 'insforge_service.dart';

/// Authentication service interfacing with InsForge Auth.
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  /// Gets the InsForge client instance.
  InsforgeClient get _client => InsforgeService.instance.client;

  /// Returns the currently signed-in user, or null if signed out.
  User? get currentUser =>
      InsforgeService.instance.isConnected ? _client.auth.currentUser : null;

  /// Returns true if a user session is currently active.
  bool get isAuthenticated => currentUser != null;

  /// Stream of authentication state changes.
  Stream<AuthState>? get onAuthStateChange =>
      InsforgeService.instance.isConnected ? _client.auth.onAuthStateChange : null;

  /// Signs up a new user with email and password.
  Future<SignUpResponse> signUp({
    required String email,
    required String password,
    String? name,
  }) async {
    return await _client.auth.signUp(
      email: email.trim(),
      password: password,
      name: name?.trim(),
    );
  }

  /// Signs in an existing user with email and password.
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _client.auth.signIn(
      email: email.trim(),
      password: password,
    );
  }

  /// Signs out the current user session.
  Future<void> signOut() async {
    if (InsforgeService.instance.isConnected) {
      await _client.auth.signOut();
    }
  }
}
