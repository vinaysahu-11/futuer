import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../config/theme.dart';
import '../../../models/device_model.dart';
import '../../../services/auth_service.dart';
import '../../../services/device_service.dart';
import '../../../services/role_service.dart';
import '../../splash_gate.dart';
import '../device_details/owner_device_details_screen.dart';
import '../pairing/owner_pairing_screen.dart';

class OwnerDashboardScreen extends StatefulWidget {
  const OwnerDashboardScreen({super.key});

  @override
  State<OwnerDashboardScreen> createState() => _OwnerDashboardScreenState();
}

class _OwnerDashboardScreenState extends State<OwnerDashboardScreen> {
  List<DeviceModel> _devices = [];
  bool _isLoading = true;
  String? _error;
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _loadDevices();
    // 3-second polling interval for instant live online/offline status updates
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (_) => _loadDevices(silent: true));
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
          _error = e.toString().replaceAll('Exception:', '').trim();
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

  void _openAddDevice() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const OwnerPairingScreen()),
    );
    if (result == true) {
      _loadDevices();
    }
  }

  void _promptRenameDevice(DeviceModel device) {
    final controller = TextEditingController(text: device.deviceName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename Device'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter a new descriptive name for this linked device:',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Device Name',
                hintText: 'e.g. My Tablet, Work Phone',
              ),
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
              final newName = controller.text.trim();
              if (newName.isEmpty) return;
              Navigator.of(ctx).pop();
              try {
                await DeviceService.instance.renameDevice(device.id, newName);
                _loadDevices();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Device renamed to "$newName"')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to rename: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text('Save Name'),
          ),
        ],
      ),
    );
  }

  void _confirmUnlinkDevice(DeviceModel device) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Unlink Device?'),
        content: Text(
          'Are you sure you want to unlink "${device.deviceName}"? The device will lose access to this Futuer Owner account.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.of(ctx).pop();
              try {
                await DeviceService.instance.revokeDevice(device.id);
                _loadDevices();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('"${device.deviceName}" unlinked successfully')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to unlink: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text('Unlink Device'),
          ),
        ],
      ),
    );
  }

  void _confirmSignOut() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out of Futuer Owner?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              _pollingTimer?.cancel();
              await RoleService.instance.resetRole();
              if (!mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const SplashGate()),
                (route) => false,
              );
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  void _confirmChangeRole() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Switch App Role?'),
        content: const Text(
          'This will sign out of the Owner account and allow you to configure this phone as a Futuer Link device.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              _pollingTimer?.cancel();
              await RoleService.instance.resetRole();
              if (!mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const SplashGate()),
                (route) => false,
              );
            },
            child: const Text('Switch Role'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final user = AuthService.instance.currentUser;
    final dateFormat = DateFormat('MMM d, hh:mm a');

    final totalCount = _devices.length;
    final onlineCount = _devices.where((d) => d.status == DeviceStatus.online).length;
    final offlineCount = _devices.where((d) => d.status == DeviceStatus.offline || d.status == DeviceStatus.lastSeen).length;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: FutuerTheme.brandSecondary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.security, color: FutuerTheme.brandSecondary, size: 20),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Futuer Owner',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                ),
                Text(
                  user?.email ?? 'Owner Account',
                  style: TextStyle(fontSize: 11, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadDevices(),
          ),
          PopupMenuButton<String>(
            tooltip: 'Options',
            onSelected: (val) {
              if (val == 'add') _openAddDevice();
              if (val == 'role') _confirmChangeRole();
              if (val == 'signout') _confirmSignOut();
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: 'add',
                child: Row(
                  children: [
                    Icon(Icons.add_link, size: 18),
                    SizedBox(width: 8),
                    Text('Pair New Device'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'role',
                child: Row(
                  children: [
                    Icon(Icons.swap_horiz, size: 18),
                    SizedBox(width: 8),
                    Text('Switch Role'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'signout',
                child: Row(
                  children: [
                    Icon(Icons.logout, size: 18, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Sign Out', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: _devices.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _openAddDevice,
              icon: const Icon(Icons.add_link),
              label: const Text('Pair New Device'),
              backgroundColor: FutuerTheme.brandSecondary,
              foregroundColor: Colors.white,
            )
          : null,
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
                          Text('Failed to load devices:\n$_error', textAlign: TextAlign.center),
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
                                  color: FutuerTheme.brandSecondary,
                                ),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                'No devices linked yet.',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Link multiple Android phones or tablets using a secure, single-use pairing code.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(height: 24),
                              FilledButton.icon(
                                onPressed: _openAddDevice,
                                icon: const Icon(Icons.add_link),
                                label: const Text('Pair Your First Device'),
                                style: FilledButton.styleFrom(
                                  backgroundColor: FutuerTheme.brandSecondary,
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          // Top Metrics Overview Row
                          Row(
                            children: [
                              Expanded(
                                child: _MetricCard(
                                  title: 'Total Linked',
                                  value: '$totalCount',
                                  icon: Icons.devices,
                                  color: FutuerTheme.brandSecondary,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _MetricCard(
                                  title: 'Online',
                                  value: '$onlineCount',
                                  icon: Icons.check_circle,
                                  color: FutuerTheme.onlineColor,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _MetricCard(
                                  title: 'Offline',
                                  value: '$offlineCount',
                                  icon: Icons.signal_cellular_connected_no_internet_4_bar,
                                  color: FutuerTheme.offlineColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'LINKED DEVICES ($totalCount)',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.8,
                                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                                ),
                              ),
                              TextButton.icon(
                                onPressed: _openAddDevice,
                                icon: const Icon(Icons.add, size: 16),
                                label: const Text('Add Another'),
                                style: TextButton.styleFrom(
                                  visualDensity: VisualDensity.compact,
                                  foregroundColor: FutuerTheme.brandSecondary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Device Cards List
                          ..._devices.map((d) {
                            final statusColor = _getStatusColor(d.status);
                            final isOnline = d.status == DeviceStatus.online;

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                                side: BorderSide(
                                  color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.shade200,
                                ),
                              ),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(14),
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => OwnerDeviceDetailsScreen(initialDevice: d),
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
                                            padding: const EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                              color: statusColor.withValues(alpha: 0.12),
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: Icon(Icons.smartphone, color: statusColor, size: 24),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  d.deviceName,
                                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                                ),
                                                Text(
                                                  '${d.devicePlatform.toUpperCase()} • ${d.deviceModel ?? "Android Device"}',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          // Status Chip
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: statusColor.withValues(alpha: 0.15),
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(color: statusColor.withValues(alpha: 0.4)),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Container(
                                                  width: 7,
                                                  height: 7,
                                                  decoration: BoxDecoration(
                                                    color: statusColor,
                                                    shape: BoxShape.circle,
                                                  ),
                                                ),
                                                const SizedBox(width: 6),
                                                Text(
                                                  d.statusLabel,
                                                  style: TextStyle(
                                                    color: statusColor,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 11,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          // Options Menu for Rename / Unlink
                                          PopupMenuButton<String>(
                                            icon: const Icon(Icons.more_vert, size: 20),
                                            tooltip: 'Device Options',
                                            onSelected: (val) {
                                              if (val == 'details') {
                                                Navigator.of(context).push(
                                                  MaterialPageRoute(
                                                    builder: (_) => OwnerDeviceDetailsScreen(initialDevice: d),
                                                  ),
                                                );
                                              } else if (val == 'rename') {
                                                _promptRenameDevice(d);
                                              } else if (val == 'unlink') {
                                                _confirmUnlinkDevice(d);
                                              }
                                            },
                                            itemBuilder: (ctx) => [
                                              const PopupMenuItem(
                                                value: 'details',
                                                child: Row(
                                                  children: [
                                                    Icon(Icons.info_outline, size: 18),
                                                    SizedBox(width: 8),
                                                    Text('View Details'),
                                                  ],
                                                ),
                                              ),
                                              const PopupMenuItem(
                                                value: 'rename',
                                                child: Row(
                                                  children: [
                                                    Icon(Icons.edit_outlined, size: 18),
                                                    SizedBox(width: 8),
                                                    Text('Rename Device'),
                                                  ],
                                                ),
                                              ),
                                              const PopupMenuDivider(),
                                              const PopupMenuItem(
                                                value: 'unlink',
                                                child: Row(
                                                  children: [
                                                    Icon(Icons.link_off, size: 18, color: Colors.red),
                                                    SizedBox(width: 8),
                                                    Text('Unlink Device', style: TextStyle(color: Colors.red)),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      const Divider(height: 1),
                                      const SizedBox(height: 10),
                                      // Telemetry Footer
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(
                                                d.isCharging ? Icons.battery_charging_full : Icons.battery_std,
                                                size: 16,
                                                color: Colors.grey,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                d.batteryLevel != null
                                                    ? '${d.batteryLevel}%${d.isCharging ? " (Charging)" : ""}'
                                                    : 'Battery N/A',
                                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                                              ),
                                            ],
                                          ),
                                          Row(
                                            children: [
                                              const Icon(Icons.access_time, size: 14, color: Colors.grey),
                                              const SizedBox(width: 4),
                                              Text(
                                                isOnline
                                                    ? 'Active Now'
                                                    : d.lastSeenAt != null
                                                        ? 'Last seen: ${dateFormat.format(d.lastSeenAt!.toLocal())}'
                                                        : 'Never synced',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: isOnline ? FutuerTheme.onlineColor : Colors.grey,
                                                  fontWeight: isOnline ? FontWeight.w600 : FontWeight.normal,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }),
                          const SizedBox(height: 60),
                        ],
                      ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade900 : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
              ),
              Icon(icon, size: 16, color: color),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
