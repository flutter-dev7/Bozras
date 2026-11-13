import '../../domain/entities/production_report.dart';

class ProductionReportModel extends ProductionReport {
  const ProductionReportModel({
    required super.ordersCount,
    required super.totalQuantity,
    required super.items,
  });

  factory ProductionReportModel.fromJson(Map<String, dynamic> json) {
    return ProductionReportModel(
      ordersCount: (json['ordersCount'] as num? ?? 0).toInt(),
      totalQuantity: (json['totalQuantity'] as num? ?? 0).toInt(),
      items: (json['items'] as List? ?? const []).map((e) {
        final item = e as Map<String, dynamic>;

        return ProductionItem(
          productId: item['productId'] as String,
          productName: item['productName'] as String? ?? '',
          quantity: (item['quantity'] as num? ?? 0).toInt(),
        );
      }).toList(),
    );
  }
}