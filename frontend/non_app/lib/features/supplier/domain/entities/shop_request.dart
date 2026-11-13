class ShopRequest {
  const ShopRequest({
    required this.id,
    required this.name,
    required this.address,
    required this.phone,
    this.contactName,
    this.ownerName,
    this.ownerPhone,
  });

  final String id;
  final String name;
  final String address;
  final String phone;
  final String? contactName;
  final String? ownerName;
  final String? ownerPhone;
}