import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/breakpoints.dart';
import '../models/role.dart';
import '../state/auth_notifier.dart';
import '../storage/storage_notices.dart';
import '../widgets/inactivity_watcher.dart';

class AppShell extends StatefulWidget {
  final String location;
  final Widget child;

  const AppShell({super.key, required this.location, required this.child});

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

  List<({IconData icon, String label, String path})> _getDestinations(
    AuthNotifier? auth,
  ) {
    final list = <({IconData icon, String label, String path})>[
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

    if (auth?.has(Role.admin) ?? false) {
      list.add((
        icon: Icons.manage_accounts_outlined,
        label: 'Пользователи',
        path: '/admin/users',
      ));
    }
    return list;
  }

  int _getSelectedIndex(
    List<({IconData icon, String label, String path})> destinations,
  ) {
    final idx = destinations.indexWhere((d) => widget.location.startsWith(d.path));
    return idx >= 0 ? idx : 0;
  }

  void _showBypassRoleDialog(BuildContext context, AuthNotifier auth) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.bug_report_outlined, color: Colors.orange),
            SizedBox(width: 8),
            Text('Эксперимент п. 17 (DevTools)'),
          ],
        ),
        content: const Text(
          'Симуляция подмены роли в браузере (localStorage / DevTools):\n\n'
          'Интерфейс поверит, что у вас повышенные права, и отобразит запрещённые '
          'кнопки и разделы. Однако JWT-токен на сервере останется прежним, и при '
          'попытке выполнить операцию сервер ответит 403 Forbidden.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              auth.resetRoleBypass();
              Navigator.pop(ctx);
            },
            child: const Text('Сбросить к серверной роли'),
          ),
          FilledButton.tonal(
            onPressed: () {
              auth.simulateClientRoleBypass(Role.librarian);
              Navigator.pop(ctx);
            },
            child: const Text('Подменить на «Библиотекарь»'),
          ),
          FilledButton(
            onPressed: () {
              auth.simulateClientRoleBypass(Role.admin);
              Navigator.pop(ctx);
            },
            child: const Text('Подменить на «Администратор»'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = screenSizeOf(context);
    final auth = Provider.of<AuthNotifier?>(context);
    final destinations = _getDestinations(auth);
    final selectedIndex = _getSelectedIndex(destinations);
    final user = auth?.user;

    final Widget shell;
    if (size == ScreenSize.compact) {
      shell = Scaffold(
        appBar: AppBar(
          title: Text(user != null ? '${user.fullName} (${user.role.label})' : 'Библиотека'),
          actions: [
            if (user != null)
              IconButton(
                icon: const Icon(Icons.logout),
                tooltip: 'Выйти',
                onPressed: () {
                  auth?.logout();
                  context.go('/login');
                },
              ),
          ],
        ),
        body: SafeArea(child: widget.child),
        bottomNavigationBar: NavigationBarTheme(
          data: const NavigationBarThemeData(
            labelTextStyle: WidgetStatePropertyAll(TextStyle(fontSize: 10)),
          ),
          child: NavigationBar(
            selectedIndex: selectedIndex,
            onDestinationSelected: (i) => context.go(destinations[i].path),
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            destinations: [
              for (final d in destinations)
                NavigationDestination(icon: Icon(d.icon), label: d.label),
            ],
          ),
        ),
      );
    } else {
      final extended = MediaQuery.sizeOf(context).width >= 1500;
      shell = Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: selectedIndex,
            onDestinationSelected: (i) => context.go(destinations[i].path),
            extended: extended,
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
            trailing: user != null
                ? Expanded(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: PopupMenuButton<String>(
                          tooltip: 'Профиль: ${user.fullName} (${user.role.label})',
                          icon: CircleAvatar(
                            radius: 14,
                            child: Text(
                              user.username.isNotEmpty ? user.username[0].toUpperCase() : 'U',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                          onSelected: (val) {
                            if (val == 'logout') {
                              auth?.logout();
                              context.go('/login');
                            } else if (val == 'bypass') {
                              _showBypassRoleDialog(context, auth!);
                            }
                          },
                          itemBuilder: (_) => [
                            PopupMenuItem(
                              enabled: false,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(user.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  Text('${user.username} • ${user.role.label}', style: const TextStyle(fontSize: 12)),
                                ],
                              ),
                            ),
                            const PopupMenuDivider(),
                            const PopupMenuItem(
                              value: 'bypass',
                              child: Row(
                                children: [
                                  Icon(Icons.science_outlined, size: 18),
                                  SizedBox(width: 8),
                                  Text('Эксперимент п. 17 (DevTools)'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'logout',
                              child: Row(
                                children: [
                                  Icon(Icons.logout, size: 18, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text('Выйти из системы', style: TextStyle(color: Colors.red)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                : null,
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

  if (auth != null && auth.isAuthenticated) {
    return InactivityWatcher(
      timeout: auth.inactivityTimeout,
      warningDuration: const Duration(seconds: 30),
      onActivity: auth.recordActivity,
      onTimeout: () {
        auth.logout();
        context.go('/login');
      },
      child: shell,
    );
  }
  return shell;
  }
}
