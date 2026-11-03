import 'package:non_app/features/orders/domain/entities/payment_method.dart';

import '../../../../core/network/api_client.dart';

class PaymentsRemoteDataSource {
  PaymentsRemoteDataSource(this._client);

  final ApiClient _client;

  Future<void> createPayment({
    required String shopId,
    required double amount,
    required PaymentMethod method,
  }) async {
    await _client.post(
      '/api/Payments',
      data: {'shopId': shopId, 'amount': amount, 'method': method.apiName},
    );
  }
}