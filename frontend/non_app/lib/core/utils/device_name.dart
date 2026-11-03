import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';

class DeviceName {
  DeviceName._();

  static String? _cached;

  static Future<String> read() async {
    final cached = _cached;

    if (cached != null) return cached;

    String name;

    try {
      final plugin = DeviceInfoPlugin();

      if (Platform.isAndroid) {
        final info = await plugin.androidInfo;
        final brand = info.brand.isEmpty
            ? ''
            : '${info.brand[0].toUpperCase()}${info.brand.substring(1)} ';

        name = '$brand${info.model} · Android ${info.version.release}';
      } else if (Platform.isIOS) {
        final info = await plugin.iosInfo;

        name = '${info.name} · iOS ${info.systemVersion}';
      } else {
        name = 'Устройство';
      }
    } catch (_) {
      name = 'Устройство';
    }

    return _cached = name;
  }
}