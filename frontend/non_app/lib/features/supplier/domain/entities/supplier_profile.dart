class SupplierProfile {
  const SupplierProfile({
    required this.id,
    required this.name,
    required this.code,
    required this.requiresApproval,
    required this.subscriptionStatus,
    this.phone,
    this.description,
    this.logoUrl,
    this.planName,
    this.subscriptionEndsAt,
  });

  final String id;
  final String name;
  final String code;
  final bool requiresApproval;
  final String subscriptionStatus;
  final String? phone;
  final String? description;
  final String? logoUrl;
  final String? planName;
  final DateTime? subscriptionEndsAt;
}