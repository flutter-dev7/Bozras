import 'connection_status.dart';

class MySupplier {
  const MySupplier({
    required this.supplierId,
    required this.name,
    this.phone,
    this.description,
    this.logoUrl,
    required this.status,
    required this.isAvailable,
  });

  final String supplierId;
  final String name;
  final String? phone;
  final String? description;
  final String? logoUrl;
  final ConnectionStatus status;
  final bool isAvailable;
}