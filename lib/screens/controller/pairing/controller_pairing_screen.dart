import 'dart:async';
import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import '../../../models/pairing_request.dart';
import '../../../services/device_service.dart';

class ControllerPairingScreen extends StatefulWidget {
  const ControllerPairingScreen({super.key});

  @override
  State<ControllerPairingScreen> createState() => _ControllerPairingScreenState();
}

class _ControllerPairingScreenState extends State<ControllerPairingScreen> {
  final _nameController = TextEditingController(text: 'Secondary Phone');
  PairingRequest? _request;
  bool _isGenerating = false;
  String? _error;

  Timer? _countdownTimer;
  Timer? _pollTimer;
  int _secondsRemaining = 600; // 10 minutes

  @override
  void initState() {
    super.initState();
    _generateCode();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _pollTimer?.cancel();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _generateCode() async {
    setState(() {
      _isGenerating = true;
      _error = null;
    });

    try {
      final req = await DeviceService.instance.createPairingRequest(
        deviceName: _nameController.text.trim().isNotEmpty ? _nameController.text.trim() : 'Secondary Phone',
      );

      if (mounted) {
        setState(() {
          _request = req;
          _secondsRemaining = req.remainingTime.inSeconds;
          _isGenerating = false;
        });

        _startTimers(req.id);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('StateError:', '').replaceAll('Exception:', '').trim();
          _isGenerating = false;
        });
      }
    }
  }

  void _startTimers(String requestId) {
    _countdownTimer?.cancel();
    _pollTimer?.cancel();

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        timer.cancel();
        _pollTimer?.cancel();
        setState(() {});
      }
    });

    // Poll status every 3 seconds to see if secondary device consumed the code
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      if (!mounted) return;
      try {
        final updated = await DeviceService.instance.getPairingRequest(requestId);
        if (updated != null && updated.isConsumed) {
          _pollTimer?.cancel();
          _countdownTimer?.cancel();
          if (!mounted) return;

          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green),
                  SizedBox(width: 8),
                  Text('Device Enrolled!'),
                ],
              ),
              content: Text(
                '${updated.deviceName} has successfully enrolled and paired with your Controller.',
              ),
              actions: [
                FilledButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    Navigator.of(context).pop(true);
                  },
                  child: const Text('View Dashboard'),
                ),
              ],
            ),
          );
        }
      } catch (_) {}
    });
  }

  Future<void> _cancelPairing() async {
    if (_request != null) {
      try {
        await DeviceService.instance.cancelPairingRequest(_request!.id);
      } catch (_) {}
    }
    _pollTimer?.cancel();
    _countdownTimer?.cancel();
    if (mounted) Navigator.of(context).pop();
  }

  String _formatCountdown(int totalSeconds) {
    if (totalSeconds <= 0) return '00:00';
    final m = totalSeconds ~/ 60;
    final s = totalSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isExpired = _secondsRemaining <= 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Your Device'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _cancelPairing,
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header icon
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: FutuerTheme.brandSecondary.withValues(alpha: 0.12),
                      ),
                      child: const Icon(
                        Icons.qr_code_2_rounded,
                        size: 48,
                        color: FutuerTheme.brandSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Pair Secondary Phone',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Enter this single-use code on the Futuer Agent app on the secondary device.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 24),

                  if (_error != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        _error!,
                        style: const TextStyle(color: Colors.red, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  if (_isGenerating)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: Column(
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 12),
                            Text('Generating secure pairing code...'),
                          ],
                        ),
                      ),
                    )
                  else if (_request != null) ...[
                    // Large Pairing Code Display
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: isExpired
                              ? Colors.red.withValues(alpha: 0.4)
                              : FutuerTheme.brandSecondary.withValues(alpha: 0.4),
                          width: 2,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                        child: Column(
                          children: [
                            Text(
                              'PAIRING CODE',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 12),
                            SelectableText(
                              _request!.pairingCode,
                              style: TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 4.0,
                                fontFamily: 'monospace',
                                color: isExpired ? Colors.red : FutuerTheme.brandSecondary,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  isExpired ? Icons.timer_off_outlined : Icons.timer_outlined,
                                  size: 16,
                                  color: isExpired ? Colors.red : Colors.orange,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  isExpired
                                      ? 'Code Expired'
                                      : 'Expires in ${_formatCountdown(_secondsRemaining)}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                    color: isExpired ? Colors.red : Colors.orange,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? FutuerTheme.darkSurfaceVariant : Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, size: 20, color: Colors.blue),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Waiting for secondary device to connect. This code can only be used once.',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? Colors.grey.shade300 : Colors.blue.shade900,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 28),

                  if (isExpired) ...[
                    FilledButton.icon(
                      onPressed: _generateCode,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Generate New Code'),
                    ),
                    const SizedBox(height: 12),
                  ],

                  OutlinedButton(
                    onPressed: _cancelPairing,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Cancel Pairing'),
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
