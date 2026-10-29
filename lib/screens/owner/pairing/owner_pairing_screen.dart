import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../config/theme.dart';
import '../../../models/pairing_request.dart';
import '../../../services/device_service.dart';

class OwnerPairingScreen extends StatefulWidget {
  const OwnerPairingScreen({super.key});

  @override
  State<OwnerPairingScreen> createState() => _OwnerPairingScreenState();
}

class _OwnerPairingScreenState extends State<OwnerPairingScreen> {
  final _nameController = TextEditingController(text: 'My Android Device');
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
        deviceName: _nameController.text.trim().isNotEmpty
            ? _nameController.text.trim()
            : 'My Android Device',
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

    // Poll status every 3 seconds to see if target device consumed the code
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
                  Text('Device Linked!'),
                ],
              ),
              content: Text(
                '${updated.deviceName} has successfully paired and is now linked to your Futuer Owner account.',
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

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _cancelPairing();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Pair New Device', style: TextStyle(fontWeight: FontWeight.bold)),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: _cancelPairing,
          ),
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
                    // Instructions
                    Text(
                      'Link a Device to Futuer',
                      style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Open the Futuer app on the secondary device, choose "Futuer Link" and enter this temporary pairing code.',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),

                    // Device Name Input
                    TextField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Device Label',
                        hintText: 'e.g. My Tablet, Samsung S21',
                        prefixIcon: const Icon(Icons.label_outline),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.refresh),
                          tooltip: 'Regenerate code with this label',
                          onPressed: _isGenerating ? null : _generateCode,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Pairing Code Box
                    if (_isGenerating)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (_error != null)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                        ),
                        child: Column(
                          children: [
                            const Icon(Icons.error_outline, color: Colors.red, size: 36),
                            const SizedBox(height: 8),
                            Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
                            const SizedBox(height: 12),
                            FilledButton(
                              onPressed: _generateCode,
                              child: const Text('Try Again'),
                            ),
                          ],
                        ),
                      )
                    else if (_request != null) ...[
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey.shade900 : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isExpired
                                ? Colors.red.withValues(alpha: 0.4)
                                : FutuerTheme.brandSecondary.withValues(alpha: 0.4),
                            width: 2,
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'SINGLE-USE PAIRING CODE',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 12),
                            SelectableText(
                              _request!.pairingCode,
                              style: TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 6,
                                color: isExpired ? Colors.red : FutuerTheme.brandSecondary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.timer_outlined,
                                  size: 16,
                                  color: isExpired ? Colors.red : Colors.grey,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  isExpired
                                      ? 'Code Expired'
                                      : 'Expires in ${_formatCountdown(_secondsRemaining)}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: isExpired ? Colors.red : Colors.grey.shade700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            OutlinedButton.icon(
                              icon: const Icon(Icons.copy, size: 16),
                              label: const Text('Copy Code'),
                              onPressed: isExpired
                                  ? null
                                  : () {
                                      Clipboard.setData(ClipboardData(text: _request!.pairingCode));
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Pairing code copied to clipboard')),
                                      );
                                    },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Waiting Status Row
                      if (!isExpired)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Waiting for "${_request!.deviceName}" to link...',
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                              ),
                            ),
                          ],
                        )
                      else
                        Center(
                          child: FilledButton.icon(
                            icon: const Icon(Icons.refresh),
                            label: const Text('Generate New Code'),
                            onPressed: _generateCode,
                          ),
                        ),
                    ],

                    const SizedBox(height: 32),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: _cancelPairing,
                      child: const Text('Cancel Pairing'),
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
