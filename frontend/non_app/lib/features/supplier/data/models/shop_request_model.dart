import '../../domain/entities/shop_request.dart';

class ShopRequestModel extends ShopRequest {
  const ShopRequestModel({
    required super.id,
    required super.name,
    required super.address,
    required super.phone,
    super.contactName,
    super.ownerName,
    super.ownerPhone,
  });

  factory ShopRequestModel.fromJson(Map<String, dynamic> json) {
    return ShopRequestModel(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      address: json['address'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      contactName: json['contactName'] as String?,
      ownerName: json['ownerName'] as String?,
      ownerPhone: json['ownerPhone'] as String?,
    );
  }
}