import '../../../../core/network/api_exception.dart';
import '../../domain/entities/location_item.dart';
import '../../domain/entities/my_supplier.dart';
import '../../domain/entities/shop_profile.dart';
import '../../domain/entities/supplier_card.dart';
import '../../domain/repository/connections_repository.dart';
import '../datasources/connections_remote_data_source.dart';

class ConnectionsRepositoryImpl implements ConnectionsRepository {
  ConnectionsRepositoryImpl(this._remote);

  final ConnectionsRemoteDataSource _remote;

  @override
  Future<ShopProfile?> getProfile() async {
    try {
      return await _remote.getProfile();
    } on ApiException catch (e) {
      if (e.type == ApiErrorType.notFound) return null;

      rethrow;
    }
  }

  @override
  Future<ShopProfile> saveProfile({
    required String name,
    required String address,
    required String phone,
    String? contactName,
    required String locationId,
    double? latitude,
    double? longitude,
  }) {
    return _remote.saveProfile(
      name: name,
      address: address,
      phone: phone,
      contactName: contactName,
      locationId: locationId,
      latitude: latitude,
      longitude: longitude,
    );
  }

  @override
  Future<List<SupplierCard>> getNearby(String search) => _remote.getNearby(search);

  @override
  Future<List<MySupplier>> getMySuppliers() => _remote.getMySuppliers();

  @override
  Future<SupplierCard> connectByCode(String code) => _remote.connectByCode(code);

  @override
  Future<SupplierCard> connectTo(String supplierId) => _remote.connectTo(supplierId);

  @override
  Future<List<LocationItem>> getLocations() => _remote.getLocations();
}