import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import 'app_snackbar.dart';

Future<LatLng?> currentLocation(BuildContext context) async {
  void fail(String message) {
    if (context.mounted) AppSnackBar.show(context, message, isError: true);
  }

  try {
    if (!await Geolocator.isLocationServiceEnabled()) {
      fail('Включите геолокацию на телефоне');
      return null;
    }

    var permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      fail('Нет доступа к местоположению. Разрешите его в настройках');
      return null;
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );

    return LatLng(position.latitude, position.longitude);
  } catch (_) {
    fail('Не удалось определить местоположение');
    return null;
  }
}