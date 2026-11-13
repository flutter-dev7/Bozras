import '../../../../core/utils/formatters.dart';
import '../../domain/entities/supplier_profile.dart';

class SupplierProfileModel extends SupplierProfile {
  const SupplierProfileModel({
    required super.id,
    required super.name,
    required super.code,
    required super.requiresApproval,
    required super.subscriptionStatus,
    super.phone,
    super.description,
    super.logoUrl,
    super.planName,
    super.subscriptionEndsAt,
  });

  factory SupplierProfileModel.fromJson(Map<String, dynamic> json) {
    final ends = json['subscriptionEndsAt'] as String?;

    return SupplierProfileModel(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      code: json['code'] as String? ?? '',
      requiresApproval: json['requiresApproval'] as bool? ?? false,
      subscriptionStatus: json['subscriptionStatus'] as String? ?? '',
      phone: json['phone'] as String?,
      description: json['description'] as String?,
      logoUrl: json['logoUrl'] as String?,
      planName: json['planName'] as String?,
      subscriptionEndsAt: ends == null ? null : Formatters.parseDateTime(ends),
    );
  }
}