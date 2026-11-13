import '../../domain/entities/connection_status.dart';

ConnectionStatus parseConnectionStatus(Object? value) {
  switch (value?.toString().toLowerCase()) {
    case 'active':
    case '1':
      return ConnectionStatus.active;
    case 'pending':
    case '2':
      return ConnectionStatus.pending;
    default:
      return ConnectionStatus.rejected;
  }
}