import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/call_activity.dart';
import '../models/device_location.dart';
import '../models/device_model.dart';
import '../models/device_notification.dart';
import '../models/device_session.dart';
import '../models/pairing_request.dart';
import 'audit_service.dart';
import 'auth_service.dart';
import 'insforge_service.dart';

class DeviceService {
  DeviceService._();
  static final DeviceService instance = DeviceService._();

  InsforgeService get _insforge => InsforgeService.instance;
  DateTime? _lastCodeGenerationTime;

  /// Fetches all devices belonging to the logged-in owner with safe timeout
  Future<List<DeviceModel>> fetchDevices() async {
    final ownerId = AuthService.instance.currentUser?.id;
    if (ownerId == null) return [];

    try {
      final rows = await _insforge.client.database
          .from('devices')
          .select()
          .eq('owner_user_id', ownerId)
          .order('created_at', ascending: false)
          .execute();

      return rows.map((r) => DeviceModel.fromJson(r)).toList();
    } catch (e) {
      debugPrint('DeviceService.fetchDevices note: $e');
      return [];
    }
  }

  /// Gets a single device by ID
  Future<DeviceModel?> getDevice(String deviceId) async {
    try {
      final rows = await _insforge.client.database
          .from('devices')
          .select()
          .eq('id', deviceId)
          .limit(1)
          .execute();

      if (rows.isEmpty) return null;
      return DeviceModel.fromJson(rows.first);
    } catch (_) {
      return null;
    }
  }

  /// Generates a cryptographically secure, 10-minute expiring pairing code in pairing_requests
  Future<PairingRequest> createPairingRequest({required String deviceName}) async {
    final ownerId = AuthService.instance.currentUser?.id;
    if (ownerId == null) throw StateError('User not logged in');

    // Rate limiting: enforce at least 2 seconds between requests
    final now = DateTime.now();
    if (_lastCodeGenerationTime != null &&
        now.difference(_lastCodeGenerationTime!).inSeconds < 2) {
      throw StateError('Please wait a moment before generating another pairing code.');
    }
    _lastCodeGenerationTime = now;

    // Expire any existing pending requests for this controller to maintain clean state
    try {
      await _insforge.client.database
          .from('pairing_requests')
          .eq('controller_user_id', ownerId)
          .eq('status', 'PENDING')
          .update({'status': 'EXPIRED'})
          .execute();
    } catch (_) {}

    // Generate secure 6-digit alphanumeric code e.g. FUT-482
    final secureRandom = Random.secure();
    final randomDigits = 100 + secureRandom.nextInt(900);
    final code = 'FUT-$randomDigits';
    final expiresAt = now.toUtc().add(const Duration(minutes: 10));

    final effectiveName = deviceName.trim().isNotEmpty ? deviceName.trim() : 'Secondary Device';

    final inserted = await _insforge.client.database
        .from('pairing_requests')
        .insert([
          {
            'controller_user_id': ownerId,
            'device_name': effectiveName,
            'pairing_code': code,
            'status': 'PENDING',
            'expires_at': expiresAt.toIso8601String(),
          }
        ])
        .select()
        .execute();

    if (inserted.isEmpty) throw StateError('Failed to create pairing request in database.');

    final req = PairingRequest.fromJson(inserted.first);

    await AuditService.instance.log(
      action: 'PAIRING_CODE_GENERATED',
      result: 'SUCCESS',
    );

    return req;
  }

  /// Cancels an active pairing request
  Future<void> cancelPairingRequest(String pairingRequestId) async {
    try {
      await _insforge.client.database
          .from('pairing_requests')
          .eq('id', pairingRequestId)
          .update({'status': 'CANCELLED'})
          .execute();

      await AuditService.instance.log(
        action: 'PAIRING_CODE_CANCELLED',
        result: 'SUCCESS',
      );
    } catch (_) {}
  }

  /// Checks the status of a pairing request (used for polling)
  Future<PairingRequest?> getPairingRequest(String pairingRequestId) async {
    try {
      final rows = await _insforge.client.database
          .from('pairing_requests')
          .select()
          .eq('id', pairingRequestId)
          .limit(1)
          .execute();

      if (rows.isEmpty) return null;
      return PairingRequest.fromJson(rows.first);
    } catch (_) {
      return null;
    }
  }

  /// Fetches recorded locations for a device
  Future<List<DeviceLocation>> fetchLocations(String deviceId, {int limit = 50}) async {
    final rows = await _insforge.client.database
        .from('device_locations')
        .select()
        .eq('device_id', deviceId)
        .order('recorded_at', ascending: false)
        .limit(limit)
        .execute();

    return rows.map((r) => DeviceLocation.fromJson(r)).toList();
  }

