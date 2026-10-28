import 'dart:async';
import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../models/device_model.dart';
import '../../services/audit_service.dart';
import '../../services/device_service.dart';

class PairDeviceScreen extends StatefulWidget {
  const PairDeviceScreen({super.key});

  @override
  State<PairDeviceScreen> createState() => _PairDeviceScreenState();
}

class _PairDeviceScreenState extends State<PairDeviceScreen> {
  final _nameController = TextEditingController(text: 'Secondary Android Phone');
  bool _isGenerating = false;
  DeviceModel? _pendingDevice;
  Timer? _pollTimer;
  Timer? _countdownTimer;
  int _secondsRemaining = 600; // 10 minutes

  @override
  void dispose() {
    _pollTimer?.cancel();
    _countdownTimer?.cancel();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _generatePairingCode() async {
    setState(() {
      _isGenerating = true;
    });

    try {
      final device = await DeviceService.instance.generatePairingCode(
        deviceName: _nameController.text.trim(),
      );

      await AuditService.instance.log(
        action: 'DEVICE_PAIRING_INITIATED',
        result: 'SUCCESS',
        deviceId: device.id,
      );

      setState(() {
        _pendingDevice = device;
        _secondsRemaining = 600;
      });

      _startTimers(device.id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate code: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
      }
    }
  }

  void _startTimers(String deviceId) {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        if (mounted) setState(() => _secondsRemaining--);
      } else {
        timer.cancel();
        _pollTimer?.cancel();
      }
    });

    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      try {
        final updated = await DeviceService.instance.getDevice(deviceId);
        if (updated != null && updated.isPaired) {
          _pollTimer?.cancel();
          _countdownTimer?.cancel();

          await AuditService.instance.log(
            action: 'DEVICE_PAIRING_COMPLETED',
            result: 'SUCCESS',
            deviceId: updated.id,
          );

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Device "${updated.deviceName}" paired successfully!'),
                backgroundColor: FutuerTheme.onlineColor,
              ),
            );
            Navigator.of(context).pop(true);
          }
        }
      } catch (_) {}
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pair Futuer Agent'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                color: FutuerTheme.brandSecondary.withValues(alpha: 0.1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: FutuerTheme.brandPrimary, size: 28),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          'Install Futuer Agent on the secondary phone you own and authorize. Generate a secure expiring pairing code below to link it.',
                          style: theme.textTheme.bodySmall?.copyWith(height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              if (_pendingDevice == null) ...[
                Text(
                  '1. Assign Device Label',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Device Name',
                    hintText: 'e.g. Samsung Galaxy S23, Pixel 8',
                    prefixIcon: Icon(Icons.phone_android),
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _isGenerating ? null : _generatePairingCode,
                  icon: _isGenerating
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.qr_code_2),
                  label: Text(_isGenerating ? 'Generating...' : 'Generate Pairing Code'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: FutuerTheme.brandSecondary,
                  ),
                ),
              ] else ...[
                Center(
                  child: Column(
                    children: [
                      Text(
                        'PAIRING CODE',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: FutuerTheme.brandPrimary,
                          letterSpacing: 2,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        decoration: BoxDecoration(
                          color: FutuerTheme.darkSurfaceVariant,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: FutuerTheme.brandPrimary, width: 2),
                        ),
                        child: Text(
                          _pendingDevice!.pairingCode ?? 'N/A',
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 8.0,
                            fontFamily: 'monospace',
                            color: FutuerTheme.brandPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.timer_outlined, size: 16, color: Colors.orange),
                          const SizedBox(width: 6),
                          Text(
                            'Expires in ${_secondsRemaining ~/ 60}:${(_secondsRemaining % 60).toString().padLeft(2, '0')}',
                            style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Instructions for secondary phone:',
                          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        const Text('1. Launch the Futuer Agent application on your secondary phone.'),
                        const SizedBox(height: 6),
                        const Text('2. Review and grant requested permissions explicitly.'),
                        const SizedBox(height: 6),
                        Text('3. Enter the pairing code ${_pendingDevice!.pairingCode}.'),
                        const SizedBox(height: 6),
                        const Text('4. This screen will automatically update once paired.'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Listening for Agent authorization...',
                      style: theme.textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                OutlinedButton(
                  onPressed: () {
                    _pollTimer?.cancel();
                    _countdownTimer?.cancel();
                    setState(() => _pendingDevice = null);
                  },
                  child: const Text('Cancel / Generate New Code'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
