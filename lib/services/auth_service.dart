import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:insforge_flutter/insforge_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'insforge_service.dart';

/// Authentication service interfacing with InsForge Auth.
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  static const _storage = FlutterSecureStorage();
  static const _keyPkceVerifier = 'futuer_pkce_verifier';

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

  /// Initiates Google OAuth using InsForge PKCE authorization flow.
  Future<void> signInWithGoogle({String? customRedirectUri}) async {
    if (!InsforgeService.instance.isConnected) {
      throw StateError('InsForge is not connected.');
    }

    // 1. Generate cryptographic PKCE verifier and challenge
    final verifier = PkceHelper.generateCodeVerifier();
    final challenge = PkceHelper.codeChallenge(verifier);

    // 2. Persist verifier securely to exchange once callback returns
    await _storage.write(key: _keyPkceVerifier, value: verifier);

    // 3. Determine redirect URI: use origin on web, and custom app scheme on Android
    final redirect = customRedirectUri ??
        (kIsWeb
            ? '${Uri.base.scheme}://${Uri.base.host}${Uri.base.hasPort ? ':${Uri.base.port}' : ''}/'
            : 'futuer://callback');

    // 4. Request Google authorization URL from InsForge
    final authUrl = await _client.auth.getOAuthUrl(
      provider: OAuthProvider.google,
      redirectUri: redirect,
      codeChallenge: challenge,
    );

    // 5. Navigate to provider URL
    final uri = Uri.parse(authUrl);
    if (kIsWeb) {
      await launchUrl(uri, webOnlyWindowName: '_self');
    } else {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  /// Completes the OAuth flow if an insforge_code query parameter is present.
  Future<bool> handleOAuthCallbackIfPresent(Uri uri) async {
    if (!uri.queryParameters.containsKey('insforge_code')) {
      return false;
    }

    final verifier = await _storage.read(key: _keyPkceVerifier);
    if (verifier == null || verifier.isEmpty) {
      debugPrint('No PKCE verifier found for returning OAuth exchange.');
      return false;
    }

    try {
      await _client.auth.handleOAuthCallback(uri, verifier);
      await _storage.delete(key: _keyPkceVerifier);
      return true;
    } catch (e) {
      debugPrint('Failed to handle OAuth callback: $e');
      return false;
    }
  }

  /// Signs out the current user session.
  Future<void> signOut() async {
    if (InsforgeService.instance.isConnected) {
      await _client.auth.signOut();
    }
  }
}
