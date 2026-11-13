import '../entities/production_report.dart';
import '../entities/sales_report.dart';

abstract class ReportsRepository {
  Future<ProductionReport> getProduction(DateTime date);

  Future<SalesReport> getSales(DateTime from, DateTime to);
}