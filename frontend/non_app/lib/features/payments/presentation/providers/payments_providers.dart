import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:non_app/features/payments/data/payments_remote_data_source.dart';

import '../../../../core/providers/core_providers.dart';

final paymentsRemoteProvider = Provider(
  (ref) => PaymentsRemoteDataSource(ref.watch(apiClientProvider)),
);