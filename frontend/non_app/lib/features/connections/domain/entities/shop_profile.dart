class ShopProfile {
  const ShopProfile({
    required this.id,
    required this.name,
    required this.address,
    required this.phone,
    this.contactName,
    this.locationId,
    this.locationName,
    this.latitude,
    this.longitude,
  });

  final String id;
  final String name;
  final String address;
  final String phone;
  final String? contactName;
  final String? locationId;
  final String? locationName;
  final double? latitude;
  final double? longitude;
}