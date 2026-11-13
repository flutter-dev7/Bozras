import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/error_text.dart';
import '../../../../core/widgets/app_top_bar.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../domain/entities/location_item.dart';
import '../providers/connections_providers.dart';

class RegionPickerPage extends ConsumerStatefulWidget {
  const RegionPickerPage({super.key});

  @override
  ConsumerState<RegionPickerPage> createState() => _RegionPickerPageState();
}

class _RegionPickerPageState extends ConsumerState<RegionPickerPage> {
  String _query = '';

  String _path(LocationItem item, Map<String, LocationItem> byId) {
    final names = <String>[];
    var parent = item.parentId == null ? null : byId[item.parentId];

    while (parent != null) {
      names.add(parent.name);
      parent = parent.parentId == null ? null : byId[parent.parentId];
    }

    return names.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final locations = ref.watch(locationsProvider);

    return Scaffold(
      appBar: const AppTopBar(title: 'Регион'),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: TextField(
              onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
              decoration: const InputDecoration(
                hintText: 'Поиск города или района',
                prefixIcon: Icon(AppIcons.search, size: 22),
              ),
            ),
          ),
          Expanded(
            child: locations.when(
              loading: () => const LoadingView(),
              error: (error, _) => ErrorView(
                message: errorText(error),
                onRetry: () => ref.invalidate(locationsProvider),
              ),
              data: (items) {
                final byId = {for (final i in items) i.id: i};

                final visible = items
                    .where((i) => i.type.toLowerCase() != 'region')
                    .where((i) => _query.isEmpty || i.name.toLowerCase().contains(_query))
                    .toList()
                  ..sort((a, b) => a.name.compareTo(b.name));

                if (visible.isEmpty) {
                  return const EmptyState(
                    icon: AppIcons.location,
                    title: 'Ничего не найдено',
                    message: 'Измените поиск.',
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  itemCount: visible.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = visible[index];
                    final path = _path(item, byId);

                    return Card(
                      child: ListTile(
                        title: Text(
                          item.name,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: path.isEmpty
                            ? null
                            : Text(path, style: const TextStyle(color: AppColors.muted)),
                        onTap: () => Navigator.of(context).pop(item),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}