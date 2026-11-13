import '../../domain/entities/shop_request.dart';
import '../../domain/entities/supplier_profile.dart';
import '../../domain/repository/supplier_repository.dart';
import '../datasources/supplier_remote_data_source.dart';

class SupplierRepositoryImpl implements SupplierRepository {
  SupplierRepositoryImpl(this._remote);

  final SupplierRemoteDataSource _remote;

  @override
  Future<SupplierProfile> getProfile() => _remote.getProfile();

  @override
  Future<void> updateProfile({
    String? phone,
    String? description,
    required bool requiresApproval,
  }) => _remote.updateProfile(
    phone: phone,
    description: description,
    requiresApproval: requiresApproval,
  );

  @override
  Future<SupplierProfile> regenerateCode() => _remote.regenerateCode();

  @override
  Future<List<ShopRequest>> getRequests() => _remote.getRequests();

  @override
  Future<void> approveRequest(String id) => _remote.approveRequest(id);

  @override
  Future<void> rejectRequest(String id) => _remote.rejectRequest(id);
}