import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:non_app/core/widgets/app_dialogs.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_decor.dart';
import '../../../../core/utils/app_snackbar.dart';
import '../../../../core/utils/error_text.dart';
import '../providers/product_management_providers.dart';

class CategoriesSheet extends ConsumerWidget {
  const CategoriesSheet({super.key});

  Future<void> _run(
    BuildContext context,
    WidgetRef ref,
    Future<void> Function() action,
  ) async {
    try {
      await action();

      ref.invalidate(manageCategoriesProvider);
      ref.invalidate(productsManageProvider);
    } on ApiException catch (e) {
      if (context.mounted) {
        AppSnackBar.show(context, e.message, isError: true);
      }
    }
  }

  Future<void> _add(BuildContext context, WidgetRef ref) async {
    final name = await showDialog<String>(
      context: context,
      builder: (_) => const _NameDialog(title: 'Новая категория'),
    );

    if (name == null || !context.mounted) return;

    await _run(context, ref, () => ref.read(createCategoryUseCaseProvider)(name));
  }

  Future<void> _rename(
    BuildContext context,
    WidgetRef ref,
    String id,
    String current,
  ) async {
    final name = await showDialog<String>(
      context: context,
      builder: (_) => _NameDialog(title: 'Переименовать', initial: current),
    );

    if (name == null || !context.mounted) return;

    await _run(
      context,
      ref,
      () => ref.read(renameCategoryUseCaseProvider)(id, name),
    );
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    String id,
    String name,
  ) async {
    final confirmed = await AppDialogs.confirm(
      context,
      title: 'Удалить категорию?',
      message: 'Категория «$name» будет удалена.',
      confirmLabel: 'Удалить',
      destructive: true,
    );

    if (!confirmed || !context.mounted) return;

    await _run(context, ref, () => ref.read(deleteCategoryUseCaseProvider)(id));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(manageCategoriesProvider);

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(
                'Категории',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
            ),
            Flexible(
              child: categories.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (error, _) => Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(child: Text(errorText(error))),
                ),
                data: (list) => list.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(
                          child: Text(
                            'Категорий пока нет',
                            style: TextStyle(color: AppColors.muted),
                          ),
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                        itemCount: list.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final category = list[index];

                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              category.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            subtitle: Text('Товаров: ${category.productsCount}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(AppIcons.edit, size: 20),
                                  onPressed: () => _rename(
                                    context,
                                    ref,
                                    category.id,
                                    category.name,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    AppIcons.trash,
                                    size: 20,
                                    color: AppColors.error,
                                  ),
                                  onPressed: () => _delete(
                                    context,
                                    ref,
                                    category.id,
                                    category.name,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  backgroundColor: AppDecor.heroMid,
                ),
                onPressed: () => _add(context, ref),
                icon: const Icon(AppIcons.plus, size: 20),
                label: const Text('Добавить категорию'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NameDialog extends StatefulWidget {
  const _NameDialog({required this.title, this.initial = ''});

  final String title;
  final String initial;

  @override
  State<_NameDialog> createState() => _NameDialogState();
}

class _NameDialogState extends State<_NameDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initial);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _done() {
    final name = _controller.text.trim();

    if (name.isNotEmpty) Navigator.of(context).pop(name);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text(
        widget.title,
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLength: 100,
        textCapitalization: TextCapitalization.sentences,
        decoration: const InputDecoration(labelText: 'Название'),
        onSubmitted: (_) => _done(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Отмена'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size(0, 46)),
          onPressed: _done,
          child: const Text('Готово'),
        ),
      ],
    );
  }
}