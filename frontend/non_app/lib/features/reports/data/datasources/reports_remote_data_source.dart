import '../../../../core/network/api_client.dart';
import '../../../../core/utils/formatters.dart';
import '../models/production_report_model.dart';
import '../models/sales_report_model.dart';

class ReportsRemoteDataSource {
  ReportsRemoteDataSource(this._client);

  final ApiClient _client;

  Future<ProductionReportModel> getProduction(DateTime date) async {
    final path = Uri(
      path: '/api/Reports/production',
      queryParameters: {'Date': Formatters.apiDate(date)},
    ).toString();

    final data = await _client.get(path);

    return ProductionReportModel.fromJson(data as Map<String, dynamic>);
  }

  Future<SalesReportModel> getSales(DateTime from, DateTime to) async {
    final path = Uri(
      path: '/api/Reports/sales',
      queryParameters: {
        'From': Formatters.apiDate(from),
        'To': Formatters.apiDate(to),
      },
    ).toString();

    final data = await _client.get(path);

    return SalesReportModel.fromJson(data as Map<String, dynamic>);
  }
}