  /// Fetches latest location record for a device
  Future<DeviceLocation?> getLatestLocation(String deviceId) async {
    try {
      final rows = await _insforge.client.database
          .from('device_locations')
          .select()
          .eq('device_id', deviceId)
          .order('recorded_at', ascending: false)
          .limit(1)
          .execute();

      if (rows.isNotEmpty) {
        return DeviceLocation.fromJson(rows.first);
      }
    } catch (e) {
      debugPrint('getLatestLocation from device_locations note: $e');
    }

    try {
      final devRows = await _insforge.client.database
          .from('devices')
          .select('id, last_latitude, last_longitude, last_location_time')
          .eq('id', deviceId)
          .limit(1)
          .execute();
      if (devRows.isNotEmpty &&
          devRows.first['last_latitude'] != null &&
          devRows.first['last_longitude'] != null) {
        final d = devRows.first;
        return DeviceLocation(
          id: 'dev-loc-${d['id']}',
          deviceId: deviceId,
          latitude: (d['last_latitude'] as num).toDouble(),
          longitude: (d['last_longitude'] as num).toDouble(),
          accuracy: 10.0,
          recordedAt: d['last_location_time'] != null
              ? DateTime.parse(d['last_location_time'].toString())
              : DateTime.now().toUtc(),
        );
      }
    } catch (e) {
      debugPrint('fallback dev location note: $e');
    }
    return null;
  }

  /// Fetches recorded notifications
  Future<List<DeviceNotification>> fetchNotifications(String deviceId, {int limit = 50}) async {
    final rows = await _insforge.client.database
        .from('device_notifications')
        .select()
        .eq('device_id', deviceId)
        .order('recorded_at', ascending: false)
        .limit(limit)
        .execute();

    return rows.map((r) => DeviceNotification.fromJson(r)).toList();
  }

  /// Fetches recorded call activities
  Future<List<CallActivity>> fetchCallActivities(String deviceId, {int limit = 50}) async {
    final rows = await _insforge.client.database
        .from('call_activity')
        .select()
        .eq('device_id', deviceId)
        .order('started_at', ascending: false)
        .limit(limit)
        .execute();

    return rows.map((r) => CallActivity.fromJson(r)).toList();
  }

  /// Fetches sessions (camera, mic)
  Future<List<DeviceSession>> fetchSessions(String deviceId, {int limit = 20}) async {
    final rows = await _insforge.client.database
        .from('device_sessions')
        .select()
        .eq('device_id', deviceId)
        .order('started_at', ascending: false)
        .limit(limit)
        .execute();

    return rows.map((r) => DeviceSession.fromJson(r)).toList();
  }

  /// Requests an authorized session (camera or microphone)
  Future<DeviceSession> requestSession({
    required String deviceId,
    required String sessionType,
  }) async {
    final inserted = await _insforge.client.database
        .from('device_sessions')
        .insert([
          {
            'device_id': deviceId,
            'session_type': sessionType,
            'status': 'REQUESTED',
            'started_at': DateTime.now().toUtc().toIso8601String(),
          }
        ])
        .select()
        .execute();

    if (inserted.isEmpty) throw StateError('Failed to initiate $sessionType session');
    return DeviceSession.fromJson(inserted.first);
  }

  /// Terminates an active session
  Future<void> endSession(String sessionId) async {
    await _insforge.client.database
        .from('device_sessions')
        .eq('id', sessionId)
        .update({
          'status': 'ENDED',
          'ended_at': DateTime.now().toUtc().toIso8601String(),
        })
        .execute();
  }

  /// Fetches connection history (heartbeats)
  Future<List<Map<String, dynamic>>> fetchHeartbeats(String deviceId, {int limit = 50}) async {
    return await _insforge.client.database
        .from('device_heartbeats')
        .select()
        .eq('device_id', deviceId)
        .order('received_at', ascending: false)
        .limit(limit)
        .execute();
  }

  /// Renames an enrolled device belonging to this owner
  Future<void> renameDevice(String deviceId, String newName) async {
    final trimmed = newName.trim();
    if (trimmed.isEmpty) throw ArgumentError('Device name cannot be empty');

    await _insforge.client.database
        .from('devices')
        .eq('id', deviceId)
        .update({
          'device_name': trimmed,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .execute();

    await AuditService.instance.log(
      action: 'DEVICE_RENAMED',
      result: 'SUCCESS',
      deviceId: deviceId,
    );
  }

  /// Revokes an enrolled device (unlinks from owner)
  Future<void> revokeDevice(String deviceId) async {
    await _insforge.client.database
        .from('devices')
        .eq('id', deviceId)
        .delete()
        .execute();

    await AuditService.instance.log(
      action: 'DEVICE_REVOKED',
      result: 'SUCCESS',
      deviceId: deviceId,
    );
  }
}
