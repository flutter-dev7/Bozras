import 'package:flutter/material.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/theme/app_colors.dart';

class RegionField extends StatelessWidget {
  const RegionField({
    super.key,
    required this.regionName,
    required this.onTap,
    this.showError = false,
    this.enabled = true,
  });

  final String? regionName;
  final VoidCallback onTap;
  final bool showError;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: enabled ? onTap : null,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Регион',
          prefixIcon: const Icon(AppIcons.location),
          suffixIcon: const Icon(Icons.chevron_right),
          errorText: showError ? 'Выберите регион' : null,
        ),
        child: Text(
          regionName ?? 'Не выбран',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: regionName == null ? AppColors.muted : AppColors.brown,
          ),
        ),
      ),
    );
  }
}