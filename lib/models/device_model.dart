enum DeviceStatus {
  online,
  offline,
  connecting,
  permissionRequired,
  lastSeen,
}

class DeviceModel {
  final String id;
  final String ownerUserId;
  final String deviceName;
  final String? deviceModel;
  final String devicePlatform;
  final String? pairingCode;
  final DateTime? pairingCodeExpiresAt;
  final bool isPaired;
  final String enrollmentStatus;
  final int? batteryLevel;
  final bool isCharging;
  final Map<String, dynamic> permissionStatus;
  final DateTime? lastSeenAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  DeviceModel({
    required this.id,
    required this.ownerUserId,
    required this.deviceName,
    this.deviceModel,
    this.devicePlatform = 'android',
    this.pairingCode,
    this.pairingCodeExpiresAt,
    this.isPaired = false,
    this.enrollmentStatus = 'ENROLLED',
    this.batteryLevel,
    this.isCharging = false,
    this.permissionStatus = const {},
    this.lastSeenAt,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Evaluates verified online/offline status based on last seen heartbeat within 60s
  DeviceStatus get status {
    if (!isPaired) return DeviceStatus.connecting;

    final hasPermWarning = permissionStatus.values.any((val) => val == false);

    if (lastSeenAt == null) {
      return hasPermWarning ? DeviceStatus.permissionRequired : DeviceStatus.offline;
    }

    final diffSeconds = DateTime.now().toUtc().difference(lastSeenAt!.toUtc()).inSeconds;

    if (diffSeconds <= 60) {
      if (hasPermWarning) return DeviceStatus.permissionRequired;
      return DeviceStatus.online;
    } else if (diffSeconds <= 180) {
      return DeviceStatus.connecting;
    } else {
      return DeviceStatus.offline;
    }
  }

  String get statusLabel {
    switch (status) {
      case DeviceStatus.online:
        return 'ONLINE';
      case DeviceStatus.offline:
        return lastSeenAt != null ? 'LAST SEEN' : 'OFFLINE';
      case DeviceStatus.connecting:
        return 'CONNECTING';
      case DeviceStatus.permissionRequired:
        return 'PERMISSION REQUIRED';
      case DeviceStatus.lastSeen:
        return 'LAST SEEN';
    }
  }

  factory DeviceModel.fromJson(Map<String, dynamic> json) {
    return DeviceModel(
      id: json['id'] as String,
      ownerUserId: json['owner_user_id'] as String,
      deviceName: json['device_name'] as String? ?? 'Futuer Link',
      deviceModel: json['device_model'] as String?,
      devicePlatform: json['device_platform'] as String? ?? 'android',
      pairingCode: json['pairing_code'] as String?,
      pairingCodeExpiresAt: json['pairing_code_expires_at'] != null
          ? DateTime.tryParse(json['pairing_code_expires_at'].toString())
          : null,
      isPaired: json['is_paired'] as bool? ?? false,
      enrollmentStatus: json['enrollment_status'] as String? ?? 'ENROLLED',
      batteryLevel: json['battery_level'] as int?,
      isCharging: json['is_charging'] as bool? ?? false,
      permissionStatus: json['permission_status'] is Map
          ? Map<String, dynamic>.from(json['permission_status'] as Map)
          : {},
      lastSeenAt: json['last_seen_at'] != null
          ? DateTime.tryParse(json['last_seen_at'].toString())
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'owner_user_id': ownerUserId,
        'device_name': deviceName,
        'device_model': deviceModel,
        'device_platform': devicePlatform,
        'pairing_code': pairingCode,
        'pairing_code_expires_at': pairingCodeExpiresAt?.toIso8601String(),
        'is_paired': isPaired,
        'enrollment_status': enrollmentStatus,
        'battery_level': batteryLevel,
        'is_charging': isCharging,
        'permission_status': permissionStatus,
        'last_seen_at': lastSeenAt?.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };
}
