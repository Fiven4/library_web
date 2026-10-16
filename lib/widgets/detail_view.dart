import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/breakpoints.dart';
import '../state/entity_detail_notifier.dart';
import '../state/load_status.dart';
import 'state_views.dart';

/// Универсальная карточка записи: заголовок, поля, удаление и восстановление.
class DetailView<T> extends StatelessWidget {
  final EntityDetailNotifier<T> notifier;
  final String listPath;
  final String Function(T item) titleOf;
  final bool Function(T item) isDeleted;
  final List<(String, Widget)> Function(T item) fields;
  final Widget Function(T item)? extra;

  const DetailView({
    super.key,
    required this.notifier,
    required this.listPath,
    required this.titleOf,
    required this.isDeleted,
    required this.fields,
    this.extra,
  });

  void _back(BuildContext context) {
    // Если карточку открыли из списка, возвращаемся к нему с теми же условиями;
    // если по прямой ссылке — к списку без условий.
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(listPath);
    }
  }

  Future<bool> _confirm(
    BuildContext context,
    String title,
    String text,
    String action,
  ) async {
    final answer = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(text),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(action),
          ),
        ],
      ),
    );
    return answer ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final compact = screenSizeOf(context) == ScreenSize.compact;
    return Padding(
      padding: EdgeInsets.all(compact ? 12 : 24),
      child: ListenableBuilder(
        listenable: notifier,
        builder: (context, _) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                key: const ValueKey('back-button'),
                onPressed: () => _back(context),
                icon: const Icon(Icons.arrow_back),
                label: const Text('К списку'),
              ),
            ),
            Expanded(child: _body(context)),
          ],
        ),
      ),
    );
  }

  Widget _body(BuildContext context) {
    if (notifier.status == LoadStatus.error) {
      return ErrorView(
        message: notifier.error ?? 'Ошибка',
        onRetry: notifier.load,
      );
    }
    if (notifier.status != LoadStatus.success) return const LoadingView();
    final item = notifier.item;
    if (item == null) {
      return const EmptyView(
        message: 'Запись не найдена или удалена навсегда.',
      );
    }

    final deleted = isDeleted(item);
    final theme = Theme.of(context);
    return SingleChildScrollView(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(titleOf(item), style: theme.textTheme.headlineSmall),
                  if (deleted)
                    Chip(
                      label: const Text('удалена'),
                      backgroundColor: theme.colorScheme.errorContainer,
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      for (final (label, value) in fields(item))
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 140,
                                child: Text(
                                  label,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                              Expanded(child: value),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              if (extra != null) ...[const SizedBox(height: 16), extra!(item)],
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  if (!deleted)
                    OutlinedButton.icon(
                      key: const ValueKey('detail-delete'),
                      onPressed: () async {
                        final ok = await _confirm(
                          context,
                          'Удалить запись?',
                          'Запись будет помечена удалённой. Её можно восстановить.',
                          'Удалить',
                        );
                        if (ok) await notifier.softDelete();
                      },
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Удалить'),
                    )
                  else
                    FilledButton.icon(
                      key: const ValueKey('detail-restore'),
                      onPressed: notifier.restore,
                      icon: const Icon(Icons.restore),
                      label: const Text('Восстановить'),
                    ),
                  TextButton.icon(
                    key: const ValueKey('detail-hard-delete'),
                    style: TextButton.styleFrom(
                      foregroundColor: theme.colorScheme.error,
                    ),
                    onPressed: () async {
                      final ok = await _confirm(
                        context,
                        'Удалить навсегда?',
                        'Запись будет стёрта безвозвратно.',
                        'Удалить навсегда',
                      );
                      if (ok) await notifier.hardDelete();
                    },
                    icon: const Icon(Icons.delete_forever_outlined),
                    label: const Text('Удалить навсегда'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
