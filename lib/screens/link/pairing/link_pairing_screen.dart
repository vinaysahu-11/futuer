import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import '../../../models/pairing_request.dart';
import '../../../services/enrollment_service.dart';
import '../permissions/link_permissions_screen.dart';

class LinkPairingScreen extends StatefulWidget {
  const LinkPairingScreen({super.key});

  @override
  State<LinkPairingScreen> createState() => _LinkPairingScreenState();
}

class _LinkPairingScreenState extends State<LinkPairingScreen> {
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
      setState(() => _errorMessage = 'Please enter the pairing code displayed on the Futuer Owner screen.');
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

      // 6. Ask device user to confirm displayed pairing details
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
            Text('Confirm Pairing'),
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
                      const Text('Device Label: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
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
              'Do you authorize this phone to be enrolled as a Futuer Link and managed by the Owner?',
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
            child: const Text('Authorize & Link'),
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
      // 7-10. Server-side atomic verification, single-use consumption, device registration
      await EnrollmentService.instance.confirmAndPairDevice(
        pairingCode: code,
        deviceModel: 'Android Phone',
      );

      if (mounted) {
        // Navigate to permissions setup
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LinkPermissionsScreen()),
        );
      }
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pair Device with Owner'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: FutuerTheme.brandPrimary.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.qr_code_2_rounded,
                        size: 32,
                        color: FutuerTheme.brandPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Enter Pairing Code',
                    style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Enter the 6-character code generated on the Futuer Owner device (e.g. FUT-123).',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),

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

                  // Pairing Code Input Field
                  TextField(
                    controller: _codeController,
                    textCapitalization: TextCapitalization.characters,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 6,
                    ),
                    decoration: InputDecoration(
                      hintText: 'FUT-XXX',
                      hintStyle: TextStyle(
                        fontSize: 24,
                        letterSpacing: 4,
                        color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 18),
                    ),
                    onSubmitted: (_) => _handleVerifyCode(),
                  ),
                  const SizedBox(height: 24),

                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: FutuerTheme.brandPrimaryDark,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _isVerifying ? null : _handleVerifyCode,
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

                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
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
