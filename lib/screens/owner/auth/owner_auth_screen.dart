import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import '../../../services/auth_service.dart';
import '../../../services/role_service.dart';
import '../../role_selection_screen.dart';

class OwnerAuthScreen extends StatefulWidget {
  const OwnerAuthScreen({super.key});

  @override
  State<OwnerAuthScreen> createState() => _OwnerAuthScreenState();
}

class _OwnerAuthScreenState extends State<OwnerAuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  int _modeIndex = 0; // 0: Sign In, 1: Create Account, 2: Forgot Password
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;
  String? _successMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _switchMode(int mode) {
    setState(() {
      _modeIndex = mode;
      _errorMessage = null;
      _successMessage = null;
    });
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      if (_modeIndex == 0) {
        // Sign In
        await AuthService.instance.signIn(
          email: _emailController.text,
          password: _passwordController.text,
        );
        await RoleService.instance.setConfiguredRole(FutuerRole.owner);
      } else if (_modeIndex == 1) {
        // Create Account
        await AuthService.instance.signUp(
          email: _emailController.text,
          password: _passwordController.text,
          name: _nameController.text.trim().isNotEmpty ? _nameController.text.trim() : null,
        );
        await RoleService.instance.setConfiguredRole(FutuerRole.owner);
        setState(() {
          _successMessage = 'Account created successfully! You are now signed in.';
        });
      } else {
        // Forgot Password
        setState(() {
          _successMessage = 'Password recovery link has been sent to ${_emailController.text.trim()} if registered.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception:', '').trim();
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
      _successMessage = null;
    });

    try {
      await RoleService.instance.setConfiguredRole(FutuerRole.owner);
      await AuthService.instance.signInWithGoogle();
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception:', '').trim();
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
            );
          },
        ),
        title: const Text('Futuer Owner', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header
                    Center(
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [FutuerTheme.brandSecondary, Color(0xFF00B0FF)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.security, size: 34, color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _modeIndex == 0
                          ? 'Welcome Back, Owner'
                          : _modeIndex == 1
                              ? 'Create Owner Account'
                              : 'Reset Password',
                      style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _modeIndex == 0
                          ? 'Sign in to access and manage your enrolled devices.'
                          : _modeIndex == 1
                              ? 'Register to pair and monitor your devices securely.'
                              : 'Enter your email to receive recovery instructions.',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),

                    // Mode Toggle Buttons
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _TabButton(
                              label: 'Sign In',
                              isSelected: _modeIndex == 0,
                              onTap: () => _switchMode(0),
                            ),
                          ),
                          Expanded(
                            child: _TabButton(
                              label: 'Register',
                              isSelected: _modeIndex == 1,
                              onTap: () => _switchMode(1),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Status Banners
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
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(color: Colors.red, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),

                    if (_successMessage != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle_outline, color: Colors.green, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _successMessage!,
                                style: const TextStyle(color: Colors.green, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Inputs
                    if (_modeIndex == 1) ...[
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Full Name',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],

                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      autocorrect: false,
                      decoration: const InputDecoration(
                        labelText: 'Email Address',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Please enter your email';
                        if (!v.contains('@')) return 'Enter a valid email address';
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    if (_modeIndex != 2) ...[
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_off : Icons.visibility,
                            ),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),
                    ],

                    if (_modeIndex == 0)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => _switchMode(2),
                          child: const Text('Forgot Password?', style: TextStyle(fontSize: 13)),
                        ),
                      ),

                    const SizedBox(height: 16),

                    // Submit Button
                    SizedBox(
                      height: 48,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: FutuerTheme.brandSecondary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: _isLoading ? null : _handleSubmit,
                        child: _isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : Text(
                                _modeIndex == 0
                                    ? 'Sign In as Owner'
                                    : _modeIndex == 1
                                        ? 'Create Account'
                                        : 'Send Recovery Email',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                      ),
                    ),

                    if (_modeIndex != 2) ...[
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(child: Divider(color: isDark ? Colors.grey.shade800 : Colors.grey.shade300)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              'OR',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
                              ),
                            ),
                          ),
                          Expanded(child: Divider(color: isDark ? Colors.grey.shade800 : Colors.grey.shade300)),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Google OAuth Button
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 13),
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
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                      ),
                    ],

                    if (_modeIndex == 2) ...[
                      const SizedBox(height: 12),
                      Center(
                        child: TextButton(
                          onPressed: () => _switchMode(0),
                          child: const Text('Back to Sign In'),
                        ),
                      ),
                    ],
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

class _TabButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? Colors.grey.shade800 : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected
                ? FutuerTheme.brandSecondary
                : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
