import 'connection_status.dart';

class SupplierCard {
  const SupplierCard({
    required this.id,
    required this.name,
    this.phone,
    this.description,
    this.logoUrl,
    required this.requiresApproval,
    this.status,
  });

  final String id;
  final String name;
  final String? phone;
  final String? description;
  final String? logoUrl;
  final bool requiresApproval;
  final ConnectionStatus? status;
}