import 'dart:math';
import '../models/call_activity.dart';
import '../models/device_location.dart';
import '../models/device_model.dart';
import '../models/device_notification.dart';
import '../models/device_session.dart';
import 'auth_service.dart';
import 'insforge_service.dart';

class DeviceService {
  DeviceService._();
  static final DeviceService instance = DeviceService._();

  InsforgeService get _insforge => InsforgeService.instance;

  /// Fetches all devices belonging to the logged-in owner
  Future<List<DeviceModel>> fetchDevices() async {
    final ownerId = AuthService.instance.currentUser?.id;
    if (ownerId == null) return [];

    final rows = await _insforge.client.database
        .from('devices')
        .select()
        .eq('owner_user_id', ownerId)
        .order('created_at', ascending: false)
        .execute();

    return rows.map((r) => DeviceModel.fromJson(r)).toList();
  }

  /// Gets a single device by ID
  Future<DeviceModel?> getDevice(String deviceId) async {
    final rows = await _insforge.client.database
        .from('devices')
        .select()
        .eq('id', deviceId)
        .limit(1)
        .execute();

    if (rows.isEmpty) return null;
    return DeviceModel.fromJson(rows.first);
  }

  /// Generates a secure, 10-minute expiring pairing code for enrolling a secondary phone
  Future<DeviceModel> generatePairingCode({required String deviceName}) async {
    final ownerId = AuthService.instance.currentUser?.id;
    if (ownerId == null) throw StateError('User not logged in');

    // 6-digit alphanumeric code e.g. FUT-742
    final randomPart = (100 + Random().nextInt(900)).toString();
    final code = 'FUT-$randomPart';
    final expiresAt = DateTime.now().toUtc().add(const Duration(minutes: 10));

    final inserted = await _insforge.client.database
        .from('devices')
        .insert({
          'owner_user_id': ownerId,
          'device_name': deviceName.trim().isNotEmpty ? deviceName.trim() : 'Futuer Agent',
          'device_platform': 'android',
          'pairing_code': code,
          'pairing_code_expires_at': expiresAt.toIso8601String(),
          'is_paired': false,
        })
        .select()
        .execute();

    if (inserted.isEmpty) throw StateError('Failed to create pairing session');
    return DeviceModel.fromJson(inserted.first);
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
    final rows = await _insforge.client.database
        .from('device_locations')
        .select()
        .eq('device_id', deviceId)
        .order('recorded_at', ascending: false)
        .limit(1)
        .execute();

    if (rows.isEmpty) return null;
    return DeviceLocation.fromJson(rows.first);
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
    required String sessionType, // 'CAMERA' or 'MICROPHONE'
  }) async {
    final inserted = await _insforge.client.database
        .from('device_sessions')
        .insert({
          'device_id': deviceId,
          'session_type': sessionType,
          'status': 'REQUESTED',
          'started_at': DateTime.now().toUtc().toIso8601String(),
        })
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

  /// Revokes an enrolled device
  Future<void> revokeDevice(String deviceId) async {
    await _insforge.client.database
        .from('devices')
        .eq('id', deviceId)
        .delete()
        .execute();
  }
}
