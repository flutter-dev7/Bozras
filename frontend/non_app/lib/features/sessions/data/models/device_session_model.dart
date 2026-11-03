import '../../../../core/utils/formatters.dart';
import '../../domain/entities/device_session.dart';

class DeviceSessionModel extends DeviceSession {
  const DeviceSessionModel({
    required super.id,
    required super.deviceName,
    required super.lastActiveAt,
    required super.isCurrent,
  });

  factory DeviceSessionModel.fromJson(Map<String, dynamic> json) {
    return DeviceSessionModel(
      id: json['id'] as String,
      deviceName: json['deviceName'] as String? ?? 'Неизвестное устройство',
      lastActiveAt: Formatters.parseDateTime(json['lastActiveAt'] as String),
      isCurrent: json['isCurrent'] as bool? ?? false,
    );
  }
}