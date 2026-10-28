import 'package:insforge_flutter/insforge_flutter.dart';
import 'insforge_service.dart';

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  InsforgeClient get _client => InsforgeService.instance.client;

  User? get currentUser =>
      InsforgeService.instance.isInitialized ? _client.auth.currentUser : null;

  bool get isAuthenticated => currentUser != null;

  Stream<AuthState>? get onAuthStateChange =>
      InsforgeService.instance.isInitialized ? _client.auth.onAuthStateChange : null;

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

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _client.auth.signIn(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> signOut() async {
    if (InsforgeService.instance.isInitialized) {
      await _client.auth.signOut();
    }
  }
}
