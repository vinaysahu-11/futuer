import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:futuer/config/theme.dart';
import 'package:futuer/models/device_location.dart';
import 'package:futuer/models/device_model.dart';
import 'package:futuer/services/device_service.dart';

class LocationMapTab extends StatefulWidget {
  final DeviceModel device;

  const LocationMapTab({super.key, required this.device});

  @override
  State<LocationMapTab> createState() => _LocationMapTabState();
}

class _LocationMapTabState extends State<LocationMapTab> {
  DeviceLocation? _latestLocation;
  bool _isLoading = true;
  String? _error;
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    _fetchLocation();
  }

  Future<void> _fetchLocation() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final loc = await DeviceService.instance.getLatestLocation(widget.device.id);
      if (mounted) {
        setState(() {
          _latestLocation = loc;
          _isLoading = false;
        });

        if (loc != null && _mapController != null) {
          _mapController!.animateCamera(
            CameraUpdate.newLatLngZoom(LatLng(loc.latitude, loc.longitude), 15),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MMM d, yyyy • hh:mm:ss a');

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text('Location Error: $_error', textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(onPressed: _fetchLocation, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    if (_latestLocation == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.location_off, size: 54, color: Colors.grey),
              const SizedBox(height: 14),
              Text(
                'No Location Recorded Yet',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Futuer Agent uploads location updates when authorized by the owner on the secondary phone.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: _fetchLocation,
                icon: const Icon(Icons.refresh),
                label: const Text('Check for Updates'),
              ),
            ],
          ),
        ),
      );
    }

    final loc = _latestLocation!;
    final isLive = !loc.isStale && widget.device.status == DeviceStatus.online;
    final latLng = LatLng(loc.latitude, loc.longitude);

    final markers = <Marker>{
      Marker(
        markerId: const MarkerId('agent_device'),
        position: latLng,
        infoWindow: InfoWindow(
          title: widget.device.deviceName,
          snippet: isLive ? 'Live Location' : 'Last Known Location',
        ),
      ),
    };

    return Column(
      children: [
        // Location Status Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: isLive
              ? FutuerTheme.onlineColor.withValues(alpha: 0.15)
              : Colors.orange.withValues(alpha: 0.15),
          child: Row(
            children: [
              Icon(
                isLive ? Icons.gps_fixed : Icons.history,
                size: 20,
                color: isLive ? FutuerTheme.onlineColor : Colors.orange,
              ),
              const SizedBox(width: 8),
              Text(
                isLive ? 'LIVE LOCATION' : 'LAST KNOWN LOCATION',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                  color: isLive ? FutuerTheme.onlineColor : Colors.orange,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.refresh, size: 20),
                tooltip: 'Refresh Location',
                onPressed: _fetchLocation,
              ),
            ],
          ),
        ),

        // Google Map Widget
        Expanded(
          child: GoogleMap(
            initialCameraPosition: CameraPosition(target: latLng, zoom: 15),
            markers: markers,
            onMapCreated: (ctrl) => _mapController = ctrl,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: true,
          ),
        ),

        // Coordinates & Accuracy details footer
        Container(
          padding: const EdgeInsets.all(16),
          color: theme.cardTheme.color ?? theme.colorScheme.surface,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Coordinates:', style: TextStyle(color: Colors.grey)),
                  Text(
                    '${loc.latitude.toStringAsFixed(6)}, ${loc.longitude.toStringAsFixed(6)}',
                    style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Accuracy:', style: TextStyle(color: Colors.grey)),
                  Text(
                    loc.accuracy != null ? '±${loc.accuracy!.toStringAsFixed(1)} m' : 'Unknown',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Timestamp:', style: TextStyle(color: Colors.grey)),
                  Text(
                    dateFormat.format(loc.recordedAt.toLocal()),
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
