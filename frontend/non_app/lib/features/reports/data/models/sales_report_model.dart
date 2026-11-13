import '../../../../core/utils/formatters.dart';
import '../../domain/entities/sales_report.dart';

class SalesReportModel extends SalesReport {
  const SalesReportModel({
    required super.ordersCount,
    required super.totalQuantity,
    required super.totalAmount,
    required super.receivedPayments,
    required super.byDay,
    required super.byProduct,
  });

  factory SalesReportModel.fromJson(Map<String, dynamic> json) {
    return SalesReportModel(
      ordersCount: (json['ordersCount'] as num? ?? 0).toInt(),
      totalQuantity: (json['totalQuantity'] as num? ?? 0).toInt(),
      totalAmount: (json['totalAmount'] as num? ?? 0).toDouble(),
      receivedPayments: (json['receivedPayments'] as num? ?? 0).toDouble(),
      byDay: (json['byDay'] as List? ?? const []).map((e) {
        final day = e as Map<String, dynamic>;

        return SalesDay(
          date: Formatters.parseDate(day['date'] as String),
          ordersCount: (day['ordersCount'] as num? ?? 0).toInt(),
          amount: (day['amount'] as num? ?? 0).toDouble(),
        );
      }).toList(),
      byProduct: (json['byProduct'] as List? ?? const []).map((e) {
        final product = e as Map<String, dynamic>;

        return SalesProduct(
          productId: product['productId'] as String,
          productName: product['productName'] as String? ?? '',
          quantity: (product['quantity'] as num? ?? 0).toInt(),
          amount: (product['amount'] as num? ?? 0).toDouble(),
        );
      }).toList(),
    );
  }
}