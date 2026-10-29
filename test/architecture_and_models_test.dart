import 'package:flutter_test/flutter_test.dart';
import 'package:futuer/models/device_model.dart';
import 'package:futuer/models/pairing_request.dart';
import 'package:futuer/services/role_service.dart';

void main() {
  group('1. Architecture & Role Tests', () {
    test('FutuerRole defines distinct Owner and Link roles', () {
      expect(FutuerRole.values, contains(FutuerRole.owner));
      expect(FutuerRole.values, contains(FutuerRole.link));
      expect(FutuerRole.values, contains(FutuerRole.none));
    });

    test('RoleService provides reactive role helpers', () {
      final service = RoleService.instance;
      service.currentRoleNotifier.value = FutuerRole.owner;
      expect(service.isOwner, isTrue);
      expect(service.isLink, isFalse);
      expect(service.isController, isTrue); // Legacy alias

      service.currentRoleNotifier.value = FutuerRole.link;
      expect(service.isLink, isTrue);
      expect(service.isOwner, isFalse);
      expect(service.isAgent, isTrue); // Legacy alias
    });
  });

  group('2. One Owner Multiple Devices Architecture Tests', () {
    final ownerId = 'd8273618-9321-4f12-a72e-333182619111';

    test('One Owner can have multiple distinct linked device records', () {
      final now = DateTime.now().toUtc();

      final device1 = DeviceModel(
        id: 'dev-phone-001',
        ownerUserId: ownerId,
        deviceName: 'Primary Android Phone',
        deviceModel: 'Pixel 8 Pro',
        isPaired: true,
        lastSeenAt: now,
        batteryLevel: 92,
        createdAt: now,
        updatedAt: now,
      );

      final device2 = DeviceModel(
        id: 'dev-tablet-002',
        ownerUserId: ownerId,
        deviceName: 'Work Tablet',
        deviceModel: 'Samsung Galaxy Tab S9',
        isPaired: true,
        lastSeenAt: now.subtract(const Duration(seconds: 20)),
        batteryLevel: 75,
        createdAt: now,
        updatedAt: now,
      );

      final device3 = DeviceModel(
        id: 'dev-backup-003',
        ownerUserId: ownerId,
        deviceName: 'Secondary Testing Phone',
        deviceModel: 'OnePlus 12',
        isPaired: true,
        lastSeenAt: now.subtract(const Duration(hours: 5)),
        batteryLevel: 45,
        createdAt: now,
        updatedAt: now,
      );

      final deviceList = [device1, device2, device3];

      // Verify all belong to same Owner
      for (final d in deviceList) {
        expect(d.ownerUserId, equals(ownerId));
      }

      // Verify each has distinct unique ID and name
      expect(deviceList.map((d) => d.id).toSet().length, equals(3));
      expect(deviceList.map((d) => d.deviceName).toSet().length, equals(3));

      // Verify online / offline statuses
      expect(device1.status, equals(DeviceStatus.online));
      expect(device2.status, equals(DeviceStatus.online));
      expect(device3.status, equals(DeviceStatus.offline));
      expect(device3.statusLabel, equals('LAST SEEN'));
    });

    test('Stale heartbeat correctly marks device as OFFLINE / LAST SEEN', () {
      final now = DateTime.now().toUtc();

      // Recent heartbeat within 60s -> ONLINE
      final liveDevice = DeviceModel(
        id: 'dev-live',
        ownerUserId: ownerId,
        deviceName: 'Active Link',
        isPaired: true,
        lastSeenAt: now.subtract(const Duration(seconds: 15)),
        createdAt: now,
        updatedAt: now,
      );
      expect(liveDevice.status, equals(DeviceStatus.online));
      expect(liveDevice.statusLabel, equals('ONLINE'));

      // Stale heartbeat (> 180s) -> OFFLINE
      final offlineDevice = DeviceModel(
        id: 'dev-offline',
        ownerUserId: ownerId,
        deviceName: 'Offline Link',
        isPaired: true,
        lastSeenAt: now.subtract(const Duration(minutes: 10)),
        createdAt: now,
        updatedAt: now,
      );
      expect(offlineDevice.status, equals(DeviceStatus.offline));
      expect(offlineDevice.statusLabel, equals('LAST SEEN'));

      // Never synced -> OFFLINE
      final neverSynced = DeviceModel(
        id: 'dev-never',
        ownerUserId: ownerId,
        deviceName: 'Unconnected Link',
        isPaired: true,
        lastSeenAt: null,
        createdAt: now,
        updatedAt: now,
      );
      expect(neverSynced.status, equals(DeviceStatus.offline));
      expect(neverSynced.statusLabel, equals('OFFLINE'));
    });
  });

  group('3. Secure Pairing Code & Expiration Tests', () {
    test('PairingRequest correctly reports expiration and status', () {
      final now = DateTime.now();

      // Active request
      final activeReq = PairingRequest(
        id: 'req-001',
        controllerUserId: 'owner-1',
        deviceName: 'My Tablet',
        pairingCode: 'FUT-824',
        status: 'PENDING',
        expiresAt: now.add(const Duration(minutes: 8)),
        createdAt: now,
      );
      expect(activeReq.isPending, isTrue);
      expect(activeReq.isExpired, isFalse);
      expect(activeReq.isConsumed, isFalse);

      // Expired request
      final expiredReq = PairingRequest(
        id: 'req-002',
        controllerUserId: 'owner-1',
        deviceName: 'Old Phone',
        pairingCode: 'FUT-119',
        status: 'PENDING',
        expiresAt: now.subtract(const Duration(minutes: 1)),
        createdAt: now.subtract(const Duration(minutes: 11)),
      );
      expect(expiredReq.isExpired, isTrue);

      // Consumed request (Single-use)
      final consumedReq = PairingRequest(
        id: 'req-003',
        controllerUserId: 'owner-1',
        deviceName: 'Linked Phone',
        pairingCode: 'FUT-992',
        status: 'CONSUMED',
        expiresAt: now.add(const Duration(minutes: 5)),
        consumedAt: now,
        consumedByDeviceId: 'dev-phone-001',
        createdAt: now,
      );
      expect(consumedReq.isConsumed, isTrue);
      expect(consumedReq.isPending, isFalse);
    });
  });
}
