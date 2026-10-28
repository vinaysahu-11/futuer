import 'dart:async';
import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import '../../../models/device_model.dart';
import '../../../services/device_service.dart';
import 'tabs/call_activity_tab.dart';
import 'tabs/camera_session_tab.dart';
import 'tabs/connection_history_tab.dart';
import 'tabs/location_map_tab.dart';
import 'tabs/microphone_session_tab.dart';
import 'tabs/notifications_tab.dart';
import 'tabs/overview_tab.dart';
import 'tabs/permissions_tab.dart';

class ControllerDeviceDetailsScreen extends StatefulWidget {
  final DeviceModel initialDevice;

  const ControllerDeviceDetailsScreen({super.key, required this.initialDevice});

  @override
  State<ControllerDeviceDetailsScreen> createState() => _ControllerDeviceDetailsScreenState();
}

class _ControllerDeviceDetailsScreenState extends State<ControllerDeviceDetailsScreen>
    with SingleTickerProviderStateMixin {
  late DeviceModel _device;
  late final TabController _tabController;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _device = widget.initialDevice;
    _tabController = TabController(length: 8, vsync: this);
    // Periodically refresh device record to capture verified heartbeats
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) => _refreshDevice());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _refreshDevice() async {
    try {
      final updated = await DeviceService.instance.getDevice(_device.id);
      if (updated != null && mounted) {
        setState(() => _device = updated);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            Text(_device.deviceName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text(
              '${_device.statusLabel} • ${_device.deviceModel ?? "Android"}',
              style: TextStyle(
                fontSize: 11,
                color: _device.status == DeviceStatus.online ? FutuerTheme.onlineColor : Colors.grey,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          indicatorColor: FutuerTheme.brandSecondary,
          labelColor: FutuerTheme.brandSecondary,
          tabs: const [
            Tab(icon: Icon(Icons.info_outline, size: 20), text: 'Overview'),
            Tab(icon: Icon(Icons.map_outlined, size: 20), text: 'Location'),
            Tab(icon: Icon(Icons.notifications_none, size: 20), text: 'Notifications'),
            Tab(icon: Icon(Icons.call_outlined, size: 20), text: 'Call Activity'),
            Tab(icon: Icon(Icons.videocam_outlined, size: 20), text: 'Camera'),
            Tab(icon: Icon(Icons.mic_outlined, size: 20), text: 'Microphone'),
            Tab(icon: Icon(Icons.history, size: 20), text: 'History'),
            Tab(icon: Icon(Icons.security, size: 20), text: 'Permissions'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          OverviewTab(device: _device, onRefresh: _refreshDevice),
          LocationMapTab(device: _device),
          NotificationsTab(device: _device),
          CallActivityTab(device: _device),
          CameraSessionTab(device: _device),
          MicrophoneSessionTab(device: _device),
          ConnectionHistoryTab(device: _device),
          PermissionsTab(device: _device),
        ],
      ),
    );
  }
}
