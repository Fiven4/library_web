import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/breakpoints.dart';

/// Каркас приложения с адаптивной навигацией: на узком окне нижняя панель,
/// на широком боковая полоса (раскрытая от 1500 пикселей).
class AppShell extends StatelessWidget {
  final String location;
  final Widget child;

  const AppShell({super.key, required this.location, required this.child});

  static const _destinations = [
    (icon: Icons.menu_book_outlined, label: 'Книги', path: '/books'),
    (icon: Icons.person_outline, label: 'Авторы', path: '/authors'),
  ];

  int get _selectedIndex =>
      _destinations.indexWhere((d) => location.startsWith(d.path)).clamp(0, 1);

  void _select(BuildContext context, int index) =>
      context.go(_destinations[index].path);

  @override
  Widget build(BuildContext context) {
    final size = screenSizeOf(context);

    if (size == ScreenSize.compact) {
      return Scaffold(
        body: SafeArea(child: child),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: (i) => _select(context, i),
          destinations: [
            for (final d in _destinations)
              NavigationDestination(icon: Icon(d.icon), label: d.label),
          ],
        ),
      );
    }

    // Раскрытая полоса съедает 176 пикселей у таблицы, поэтому подписи
    // встают рядом со значками только на очень широком окне.
    final extended = MediaQuery.sizeOf(context).width >= 1500;
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (i) => _select(context, i),
            extended: extended,
            // extended и labelType, отличный от none, вместе недопустимы.
            labelType: extended
                ? NavigationRailLabelType.none
                : NavigationRailLabelType.all,
            leading: const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Icon(Icons.local_library_outlined, size: 32),
            ),
            destinations: [
              for (final d in _destinations)
                NavigationRailDestination(
                  icon: Icon(d.icon),
                  label: Text(d.label),
                ),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(child: SafeArea(child: child)),
        ],
      ),
    );
  }
}
