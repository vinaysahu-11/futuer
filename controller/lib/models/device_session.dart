class DeviceSession {
  final String id;
  final String deviceId;
  final String sessionType; // 'CAMERA', 'MICROPHONE'
  final String status; // 'REQUESTED', 'ACTIVE', 'ENDED', 'REJECTED'
  final Map<String, dynamic> sessionData;
  final DateTime startedAt;
  final DateTime? endedAt;

  DeviceSession({
    required this.id,
    required this.deviceId,
    required this.sessionType,
    required this.status,
    this.sessionData = const {},
    required this.startedAt,
    this.endedAt,
  });

  factory DeviceSession.fromJson(Map<String, dynamic> json) {
    return DeviceSession(
      id: json['id'] as String,
      deviceId: json['device_id'] as String,
      sessionType: json['session_type'] as String? ?? 'CAMERA',
      status: json['status'] as String? ?? 'REQUESTED',
      sessionData: json['session_data'] is Map
          ? Map<String, dynamic>.from(json['session_data'] as Map)
          : {},
      startedAt: DateTime.tryParse(json['started_at'].toString()) ?? DateTime.now(),
      endedAt: json['ended_at'] != null ? DateTime.tryParse(json['ended_at'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'device_id': deviceId,
        'session_type': sessionType,
        'status': status,
        'session_data': sessionData,
        'started_at': startedAt.toIso8601String(),
        'ended_at': endedAt?.toIso8601String(),
      };
}
