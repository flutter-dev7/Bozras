import '../../domain/entities/production_report.dart';
import '../../domain/entities/sales_report.dart';
import '../../domain/repository/reports_repository.dart';
import '../datasources/reports_remote_data_source.dart';

class ReportsRepositoryImpl implements ReportsRepository {
  ReportsRepositoryImpl(this._remote);

  final ReportsRemoteDataSource _remote;

  @override
  Future<ProductionReport> getProduction(DateTime date) =>
      _remote.getProduction(date);

  @override
  Future<SalesReport> getSales(DateTime from, DateTime to) =>
      _remote.getSales(from, to);
}