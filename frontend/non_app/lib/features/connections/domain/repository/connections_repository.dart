import '../entities/location_item.dart';
import '../entities/my_supplier.dart';
import '../entities/shop_profile.dart';
import '../entities/supplier_card.dart';

abstract class ConnectionsRepository {
  /// null, если профиль магазина ещё не заполнен.
  Future<ShopProfile?> getProfile();

  Future<ShopProfile> saveProfile({
    required String name,
    required String address,
    required String phone,
    String? contactName,
    required String locationId,
    double? latitude,
    double? longitude,
  });

  Future<List<SupplierCard>> getNearby(String search);

  Future<List<MySupplier>> getMySuppliers();

  Future<SupplierCard> connectByCode(String code);

  Future<SupplierCard> connectTo(String supplierId);

  Future<List<LocationItem>> getLocations();
}