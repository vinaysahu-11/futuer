class DeviceLocation {
  final String id;
  final String deviceId;
  final double latitude;
  final double longitude;
  final double? accuracy;
  final DateTime recordedAt;

  DeviceLocation({
    required this.id,
    required this.deviceId,
    required this.latitude,
    required this.longitude,
    this.accuracy,
    required this.recordedAt,
  });

  /// Evaluates whether the location was recorded more than 10 minutes ago
  bool get isStale {
    final diffMinutes = DateTime.now().toUtc().difference(recordedAt.toUtc()).inMinutes;
    return diffMinutes > 10;
  }

  factory DeviceLocation.fromJson(Map<String, dynamic> json) {
    return DeviceLocation(
      id: json['id'] as String,
      deviceId: json['device_id'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      accuracy: json['accuracy'] != null ? (json['accuracy'] as num).toDouble() : null,
      recordedAt: DateTime.tryParse(json['recorded_at'].toString()) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'device_id': deviceId,
        'latitude': latitude,
        'longitude': longitude,
        'accuracy': accuracy,
        'recorded_at': recordedAt.toIso8601String(),
      };
}
