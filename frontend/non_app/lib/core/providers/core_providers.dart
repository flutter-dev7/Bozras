import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/api_client.dart';
import '../network/session_events.dart';
import '../storage/supplier_storage.dart';
import '../storage/token_storage.dart';

final tokenStorageProvider = Provider<TokenStorage>((ref) => TokenStorage());

final supplierStorageProvider = Provider<SupplierStorage>((ref) => SupplierStorage());

final sessionEventsProvider = Provider<SessionEvents>((ref) {
  final events = SessionEvents();
  ref.onDispose(events.dispose);
  return events;
});

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(
    tokenStorage: ref.watch(tokenStorageProvider),
    supplierStorage: ref.watch(supplierStorageProvider),
    sessionEvents: ref.watch(sessionEventsProvider),
  );
});