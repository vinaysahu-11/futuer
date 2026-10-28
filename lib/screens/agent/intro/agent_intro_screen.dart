import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import '../auth/agent_auth_screen.dart';

class AgentIntroScreen extends StatelessWidget {
  const AgentIntroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Connect This Device'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: FutuerTheme.brandPrimary.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: FutuerTheme.brandPrimary.withValues(alpha: 0.4),
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.phonelink_setup_rounded,
                        size: 34,
                        color: FutuerTheme.brandPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Connect This Device to Futuer',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Configure this secondary Android phone to be managed securely by your Futuer Controller.',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),

                  // Explanation Cards
                  _ExplanationTile(
                    icon: Icons.link_rounded,
                    color: Colors.blue,
                    title: 'Controller Association',
                    description:
                        'This phone will be securely associated with an authorized Futuer Controller account via single-use pairing.',
                  ),
                  const SizedBox(height: 12),
                  _ExplanationTile(
                    icon: Icons.verified_user_outlined,
                    color: Colors.teal,
                    title: 'Explicit Device Owner Authorization',
                    description:
                        'The device owner must authorize enrollment. Pairing codes expire after 10 minutes and can be revoked at any time.',
                  ),
                  const SizedBox(height: 12),
                  _ExplanationTile(
                    icon: Icons.security_outlined,
                    color: Colors.amber.shade800,
                    title: 'Android Permissions Required',
                    description:
                        'Certain management features (GPS location, telephony call logs, notifications) require explicit Android permissions.',
                  ),
                  const SizedBox(height: 12),
                  _ExplanationTile(
                    icon: Icons.privacy_tip_outlined,
                    color: Colors.purple,
                    title: 'Privacy & Visual Indicators',
                    description:
                        'Authorized remote camera and microphone sessions comply strictly with Android visual privacy indicators (system status dots). Covert operation is prohibited.',
                  ),

                  const SizedBox(height: 32),

                  FilledButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const AgentAuthScreen()),
                      );
                    },
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: FutuerTheme.brandPrimaryDark,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text(
                      'Continue',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel / Change Role'),
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

class _ExplanationTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String description;

  const _ExplanationTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? FutuerTheme.darkSurfaceVariant : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.shade200,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
