abstract class SettingsRepository {
  Future<String> getOrderCutoffTime();

  Future<void> updateOrderCutoffTime(String time);
}