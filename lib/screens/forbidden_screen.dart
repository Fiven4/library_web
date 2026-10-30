import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../state/auth_notifier.dart';

class ForbiddenScreen extends StatelessWidget {
  const ForbiddenScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.watch<AuthNotifier>();
    final roleName = auth.user?.role.label ?? 'Гость';

    return Scaffold(
      appBar: AppBar(title: const Text('Доступ ограничен')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(36),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.errorContainer.withValues(
                          alpha: 0.4,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.shield_outlined,
                        size: 64,
                        color: theme.colorScheme.error,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      '403 – Доступ запрещён',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'У вашей текущей роли ($roleName) недостаточно прав для просмотра данного экрана '
                      'или выполнения запрошенного действия. Клиентский маршрутизатор перехватил переход '
                      'в функции redirect.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 28),
                    FilledButton.icon(
                      key: const Key('forbidden-back-btn'),
                      onPressed: () => context.go('/books'),
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Вернуться в каталог книг'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
