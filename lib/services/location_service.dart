import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'enrollment_service.dart';
import 'insforge_service.dart';

class LocationService {
  LocationService._();
  static final LocationService instance = LocationService._();

  Timer? _timer;
  bool _isRunning = false;

  bool get isRunning => _isRunning;

  void start() {
    if (_isRunning) return;
    _isRunning = true;
    _captureAndUploadLocation();
    _timer = Timer.periodic(
      const Duration(seconds: 20),
      (_) => _captureAndUploadLocation(),
    );
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    _isRunning = false;
  }

  Future<Position?> _captureAndUploadLocation() async {
    final deviceId = EnrollmentService.instance.cachedDeviceId;
    if (deviceId == null) return null;

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return null;
      }

      if (permission == LocationPermission.deniedForever) return null;

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );

      final client = InsforgeService.instance.client;
      final nowUtcStr = DateTime.now().toUtc().toIso8601String();

      // 1. Update latest coordinates on devices table
      try {
        await client.database
            .from('devices')
            .eq('id', deviceId)
            .update({
              'last_latitude': position.latitude,
              'last_longitude': position.longitude,
              'last_location_time': nowUtcStr,
            })
            .execute();
      } catch (devLocErr) {
        debugPrint('devices table location update note: $devLocErr');
      }

      // 2. Insert into device_locations history table using array syntax
      await client.database
          .from('device_locations')
          .insert([
            {
              'device_id': deviceId,
              'latitude': position.latitude,
              'longitude': position.longitude,
              'accuracy': position.accuracy,
              'recorded_at': nowUtcStr,
            }
          ])
          .execute();

      return position;
    } catch (e) {
      debugPrint('Location capture/upload error: $e');
      return null;
    }
  }

  Future<Position?> forceUpdateLocation() async {
    return await _captureAndUploadLocation();
  }
}
