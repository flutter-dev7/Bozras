class LocationItem {
  const LocationItem({
    required this.id,
    required this.name,
    required this.type,
    this.parentId,
  });

  final String id;
  final String name;
  final String type;
  final String? parentId;
}