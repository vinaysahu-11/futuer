import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../models/device_model.dart';
import '../../services/auth_service.dart';
import '../../services/device_service.dart';
import '../device_details/device_details_screen.dart';
import '../pairing/pair_device_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<DeviceModel> _devices = [];
  bool _isLoading = true;
  String? _error;
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _loadDevices();
    // 5-second polling interval for verified live heartbeats
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (_) => _loadDevices(silent: true));
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadDevices({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final list = await DeviceService.instance.fetchDevices();
      if (mounted) {
        setState(() {
          _devices = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted && !silent) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Color _getStatusColor(DeviceStatus status) {
    switch (status) {
      case DeviceStatus.online:
        return FutuerTheme.onlineColor;
      case DeviceStatus.offline:
      case DeviceStatus.lastSeen:
        return FutuerTheme.offlineColor;
      case DeviceStatus.connecting:
        return FutuerTheme.connectingColor;
      case DeviceStatus.permissionRequired:
        return FutuerTheme.permissionReqColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = AuthService.instance.currentUser;
    final dateFormat = DateFormat('hh:mm:ss a');

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.radar_rounded, color: FutuerTheme.brandPrimary, size: 28),
            const SizedBox(width: 8),
            Text(
              'FUTUER',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: 2.0,
                color: FutuerTheme.brandPrimary,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Sign Out',
            icon: const Icon(Icons.logout),
            onPressed: () async => await AuthService.instance.signOut(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _loadDevices(),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline, size: 48, color: Colors.red),
                          const SizedBox(height: 12),
                          Text('Failed to load devices: $_error', textAlign: TextAlign.center),
                          const SizedBox(height: 16),
                          FilledButton(onPressed: () => _loadDevices(), child: const Text('Retry')),
                        ],
                      ),
                    ),
                  )
                : _devices.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: FutuerTheme.brandSecondary.withValues(alpha: 0.1),
                                ),
                                child: const Icon(
                                  Icons.phonelink_setup,
                                  size: 64,
                                  color: FutuerTheme.brandPrimary,
                                ),
                              ),
                              const SizedBox(height: 18),
                              Text(
                                'No Devices Enrolled Yet',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Owner: ${user?.email ?? ""}\nTap "Pair Device" to generate a pairing code for your secondary Android phone running Futuer Agent.',
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.grey, height: 1.4),
                              ),
                              const SizedBox(height: 24),
                              FilledButton.icon(
                                onPressed: () async {
                                  final paired = await Navigator.of(context).push<bool>(
                                    MaterialPageRoute(builder: (_) => const PairDeviceScreen()),
                                  );
                                  if (paired == true) _loadDevices();
                                },
                                icon: const Icon(Icons.add),
                                label: const Text('Pair Device'),
                                style: FilledButton.styleFrom(
                                  backgroundColor: FutuerTheme.brandSecondary,
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _devices.length,
                        itemBuilder: (context, index) {
                          final d = _devices[index];
                          final statusColor = _getStatusColor(d.status);

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => DeviceDetailsScreen(initialDevice: d),
                                  ),
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          width: 10,
                                          height: 10,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: statusColor,
                                            boxShadow: [
                                              BoxShadow(
                                                color: statusColor.withValues(alpha: 0.6),
                                                blurRadius: 6,
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          d.statusLabel,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: statusColor,
                                            letterSpacing: 1.0,
                                          ),
                                        ),
                                        const Spacer(),
                                        if (d.batteryLevel != null) ...[
                                          Icon(
                                            d.isCharging ? Icons.battery_charging_full : Icons.battery_std,
                                            size: 16,
                                            color: d.batteryLevel! < 20 ? Colors.red : Colors.green,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${d.batteryLevel}%',
                                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      d.deviceName,
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${d.deviceModel ?? "Android"} • ID: ${d.id.substring(0, 8)}...',
                                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                                    ),
                                    const Divider(height: 20),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          d.lastSeenAt != null
                                              ? 'Last Seen: ${dateFormat.format(d.lastSeenAt!.toLocal())}'
                                              : 'Last Seen: Not reported',
                                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                                        ),
                                        const Row(
                                          children: [
                                            Text(
                                              'Manage',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: FutuerTheme.brandPrimary,
                                              ),
                                            ),
                                            Icon(Icons.chevron_right, size: 16, color: FutuerTheme.brandPrimary),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final paired = await Navigator.of(context).push<bool>(
            MaterialPageRoute(builder: (_) => const PairDeviceScreen()),
          );
          if (paired == true) _loadDevices();
        },
        backgroundColor: FutuerTheme.brandSecondary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Pair Device', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
