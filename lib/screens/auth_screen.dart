import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/insforge_service.dart';

/// Screen managing User Sign In & Sign Up with InsForge Auth.
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  final _signInFormKey = GlobalKey<FormState>();
  final _signUpFormKey = GlobalKey<FormState>();

  final _signInEmailController = TextEditingController();
  final _signInPasswordController = TextEditingController();

  final _signUpNameController = TextEditingController();
  final _signUpEmailController = TextEditingController();
  final _signUpPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _obscureSignInPassword = true;
  bool _obscureSignUpPassword = true;
  String? _errorMessage;
  String? _infoMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _signInEmailController.dispose();
    _signInPasswordController.dispose();
    _signUpNameController.dispose();
    _signUpEmailController.dispose();
    _signUpPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignIn() async {
    if (!_signInFormKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _infoMessage = null;
    });

    try {
      await AuthService.instance.signIn(
        email: _signInEmailController.text,
        password: _signInPasswordController.text,
      );
      // Auth state listener handles navigation
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Sign in failed: ${e.toString()}';
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

  Future<void> _handleSignUp() async {
    if (!_signUpFormKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _infoMessage = null;
    });

    try {
      final res = await AuthService.instance.signUp(
        email: _signUpEmailController.text,
        password: _signUpPasswordController.text,
        name: _signUpNameController.text.trim().isNotEmpty
            ? _signUpNameController.text.trim()
            : null,
      );

      if (mounted) {
        if (res.hasSession) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Account created and signed in successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          setState(() {
            _infoMessage =
                'Account created! If email confirmation is enabled on your InsForge project, please verify your email before logging in.';
          });
          _tabController.animateTo(0);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Sign up failed: ${e.toString()}';
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
    final activeUrl = InsforgeService.instance.activeUrl ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('InsForge Authentication'),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Disconnect / Reconfigure Backend',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => _confirmDisconnect(context),
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Active Backend status badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle, size: 16, color: Colors.green),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'Connected: $activeUrl',
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.green.shade800,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: theme.colorScheme.onErrorContainer),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                if (_infoMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _infoMessage!,
                      style: TextStyle(color: theme.colorScheme.onSecondaryContainer),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                TabBar(
                  controller: _tabController,
                  tabs: const [
                    Tab(text: 'Sign In'),
                    Tab(text: 'Create Account'),
                  ],
                ),
                const SizedBox(height: 24),

                SizedBox(
                  height: 340,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // Sign In Tab
                      Form(
                        key: _signInFormKey,
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _signInEmailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: const InputDecoration(
                                labelText: 'Email',
                                prefixIcon: Icon(Icons.email_outlined),
                                border: OutlineInputBorder(),
                              ),
                              validator: (val) =>
                                  val != null && val.contains('@') ? null : 'Enter a valid email',
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _signInPasswordController,
                              obscureText: _obscureSignInPassword,
                              decoration: InputDecoration(
                                labelText: 'Password',
                                prefixIcon: const Icon(Icons.lock_outline),
                                border: const OutlineInputBorder(),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscureSignInPassword
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscureSignInPassword = !_obscureSignInPassword;
                                    });
                                  },
                                ),
                              ),
                              validator: (val) =>
                                  val != null && val.length >= 6 ? null : 'Min 6 characters',
                            ),
                            const SizedBox(height: 24),
                            FilledButton(
                              onPressed: _isLoading ? null : _handleSignIn,
                              style: FilledButton.styleFrom(
                                minimumSize: const Size.fromHeight(50),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text('Sign In'),
                            ),
                          ],
                        ),
                      ),

                      // Sign Up Tab
                      Form(
                        key: _signUpFormKey,
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              TextFormField(
                                controller: _signUpNameController,
                                decoration: const InputDecoration(
                                  labelText: 'Full Name (optional)',
                                  prefixIcon: Icon(Icons.person_outline),
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _signUpEmailController,
                                keyboardType: TextInputType.emailAddress,
                                decoration: const InputDecoration(
                                  labelText: 'Email',
                                  prefixIcon: Icon(Icons.email_outlined),
                                  border: OutlineInputBorder(),
                                ),
                                validator: (val) =>
                                    val != null && val.contains('@') ? null : 'Enter a valid email',
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _signUpPasswordController,
                                obscureText: _obscureSignUpPassword,
                                decoration: InputDecoration(
                                  labelText: 'Password',
                                  prefixIcon: const Icon(Icons.lock_outline),
                                  border: const OutlineInputBorder(),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscureSignUpPassword
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscureSignUpPassword = !_obscureSignUpPassword;
                                      });
                                    },
                                  ),
                                ),
                                validator: (val) =>
                                    val != null && val.length >= 6 ? null : 'Min 6 characters',
                              ),
                              const SizedBox(height: 24),
                              FilledButton(
                                onPressed: _isLoading ? null : _handleSignUp,
                                style: FilledButton.styleFrom(
                                  minimumSize: const Size.fromHeight(50),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text('Create Account'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDisconnect(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Change InsForge Backend?'),
        content: const Text(
          'Disconnecting will clear the current connection settings and return to the backend configuration screen.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await InsforgeService.instance.disconnect();
            },
            child: const Text('Disconnect'),
          ),
        ],
      ),
    );
  }
}
