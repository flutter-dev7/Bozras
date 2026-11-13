import '../entities/shop_request.dart';
import '../entities/supplier_profile.dart';

abstract class SupplierRepository {
  Future<SupplierProfile> getProfile();

  Future<void> updateProfile({
    String? phone,
    String? description,
    required bool requiresApproval,
  });

  Future<SupplierProfile> regenerateCode();

  Future<List<ShopRequest>> getRequests();

  Future<void> approveRequest(String id);

  Future<void> rejectRequest(String id);
}