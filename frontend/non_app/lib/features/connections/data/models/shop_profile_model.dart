import '../../domain/entities/shop_profile.dart';

class ShopProfileModel extends ShopProfile {
  const ShopProfileModel({
    required super.id,
    required super.name,
    required super.address,
    required super.phone,
    super.contactName,
    super.locationId,
    super.locationName,
    super.latitude,
    super.longitude,
  });

  factory ShopProfileModel.fromJson(Map<String, dynamic> json) {
    return ShopProfileModel(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      address: json['address'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      contactName: json['contactName'] as String?,
      locationId: json['locationId'] as String?,
      locationName: json['locationName'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );
  }
}