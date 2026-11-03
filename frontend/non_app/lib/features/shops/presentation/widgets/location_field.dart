import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_decor.dart';
import '../pages/map_picker_page.dart';

class LocationField extends StatelessWidget {
  const LocationField({
    super.key,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  final LatLng? value;
  final ValueChanged<LatLng> onChanged;
  final bool enabled;

  Future<void> _pick(BuildContext context) async {
    final point = await pickLocation(context, initial: value);

    if (point != null) onChanged(point);
  }

  @override
  Widget build(BuildContext context) {
    final point = value;

    return Material(
      color: AppDecor.fieldFill,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: enabled ? () => _pick(context) : null,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.map_outlined, color: AppDecor.heroMid),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Расположение на карте',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: AppColors.muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      point == null
                          ? 'Не указано'
                          : '${point.latitude.toStringAsFixed(5)}, ${point.longitude.toStringAsFixed(5)}',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15.5),
                    ),
                  ],
                ),
              ),
              Text(
                point == null ? 'Указать' : 'Изменить',
                style: const TextStyle(
                  color: AppDecor.heroMid,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}