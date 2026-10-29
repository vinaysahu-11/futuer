import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import '../auth/link_auth_screen.dart';

class LinkIntroScreen extends StatelessWidget {
  const LinkIntroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Set Up Futuer Link'),
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
                    'Configure this phone as a Futuer Link device to be managed securely by an authorized Futuer Owner.',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),

                  // Explanation Cards
                  const _ExplanationTile(
                    icon: Icons.link_rounded,
                    color: Colors.blue,
                    title: 'Owner Association',
                    description:
                        'This phone will be securely linked to an authorized Futuer Owner account using a single-use pairing code.',
                  ),
                  const SizedBox(height: 12),
                  const _ExplanationTile(
                    icon: Icons.verified_user_outlined,
                    color: Colors.teal,
                    title: 'Explicit Device Owner Authorization',
                    description:
                        'The device user must authorize enrollment. Pairing codes expire in 10 minutes and can be revoked at any time.',
                  ),
                  const SizedBox(height: 12),
                  const _ExplanationTile(
                    icon: Icons.security_outlined,
                    color: Colors.orange,
                    title: 'Android Permissions Required',
                    description:
                        'Management features (GPS location, call logs, notifications) require explicit Android system permissions.',
                  ),
                  const SizedBox(height: 12),
                  const _ExplanationTile(
                    icon: Icons.privacy_tip_outlined,
                    color: Colors.purple,
                    title: 'Privacy & Visual Indicators',
                    description:
                        'Live camera and microphone sessions comply strictly with Android visual privacy indicators (status bar dots). No hidden recording.',
                  ),

                  const SizedBox(height: 32),

                  FilledButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const LinkAuthScreen()),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
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
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
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
