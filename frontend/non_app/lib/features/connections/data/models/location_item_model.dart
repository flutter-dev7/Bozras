import '../../domain/entities/location_item.dart';

class LocationItemModel extends LocationItem {
  const LocationItemModel({
    required super.id,
    required super.name,
    required super.type,
    super.parentId,
  });

  factory LocationItemModel.fromJson(Map<String, dynamic> json) {
    return LocationItemModel(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      type: json['type']?.toString() ?? '',
      parentId: json['parentId'] as String?,
    );
  }
}