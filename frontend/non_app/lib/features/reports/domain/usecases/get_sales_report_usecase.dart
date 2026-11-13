import '../entities/sales_report.dart';
import '../repository/reports_repository.dart';

class GetSalesReportUseCase {
  GetSalesReportUseCase(this._repository);

  final ReportsRepository _repository;

  Future<SalesReport> call(DateTime from, DateTime to) =>
      _repository.getSales(from, to);
}