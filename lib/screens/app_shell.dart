import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/breakpoints.dart';
import '../storage/storage_notices.dart';

/// Каркас приложения с адаптивной навигацией: на узком окне нижняя панель,
/// на широком боковая полоса (раскрытая от 1500 пикселей).
class AppShell extends StatefulWidget {
  final String location;
  final Widget child;

  const AppShell({super.key, required this.location, required this.child});

  static const destinations = [
    (icon: Icons.menu_book_outlined, label: 'Книги', path: '/books'),
    (icon: Icons.person_outline, label: 'Авторы', path: '/authors'),
    (icon: Icons.category_outlined, label: 'Жанры', path: '/genres'),
    (
      icon: Icons.apartment_outlined,
      label: 'Издательства',
      path: '/publishers',
    ),
    (icon: Icons.badge_outlined, label: 'Читатели', path: '/readers'),
  ];

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late final StorageNotices _notices = context.read<StorageNotices>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _showNotices());
  }

  /// Сообщения хранилища (перенос или сброс данных) показываются один раз.
  void _showNotices() {
    if (!mounted) return;
    final messages = _notices.take();
    if (messages.isEmpty) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          key: const ValueKey('storage-notice'),
          duration: const Duration(seconds: 8),
          content: Text(messages.join('\n')),
          showCloseIcon: true,
        ),
      );
  }

  int get _selectedIndex => AppShell.destinations
      .indexWhere((d) => widget.location.startsWith(d.path))
      .clamp(0, AppShell.destinations.length - 1);

  void _select(BuildContext context, int index) =>
      context.go(AppShell.destinations[index].path);

  @override
  Widget build(BuildContext context) {
    final size = screenSizeOf(context);
    final destinations = AppShell.destinations;

    if (size == ScreenSize.compact) {
      return Scaffold(
        body: SafeArea(child: widget.child),
        bottomNavigationBar: NavigationBarTheme(
          // Пять разделов: подписи мельче, иначе «Издательства» переносится.
          data: const NavigationBarThemeData(
            labelTextStyle: WidgetStatePropertyAll(TextStyle(fontSize: 10)),
          ),
          child: NavigationBar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (i) => _select(context, i),
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            destinations: [
              for (final d in destinations)
                NavigationDestination(icon: Icon(d.icon), label: d.label),
            ],
          ),
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
            minWidth: 72,
            selectedLabelTextStyle: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelTextStyle: const TextStyle(fontSize: 11),
            leading: const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Icon(Icons.local_library_outlined, size: 32),
            ),
            destinations: [
              for (final d in destinations)
                NavigationRailDestination(
                  icon: Icon(d.icon),
                  label: Text(d.label),
                ),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(child: SafeArea(child: widget.child)),
        ],
      ),
    );
  }
}
