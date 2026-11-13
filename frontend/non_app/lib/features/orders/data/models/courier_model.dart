import '../../domain/entities/courier.dart';

class CourierModel extends Courier {
  const CourierModel({
    required super.id,
    required super.name,
    required super.phone,
  });

  factory CourierModel.fromJson(Map<String, dynamic> json) {
    final fullName = (json['fullName'] as String?)?.trim() ?? '';
    final first = json['firstName'] as String? ?? '';
    final last = json['lastName'] as String? ?? '';

    return CourierModel(
      id: json['id'] as String,
      name: fullName.isNotEmpty ? fullName : '$first $last'.trim(),
      phone: json['phone'] as String? ?? '',
    );
  }
}