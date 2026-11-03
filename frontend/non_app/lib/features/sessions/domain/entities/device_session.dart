class DeviceSession {
  const DeviceSession({
    required this.id,
    required this.deviceName,
    required this.lastActiveAt,
    required this.isCurrent,
  });

  final String id;
  final String deviceName;
  final DateTime lastActiveAt;
  final bool isCurrent;
}