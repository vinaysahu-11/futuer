import 'dart:async';
import 'package:flutter/material.dart';
import 'package:insforge_flutter/insforge_flutter.dart';
import '../../../config/theme.dart';
import '../../../services/auth_service.dart';
import '../../../services/role_service.dart';
import '../../splash_gate.dart';
import '../pairing/link_pairing_screen.dart';

class LinkAuthScreen extends StatefulWidget {
  const LinkAuthScreen({super.key});

  @override
  State<LinkAuthScreen> createState() => _LinkAuthScreenState();
}

class _LinkAuthScreenState extends State<LinkAuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  int _modeIndex = 0; // 0: Sign In, 1: Register
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;
  StreamSubscription<AuthState>? _authSub;

  @override
  void initState() {
    super.initState();
    _authSub = AuthService.instance.onAuthStateChange?.listen((event) {
      if (AuthService.instance.isAuthenticated && mounted) {
        RoleService.instance.setConfiguredRole(FutuerRole.link);
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LinkPairingScreen()),
          (route) => false,
        );
      }
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (_modeIndex == 0) {
        try {
          await AuthService.instance.signIn(
            email: _emailController.text,
            password: _passwordController.text,
          );
        } catch (signInErr) {
          final errStr = signInErr.toString().toLowerCase();
          if (errStr.contains('invalid credentials') || errStr.contains('not found')) {
            // Seamlessly create account and sign in
            await AuthService.instance.signUp(
              email: _emailController.text,
              password: _passwordController.text,
              name: 'Futuer Link Device User',
            );
          } else {
            rethrow;
          }
        }
      } else {
        await AuthService.instance.signUp(
          email: _emailController.text,
          password: _passwordController.text,
          name: 'Futuer Link Device User',
        );
      }

      await RoleService.instance.setConfiguredRole(FutuerRole.link);

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LinkPairingScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception:', '').replaceAll('StateError:', '').trim();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await RoleService.instance.setConfiguredRole(FutuerRole.link);
      await AuthService.instance.signInWithGoogle();
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception:', '').trim();
          _isLoading = false;
        });
      }
    }
  }

  void _proceedDirectToPairing() async {
    await RoleService.instance.setConfiguredRole(FutuerRole.link);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LinkPairingScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Futuer Link Device Setup'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const SplashGate()),
              );
            }
          },
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Brand Logo
                    Center(
                      child: Container(
                        width: 68,
                        height: 68,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF00B0FF).withValues(alpha: 0.25),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.asset(
                            'assets/images/futuer_logo.png',
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: const Color(0xFF0B1120),
                              child: const Icon(Icons.phonelink_setup_rounded, size: 34, color: Color(0xFF00B0FF)),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Link This Phone',
                      style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'You can pair this phone directly using the 6-digit code from the Owner, or authenticate below.',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),

                    // Quick Pair Option (Recommended - No separate account required!)
                    Card(
                      elevation: 0,
                      color: isDark
                          ? FutuerTheme.brandPrimary.withValues(alpha: 0.12)
                          : FutuerTheme.brandPrimary.withValues(alpha: 0.08),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(
                          color: FutuerTheme.brandPrimary.withValues(alpha: 0.35),
                          width: 1.5,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.flash_on, color: FutuerTheme.brandPrimary, size: 24),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Quick Pair (Recommended)',
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: FutuerTheme.brandPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'No separate account needed. Enter the one-time pairing code from the Owner to link this device instantly.',
                              style: TextStyle(fontSize: 12, height: 1.3),
                            ),
                            const SizedBox(height: 14),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                style: FilledButton.styleFrom(
                                  backgroundColor: FutuerTheme.brandPrimaryDark,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                onPressed: _proceedDirectToPairing,
                                icon: const Icon(Icons.qr_code_2_rounded, size: 18),
                                label: const Text('Enter Pairing Code Now'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(child: Divider(color: isDark ? Colors.grey.shade800 : Colors.grey.shade300)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Text(
                            'OR SIGN IN WITH ACCOUNT',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.8,
                              color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
                            ),
                          ),
                        ),
                        Expanded(child: Divider(color: isDark ? Colors.grey.shade800 : Colors.grey.shade300)),
                      ],
                    ),
                    const SizedBox(height: 16),

                    if (_errorMessage != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: Colors.red, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(color: Colors.red, fontSize: 12.5),
                              ),
                            ),
                          ],
                        ),
                      ),

                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email Address',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      validator: (v) => (v == null || !v.contains('@')) ? 'Enter a valid email' : null,
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      validator: (v) => (v == null || v.length < 6) ? 'Password must be 6+ chars' : null,
                    ),
                    const SizedBox(height: 16),

                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF00B0FF),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: _isLoading ? null : _handleSubmit,
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Text(_modeIndex == 0 ? 'Sign In & Pair' : 'Register & Pair'),
                    ),
                    const SizedBox(height: 12),

                    // Google OAuth Button
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        side: BorderSide(
                          color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                        ),
                      ),
                      onPressed: _isLoading ? null : _handleGoogleSignIn,
                      icon: Image.network(
                        'https://lh3.googleusercontent.com/COxitqgJr1sJnIDe8-jiKhxDx1FrYbtRHKJ9zOIoVjUhRluVj/+W3O1H4/w32-rw',
                        height: 20,
                        width: 20,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.g_mobiledata, size: 24, color: Colors.red),
                      ),
                      label: const Text(
                        'Continue with Google',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                    ),

                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => setState(() => _modeIndex = _modeIndex == 0 ? 1 : 0),
                      child: Text(
                        _modeIndex == 0
                            ? "Don't have an account? Register"
                            : "Already have an account? Sign In",
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
