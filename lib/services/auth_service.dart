import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:insforge_flutter/insforge_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'insforge_service.dart';

/// Authentication service interfacing with InsForge Auth.
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      resetOnError: true,
    ),
  );
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

  /// Auto verifies email in the backend to ensure zero email verification friction.
  Future<void> autoVerifyEmail(String email) async {
    try {
      if (email.trim().isNotEmpty) {
        await _client.database.rpc('verify_user_by_email', args: {
          'p_email': email.trim(),
        }).execute();
      }
    } catch (e) {
      debugPrint('Auto-verify email background note: $e');
    }
  }

  /// Signs up a new user with email and password, auto-verifies, and signs in seamlessly.
  /// If user already exists, transparently signs in.
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    String? name,
  }) async {
    final cleanEmail = email.trim();
    try {
      // 1. Create account
      await _client.auth.signUp(
        email: cleanEmail,
        password: password,
        name: name?.trim(),
      );
    } catch (e) {
      final err = e.toString().toLowerCase();
      // If already registered, proceed to sign in directly
      if (!err.contains('already') && !err.contains('exists') && !err.contains('duplicate')) {
        rethrow;
      }
    }

    // 2. Ensure email_verified = true in backend
    await autoVerifyEmail(cleanEmail);

    // 3. Immediately sign in so user enters app without any friction
    return await signIn(
      email: cleanEmail,
      password: password,
    );
  }

  /// Signs in an existing user with email and password, handling auto-verification if needed.
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    final cleanEmail = email.trim();
    try {
      return await _client.auth.signIn(
        email: cleanEmail,
        password: password,
      );
    } catch (e) {
      final errStr = e.toString().toLowerCase();
      // If email verification was demanded by backend, auto-verify and retry once
      if (errStr.contains('verification') || errStr.contains('verified') || errStr.contains('confirm')) {
        debugPrint('Auto-resolving email verification requirement for $cleanEmail...');
        await autoVerifyEmail(cleanEmail);
        return await _client.auth.signIn(
          email: cleanEmail,
          password: password,
        );
      }
      rethrow;
    }
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

  /// Checks if a returning URI has an OAuth callback code in query parameters or fragment.
  Future<bool> handleOAuthCallbackIfPresent(Uri uri) async {
    String? code = uri.queryParameters['insforge_code'] ?? uri.queryParameters['code'];

    // Also check inside fragment if Flutter Web hash routing is used (e.g. /#/?insforge_code=...)
    if ((code == null || code.isEmpty) && uri.fragment.contains('?')) {
      final fragmentQuery = uri.fragment.substring(uri.fragment.indexOf('?') + 1);
      final fragmentParams = Uri.splitQueryString(fragmentQuery);
      code = fragmentParams['insforge_code'] ?? fragmentParams['code'];
    }

    if (code == null || code.isEmpty) {
      return false;
    }

    final verifier = await _storage.read(key: _keyPkceVerifier);
    if (verifier == null || verifier.isEmpty) {
      debugPrint('No PKCE verifier found for returning OAuth exchange.');
      return false;
    }

    try {
      // Ensure the URI has insforge_code in its queryParameters for SDK parser
      final effectiveUri = uri.queryParameters.containsKey('insforge_code')
          ? uri
          : uri.replace(queryParameters: {
              ...uri.queryParameters,
              'insforge_code': code,
            });

      await _client.auth.handleOAuthCallback(effectiveUri, verifier);
      await _storage.delete(key: _keyPkceVerifier);
      return true;
    } catch (e) {
      debugPrint('Failed to handle OAuth callback: $e');
      // If code was already exchanged, ignore and let session restore handle it
      return false;
    }
  }

  /// Checks if an authenticated user is already registered as an Owner with linked devices.
  Future<bool> isUserAnOwner(String userId) async {
    try {
      final rows = await _client.database
          .from('devices')
          .select('id')
          .eq('owner_user_id', userId)
          .limit(1)
          .execute();
      if (rows.isNotEmpty) return true;

      final reqs = await _client.database
          .from('pairing_requests')
          .select('id')
          .eq('controller_user_id', userId)
          .limit(1)
          .execute();
      return reqs.isNotEmpty;
    } catch (_) {
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
