import 'package:flutter/material.dart';
import '../../config/theme.dart';
import 'permissions_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Center(
                child: Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: FutuerAgentTheme.brandSecondary.withValues(alpha: 0.15),
                    border: Border.all(
                      color: FutuerAgentTheme.brandPrimary.withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.security,
                    size: 64,
                    color: FutuerAgentTheme.brandPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'FUTUER AGENT',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 3.0,
                  color: FutuerAgentTheme.brandPrimary,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Managed Device Application',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
              ),
              const SizedBox(height: 32),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Device Enrollment Notice',
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '• This app is installed on secondary devices that the owner explicitly authorizes.\n'
                        '• Works alongside your standard Android launcher without replacing it.\n'
                        '• All remote functions (location, notifications, camera) operate with explicit permissions and visual privacy indicators.',
                        style: TextStyle(fontSize: 12.5, height: 1.5, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),

              const Spacer(),
              FilledButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const PermissionsScreen()),
                  );
                },
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: FutuerAgentTheme.brandSecondary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text(
                  'Begin Enrollment',
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
