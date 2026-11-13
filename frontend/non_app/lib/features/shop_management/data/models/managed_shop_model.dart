import '../../domain/entities/managed_shop.dart';

class ManagedShopModel extends ManagedShop {
  const ManagedShopModel({
    required super.id,
    required super.name,
    required super.address,
    required super.phone,
    required super.isActive,
    super.contactName,
    super.latitude,
    super.longitude,
    super.debtLimit,
    super.ownerName,
    super.ownerPhone,
  });

  factory ManagedShopModel.fromJson(Map<String, dynamic> json) {
    return ManagedShopModel(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      address: json['address'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      isActive: json['isActive'] as bool? ?? true,
      contactName: json['contactName'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      debtLimit: (json['debtLimit'] as num?)?.toDouble(),
      ownerName: json['ownerName'] as String?,
      ownerPhone: json['ownerPhone'] as String?,
    );
  }
}