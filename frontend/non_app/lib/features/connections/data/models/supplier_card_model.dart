import '../../domain/entities/supplier_card.dart';
import 'connection_status_parser.dart';

class SupplierCardModel extends SupplierCard {
  const SupplierCardModel({
    required super.id,
    required super.name,
    super.phone,
    super.description,
    super.logoUrl,
    required super.requiresApproval,
    super.status,
  });

  factory SupplierCardModel.fromJson(Map<String, dynamic> json) {
    return SupplierCardModel(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      phone: json['phone'] as String?,
      description: json['description'] as String?,
      logoUrl: json['logoUrl'] as String?,
      requiresApproval: json['requiresApproval'] as bool? ?? false,
      status: json['connectionStatus'] == null
          ? null
          : parseConnectionStatus(json['connectionStatus']),
    );
  }
}