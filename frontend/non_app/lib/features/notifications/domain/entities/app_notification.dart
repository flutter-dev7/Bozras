class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.orderId,
    required this.supplierId,
    required this.receivedAt,
    required this.read,
  });

  final String id;
  final String title;
  final String body;
  final String? orderId;
  final String? supplierId;
  final DateTime receivedAt;
  final bool read;

  AppNotification markRead() => AppNotification(
        id: id,
        title: title,
        body: body,
        orderId: orderId,
        supplierId: supplierId,
        receivedAt: receivedAt,
        read: true,
      );
}