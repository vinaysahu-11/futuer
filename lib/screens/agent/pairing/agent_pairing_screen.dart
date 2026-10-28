import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import '../../../models/pairing_request.dart';
import '../../../services/enrollment_service.dart';
import '../permissions/agent_permissions_screen.dart';

class AgentPairingScreen extends StatefulWidget {
  const AgentPairingScreen({super.key});

  @override
  State<AgentPairingScreen> createState() => _AgentPairingScreenState();
}

class _AgentPairingScreenState extends State<AgentPairingScreen> {
  final _codeController = TextEditingController();
  bool _isVerifying = false;
  String? _errorMessage;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _handleVerifyCode() async {
    final code = _codeController.text.trim().toUpperCase();
    if (code.isEmpty) {
      setState(() => _errorMessage = 'Please enter the pairing code displayed on Controller.');
      return;
    }

    setState(() {
      _isVerifying = true;
      _errorMessage = null;
    });

    try {
      // 1-5. Format validation, trusted backend verification, expiration & single-use check
      final req = await EnrollmentService.instance.lookupPairingCode(code);

      if (!mounted) return;

      // 6. Ask device owner to confirm displayed pairing details
      _showConfirmationDialog(req);
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('StateError:', '').replaceAll('ArgumentError:', '').trim();
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isVerifying = false);
      }
    }
  }

  void _showConfirmationDialog(PairingRequest req) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.verified, color: FutuerTheme.brandPrimary),
            SizedBox(width: 8),
            Text('Confirm Enrollment'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'A valid pairing request was found for this code:',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('Device Name: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      Text(req.deviceName, style: const TextStyle(fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Text('Pairing Code: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      Text(req.pairingCode, style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Text('Expires In: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      Text('${req.remainingTime.inMinutes} minutes', style: const TextStyle(color: Colors.orange, fontSize: 13)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Do you authorize this phone to be enrolled and managed by the Controller?',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              _finalizeEnrollment(req.pairingCode);
            },
            child: const Text('Authorize & Enroll'),
          ),
        ],
      ),
    );
  }

  Future<void> _finalizeEnrollment(String code) async {
    setState(() {
      _isVerifying = true;
      _errorMessage = null;
    });

    try {
      // 7-9. Register device, atomically mark code as consumed, issue credentials securely
      await EnrollmentService.instance.confirmAndPairDevice(
        pairingCode: code,
        deviceModel: 'Android Phone',
      );

      if (!mounted) return;

      // 10. Navigate to Permissions checklist and then status screen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AgentPermissionsScreen()),
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('StateError:', '').trim();
          _isVerifying = false;
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
        title: const Text('Enter Pairing Code'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: FutuerTheme.brandPrimary.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.pin_outlined,
                        size: 46,
                        color: FutuerTheme.brandPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Pair with Controller',
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Enter the 6-character pairing code shown on your Futuer Controller screen (e.g. FUT-123).',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),

                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 18),
                  ],

                  TextField(
                    controller: _codeController,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 4.0,
                      fontFamily: 'monospace',
                    ),
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      hintText: 'FUT-___',
                      prefixIcon: const Icon(Icons.key),
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 24),

                  FilledButton(
                    onPressed: _isVerifying ? null : _handleVerifyCode,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      backgroundColor: FutuerTheme.brandPrimaryDark,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isVerifying
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text(
                            'Verify Code',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Cancel'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
