import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/dev_settings.dart';

class DevMenu extends StatelessWidget {
  const DevMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final dev = context.watch<DevSettings>();
    return PopupMenuButton<String>(
      key: const ValueKey('dev-menu'),
      tooltip: 'Проверка состояний',
      icon: Icon(
        Icons.science_outlined,
        color: (dev.failing || dev.slow)
            ? Theme.of(context).colorScheme.error
            : null,
      ),
      onSelected: (value) {
        final settings = context.read<DevSettings>();
        if (value == 'fail') settings.failing = !settings.failing;
        if (value == 'slow') settings.slow = !settings.slow;
      },
      itemBuilder: (_) => [
        CheckedPopupMenuItem(
          value: 'fail',
          checked: dev.failing,
          child: const Text('Имитировать сбой сервера'),
        ),
        CheckedPopupMenuItem(
          value: 'slow',
          checked: dev.slow,
          child: const Text('Замедлить ответ (4 с)'),
        ),
      ],
    );
  }
}
