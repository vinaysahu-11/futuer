class DeviceNotification {
  final String id;
  final String deviceId;
  final String? appPackage;
  final String? notificationTitle;
  final String? notificationText;
  final DateTime recordedAt;

  DeviceNotification({
    required this.id,
    required this.deviceId,
    this.appPackage,
    this.notificationTitle,
    this.notificationText,
    required this.recordedAt,
  });

  factory DeviceNotification.fromJson(Map<String, dynamic> json) {
    return DeviceNotification(
      id: json['id'] as String,
      deviceId: json['device_id'] as String,
      appPackage: json['app_package'] as String?,
      notificationTitle: json['notification_title'] as String?,
      notificationText: json['notification_text'] as String?,
      recordedAt: DateTime.tryParse(json['recorded_at'].toString()) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'device_id': deviceId,
        'app_package': appPackage,
        'notification_title': notificationTitle,
        'notification_text': notificationText,
        'recorded_at': recordedAt.toIso8601String(),
      };
}
