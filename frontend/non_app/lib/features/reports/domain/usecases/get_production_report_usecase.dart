import '../entities/production_report.dart';
import '../repository/reports_repository.dart';

class GetProductionReportUseCase {
  GetProductionReportUseCase(this._repository);

  final ReportsRepository _repository;

  Future<ProductionReport> call(DateTime date) => _repository.getProduction(date);
}