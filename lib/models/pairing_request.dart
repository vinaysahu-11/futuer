class PairingRequest {
  final String id;
  final String controllerUserId;
  final String deviceName;
  final String pairingCode;
  final String status;
  final DateTime expiresAt;
  final DateTime? consumedAt;
  final String? consumedByDeviceId;
  final DateTime createdAt;

  PairingRequest({
    required this.id,
    required this.controllerUserId,
    required this.deviceName,
    required this.pairingCode,
    required this.status,
    required this.expiresAt,
    this.consumedAt,
    this.consumedByDeviceId,
    required this.createdAt,
  });

  bool get isExpired => DateTime.now().toUtc().isAfter(expiresAt.toUtc());
  bool get isPending => status == 'PENDING' && !isExpired;
  bool get isConsumed => status == 'CONSUMED';

  Duration get remainingTime {
    final diff = expiresAt.toUtc().difference(DateTime.now().toUtc());
    return diff.isNegative ? Duration.zero : diff;
  }

  factory PairingRequest.fromJson(Map<String, dynamic> json) {
    return PairingRequest(
      id: json['id'] as String,
      controllerUserId: json['controller_user_id'] as String,
      deviceName: json['device_name'] as String? ?? 'Secondary Device',
      pairingCode: json['pairing_code'] as String,
      status: json['status'] as String? ?? 'PENDING',
      expiresAt: DateTime.tryParse(json['expires_at'].toString()) ?? DateTime.now(),
      consumedAt: json['consumed_at'] != null ? DateTime.tryParse(json['consumed_at'].toString()) : null,
      consumedByDeviceId: json['consumed_by_device_id'] as String?,
      createdAt: DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'controller_user_id': controllerUserId,
        'device_name': deviceName,
        'pairing_code': pairingCode,
        'status': status,
        'expires_at': expiresAt.toIso8601String(),
        'consumed_at': consumedAt?.toIso8601String(),
        'consumed_by_device_id': consumedByDeviceId,
        'created_at': createdAt.toIso8601String(),
      };
}
