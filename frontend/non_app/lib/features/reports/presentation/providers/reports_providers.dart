import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/core_providers.dart';
import '../../../../core/utils/formatters.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/datasources/reports_remote_data_source.dart';
import '../../data/repository/reports_repository_impl.dart';
import '../../domain/entities/production_report.dart';
import '../../domain/entities/sales_report.dart';
import '../../domain/repository/reports_repository.dart';
import '../../domain/usecases/get_production_report_usecase.dart';
import '../../domain/usecases/get_sales_report_usecase.dart';

final reportsRepositoryProvider = Provider<ReportsRepository>((ref) {
  return ReportsRepositoryImpl(
    ReportsRemoteDataSource(ref.watch(apiClientProvider)),
  );
});

final getProductionReportUseCaseProvider = Provider(
  (ref) => GetProductionReportUseCase(ref.watch(reportsRepositoryProvider)),
);
final getSalesReportUseCaseProvider = Provider(
  (ref) => GetSalesReportUseCase(ref.watch(reportsRepositoryProvider)),
);

DateTime _tomorrow() {
  final today = Formatters.today();

  return DateTime(today.year, today.month, today.day + 1);
}

final productionDateProvider =
    NotifierProvider<ProductionDateNotifier, DateTime>(
      ProductionDateNotifier.new,
    );

class ProductionDateNotifier extends Notifier<DateTime> {
  @override
  DateTime build() => _tomorrow();

  void select(DateTime date) => state = date;
}

final productionProvider = FutureProvider.autoDispose<ProductionReport>((ref) {
  ref.watch(currentUserIdProvider);

  return ref.watch(getProductionReportUseCaseProvider)(
    ref.watch(productionDateProvider),
  );
});

DateTimeRange currentMonthRange() {
  final today = Formatters.today();

  return DateTimeRange(
    start: DateTime(today.year, today.month, 1),
    end: DateTime(today.year, today.month, today.day),
  );
}

final salesRangeProvider = NotifierProvider<SalesRangeNotifier, DateTimeRange>(
  SalesRangeNotifier.new,
);

class SalesRangeNotifier extends Notifier<DateTimeRange> {
  @override
  DateTimeRange build() => currentMonthRange();

  void select(DateTimeRange range) => state = range;
}

final salesProvider = FutureProvider.autoDispose<SalesReport>((ref) {
  ref.watch(currentUserIdProvider);

  final range = ref.watch(salesRangeProvider);

  return ref.watch(getSalesReportUseCaseProvider)(range.start, range.end);
});