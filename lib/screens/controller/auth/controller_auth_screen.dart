import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import '../../../services/auth_service.dart';
import '../../../services/role_service.dart';
import '../../role_selection_screen.dart';

class ControllerAuthScreen extends StatefulWidget {
  const ControllerAuthScreen({super.key});

  @override
  State<ControllerAuthScreen> createState() => _ControllerAuthScreenState();
}

class _ControllerAuthScreenState extends State<ControllerAuthScreen> {
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
        await RoleService.instance.setConfiguredRole(FutuerRole.controller);
        // Note: SplashGate stream handles navigation upon auth change
      } else if (_modeIndex == 1) {
        // Create Account
        await AuthService.instance.signUp(
          email: _emailController.text,
          password: _passwordController.text,
          name: _nameController.text.trim().isNotEmpty ? _nameController.text.trim() : null,
        );
        await RoleService.instance.setConfiguredRole(FutuerRole.controller);
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

  void _confirmChangeRole() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Change App Role?'),
        content: const Text('Do you want to go back and choose between Controller and Managed Device?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await RoleService.instance.resetRole();
              if (!mounted) return;
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
              );
            },
            child: const Text('Change Role'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Futuer Controller'),
        actions: [
          TextButton.icon(
            onPressed: _confirmChangeRole,
            icon: const Icon(Icons.swap_horiz, size: 18),
            label: const Text('Change Role'),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Controller Brand Header
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: FutuerTheme.brandSecondary.withValues(alpha: 0.15),
                          border: Border.all(
                            color: FutuerTheme.brandSecondary.withValues(alpha: 0.4),
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.admin_panel_settings_rounded,
                          size: 48,
                          color: FutuerTheme.brandSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'FUTUER CONTROLLER',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.0,
                        color: FutuerTheme.brandSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _modeIndex == 0
                          ? 'Sign in to monitor your enrolled device'
                          : _modeIndex == 1
                              ? 'Create a new Futuer Controller account'
                              : 'Recover your account password',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Mode Toggle Buttons
                    SegmentedButton<int>(
                      segments: const [
                        ButtonSegment(value: 0, label: Text('Sign In')),
                        ButtonSegment(value: 1, label: Text('Register')),
                        ButtonSegment(value: 2, label: Text('Forgot')),
                      ],
                      selected: {_modeIndex},
                      onSelectionChanged: (val) => _switchMode(val.first),
                    ),
                    const SizedBox(height: 24),

                    // Status Messages
                    if (_errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
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
                      const SizedBox(height: 16),
                    ],

                    if (_successMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
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
                      const SizedBox(height: 16),
                    ],

                    // Full Name (Only for Register)
                    if (_modeIndex == 1) ...[
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Your Name',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],

                    // Email Field
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email Address',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      validator: (val) =>
                          val != null && val.contains('@') ? null : 'Enter a valid email address',
                    ),
                    const SizedBox(height: 14),

                    // Password Field (Sign In and Register)
                    if (_modeIndex != 2) ...[
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                            ),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                        validator: (val) =>
                            val != null && val.length >= 6 ? null : 'Password must be at least 6 characters',
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Action Button
                    FilledButton(
                      onPressed: _isLoading ? null : _handleSubmit,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: FutuerTheme.brandSecondary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Text(
                              _modeIndex == 0
                                  ? 'Sign In to Controller'
                                  : _modeIndex == 1
                                      ? 'Create Controller Account'
                                      : 'Send Recovery Email',
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                    ),
                    const SizedBox(height: 24),

                    // Role switch text button
                    Center(
                      child: TextButton.icon(
                        onPressed: _confirmChangeRole,
                        icon: const Icon(Icons.swap_horiz, size: 16),
                        label: const Text('Need to set up this phone as a Managed Device?'),
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
