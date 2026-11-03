import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_snackbar.dart';
import '../../../../core/widgets/app_top_bar.dart';
import '../../../../core/widgets/primary_button.dart';

Future<LatLng?> pickLocation(BuildContext context, {LatLng? initial}) {
  return Navigator.of(context).push<LatLng>(
    MaterialPageRoute(builder: (_) => MapPickerPage(initial: initial)),
  );
}

class MapPickerPage extends StatefulWidget {
  const MapPickerPage({super.key, this.initial});

  final LatLng? initial;

  @override
  State<MapPickerPage> createState() => _MapPickerPageState();
}

class _MapPickerPageState extends State<MapPickerPage> {
  static const _dushanbe = LatLng(38.5598, 68.7870);

  final _controller = MapController();
  LatLng? _selected;
  bool _locating = false;

  @override
  void initState() {
    super.initState();
    _selected = widget.initial;
  }

  void _error(String message) {
    if (mounted) AppSnackBar.show(context, message, isError: true);
  }

  Future<void> _locate() async {
    setState(() => _locating = true);

    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        _error('Включите геолокацию на телефоне');
        return;
      }

      var permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _error('Нет доступа к местоположению. Разрешите его в настройках');
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );

      final point = LatLng(position.latitude, position.longitude);

      if (!mounted) return;

      setState(() => _selected = point);
      _controller.move(point, 17);
    } catch (_) {
      _error('Не удалось определить местоположение');
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  void _confirm() {
    final point = _selected;

    if (point == null) {
      _error('Нажмите на карту, чтобы поставить точку');
      return;
    }

    Navigator.of(context).pop(point);
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selected;

    return Scaffold(
      appBar: const AppTopBar(title: 'Расположение магазина'),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _controller,
                  options: MapOptions(
                    initialCenter: widget.initial ?? _dushanbe,
                    initialZoom: widget.initial != null ? 17 : 13,
                    onTap: (_, point) => setState(() => _selected = point),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'tj.non.non_app',
                    ),
                    if (selected != null)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: selected,
                            width: 48,
                            height: 48,
                            alignment: Alignment.topCenter,
                            child: const Icon(
                              Icons.location_on,
                              size: 48,
                              color: AppColors.error,
                            ),
                          ),
                        ],
                      ),
                    const RichAttributionWidget(
                      attributions: [TextSourceAttribution('© OpenStreetMap contributors')],
                    ),
                  ],
                ),
                Positioned(
                  right: 16,
                  top: 16,
                  child: FloatingActionButton.small(
                    heroTag: null,
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.brown,
                    onPressed: _locating ? null : _locate,
                    child: _locating
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.my_location),
                  ),
                ),
              ],
            ),
          ),
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    selected == null
                        ? 'Нажмите на карту или кнопку «Я здесь» справа вверху'
                        : '${selected.latitude.toStringAsFixed(5)}, ${selected.longitude.toStringAsFixed(5)}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  PrimaryButton(label: 'Подтвердить точку', onPressed: _confirm),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}