class ManagedShop {
  const ManagedShop({
    required this.id,
    required this.name,
    required this.address,
    required this.phone,
    required this.isActive,
    this.contactName,
    this.latitude,
    this.longitude,
    this.debtLimit,
    this.ownerName,
    this.ownerPhone,
  });

  final String id;
  final String name;
  final String address;
  final String phone;
  final bool isActive;
  final String? contactName;
  final double? latitude;
  final double? longitude;
  final double? debtLimit;
  final String? ownerName;
  final String? ownerPhone;
}