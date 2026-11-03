import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'app_snackbar.dart';

Future<void> openRoute(
  BuildContext context, {
  double? latitude,
  double? longitude,
  String? address,
}) async {
  final hasPoint = latitude != null && longitude != null;
  final hasAddress = address != null && address.trim().isNotEmpty;

  if (!hasPoint && !hasAddress) {
    AppSnackBar.show(context, 'У магазина не указан адрес', isError: true);
    return;
  }

  final uri = hasPoint
      ? Uri.parse('geo:$latitude,$longitude?q=$latitude,$longitude')
      : Uri(scheme: 'geo', path: '0,0', queryParameters: {'q': address!.trim()});

  var opened = false;

  try {
    opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    opened = false;
  }

  if (!opened && hasPoint) {
    try {
      opened = await launchUrl(
        Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$latitude,$longitude'),
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {
      opened = false;
    }
  }

  if (!opened && context.mounted) {
    AppSnackBar.show(context, 'Не удалось открыть карты', isError: true);
  }
}