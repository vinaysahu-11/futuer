import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import '../../../services/session_listener_service.dart';

class LinkActiveSessionScreen extends StatefulWidget {
  final String sessionId;
  final String sessionType;

  const LinkActiveSessionScreen({
    super.key,
    required this.sessionId,
    required this.sessionType,
  });

  @override
  State<LinkActiveSessionScreen> createState() => _LinkActiveSessionScreenState();
}

class _LinkActiveSessionScreenState extends State<LinkActiveSessionScreen> {
  bool _isEnding = false;

  Future<void> _endSession() async {
    setState(() => _isEnding = true);
    try {
      await SessionListenerService.instance.updateSessionStatus(
        sessionId: widget.sessionId,
        status: 'ENDED',
      );
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCamera = widget.sessionType == 'CAMERA';

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _endSession();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          automaticallyImplyLeading: false,
          title: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.red,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'LIVE ${widget.sessionType} SESSION',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.2),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: _isEnding ? null : _endSession,
            ),
          ],
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: FutuerTheme.brandPrimary.withValues(alpha: 0.2),
                  border: Border.all(color: FutuerTheme.brandPrimary, width: 2),
                ),
                child: Icon(
                  isCamera ? Icons.videocam : Icons.mic,
                  size: 64,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                isCamera ? 'Camera Streaming Active' : 'Microphone Streaming Active',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  'Your Futuer Owner is viewing this live session. You may terminate the stream at any time below.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 13, height: 1.4),
                ),
              ),
              const SizedBox(height: 40),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _isEnding ? null : _endSession,
                icon: const Icon(Icons.stop_circle_outlined, size: 22),
                label: const Text(
                  'Stop Live Session',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
