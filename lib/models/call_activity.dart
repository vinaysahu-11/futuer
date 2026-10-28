class CallActivity {
  final String id;
  final String deviceId;
  final String callType; // 'INCOMING', 'OUTGOING', 'MISSED'
  final String? phoneNumber;
  final DateTime startedAt;
  final int? durationSeconds;
  final DateTime recordedAt;

  CallActivity({
    required this.id,
    required this.deviceId,
    required this.callType,
    this.phoneNumber,
    required this.startedAt,
    this.durationSeconds,
    required this.recordedAt,
  });

  factory CallActivity.fromJson(Map<String, dynamic> json) {
    return CallActivity(
      id: json['id'] as String,
      deviceId: json['device_id'] as String,
      callType: json['call_type'] as String? ?? 'INCOMING',
      phoneNumber: json['phoneNumber'] ?? json['phone_number'] as String?,
      startedAt: DateTime.tryParse(json['started_at'].toString()) ?? DateTime.now(),
      durationSeconds: json['duration_seconds'] as int?,
      recordedAt: DateTime.tryParse(json['recorded_at'].toString()) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'device_id': deviceId,
        'call_type': callType,
        'phone_number': phoneNumber,
        'started_at': startedAt.toIso8601String(),
        'duration_seconds': durationSeconds,
        'recorded_at': recordedAt.toIso8601String(),
      };
}
