import '../../domain/entities/staff_user.dart';

class StaffUserModel extends StaffUser {
  const StaffUserModel({
    required super.id,
    required super.firstName,
    required super.lastName,
    required super.fullName,
    required super.phone,
    required super.role,
    required super.isActive,
    super.email,
    super.emailConfirmed,
  });

  factory StaffUserModel.fromJson(Map<String, dynamic> json) {
    final first = json['firstName'] as String? ?? '';
    final last = json['lastName'] as String? ?? '';
    final full = json['fullName'] as String?;

    return StaffUserModel(
      id: json['id'] as String,
      firstName: first,
      lastName: last,
      fullName: full != null && full.isNotEmpty ? full : '$first $last'.trim(),
      phone: json['phone'] as String? ?? '',
      role: json['role'] as String? ?? '',
      isActive: json['isActive'] as bool? ?? true,
      email: json['email'] as String?,
      emailConfirmed: json['emailConfirmed'] as bool? ?? false,
    );
  }
}