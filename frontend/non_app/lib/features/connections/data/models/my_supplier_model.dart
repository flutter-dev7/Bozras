import '../../domain/entities/my_supplier.dart';
import 'connection_status_parser.dart';

class MySupplierModel extends MySupplier {
  const MySupplierModel({
    required super.supplierId,
    required super.name,
    super.phone,
    super.description,
    super.logoUrl,
    required super.status,
    required super.isAvailable,
  });

  factory MySupplierModel.fromJson(Map<String, dynamic> json) {
    return MySupplierModel(
      supplierId: json['supplierId'] as String,
      name: json['name'] as String? ?? '',
      phone: json['phone'] as String?,
      description: json['description'] as String?,
      logoUrl: json['logoUrl'] as String?,
      status: parseConnectionStatus(json['status']),
      isAvailable: json['isAvailable'] as bool? ?? true,
    );
  }
}