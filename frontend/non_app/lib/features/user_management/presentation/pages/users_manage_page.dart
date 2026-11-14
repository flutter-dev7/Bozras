import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_decor.dart';
import '../../../../core/utils/error_text.dart';
import '../../../../core/widgets/app_top_bar.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../domain/entities/staff_user.dart';
import '../providers/user_management_providers.dart';
import 'user_form_page.dart';

class UsersManagePage extends ConsumerStatefulWidget {
  const UsersManagePage({super.key});

  @override
  ConsumerState<UsersManagePage> createState() => _UsersManagePageState();
}

class _UsersManagePageState extends ConsumerState<UsersManagePage> {
  String? _role;
  String _search = '';

  void _openForm([StaffUser? user]) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => UserFormPage(user: user)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final users = ref.watch(staffUsersProvider(_role));

    return Scaffold(
      appBar: const AppTopBar(title: 'Сотрудники'),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppDecor.heroMid,
        foregroundColor: Colors.white,
        onPressed: _openForm,
        child: const Icon(Icons.add_rounded),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
            child: TextField(
              onChanged: (v) => setState(() => _search = v.trim().toLowerCase()),
              decoration: const InputDecoration(
                hintText: 'Поиск по имени, телефону, email',
                prefixIcon: Icon(Icons.search_rounded),
              ),
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                _RoleChip(
                  label: 'Все',
                  selected: _role == null,
                  onTap: () => setState(() => _role = null),
                ),
                for (final role in ['Agent', 'Courier', 'Admin', 'Shop'])
                  _RoleChip(
                    label: staffRoleLabels[role]!,
                    selected: _role == role,
                    onTap: () => setState(() => _role = role),
                  ),
              ],
            ),
          ),
          Expanded(
            child: users.when(
              loading: () => const LoadingView(),
              error: (error, _) => ErrorView(
                message: errorText(error),
                onRetry: () => ref.invalidate(staffUsersProvider(_role)),
              ),
              data: (items) {
                final filtered = items.where((u) {
                  if (_search.isEmpty) return true;

                  return u.fullName.toLowerCase().contains(_search) ||
                      u.phone.contains(_search) ||
                      (u.email ?? '').toLowerCase().contains(_search);
                }).toList();

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(staffUsersProvider(_role));
                    await ref.read(staffUsersProvider(_role).future);
                  },
                  child: filtered.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: const [
                            SizedBox(height: 80),
                            EmptyState(
                              icon: AppIcons.store,
                              title: 'Никого не найдено',
                              message: 'Измените фильтр или добавьте сотрудника.',
                            ),
                          ],
                        )
                      : ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 90),
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final user = filtered[index];
                            final editable = user.role != 'Shop';

                            return Card(
                              child: ListTile(
                                onTap: editable ? () => _openForm(user) : null,
                                leading: CircleAvatar(
                                  backgroundColor: AppDecor.fieldFill,
                                  child: Text(
                                    user.fullName.isEmpty
                                        ? '?'
                                        : user.fullName[0].toUpperCase(),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  user.fullName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                subtitle: Text(
                                  '${staffRoleLabels[user.role] ?? user.role}'
                                  ' · ${user.phone}'
                                  '${user.isActive ? '' : ' · заблокирован'}',
                                  style: TextStyle(
                                    color: user.isActive
                                        ? AppColors.muted
                                        : AppColors.error,
                                  ),
                                ),
                                trailing: editable
                                    ? const Icon(Icons.chevron_right_rounded)
                                    : null,
                              ),
                            );
                          },
                        ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleChip extends StatelessWidget {
  const _RoleChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: AppDecor.heroMid,
        labelStyle: TextStyle(
          fontWeight: FontWeight.w700,
          color: selected ? Colors.white : AppColors.brown,
        ),
        showCheckmark: false,
      ),
    );
  }
}