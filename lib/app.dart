import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'core/dev_settings.dart';
import 'repositories/author_repository.dart';
import 'repositories/book_repository.dart';
import 'repositories/in_memory_author_repository.dart';
import 'repositories/in_memory_book_repository.dart';
import 'repositories/reference_repository.dart';
import 'state/list_notifiers.dart';
import 'state/reference_notifier.dart';

/// Провайдеры размещены выше MaterialApp: состояние нужно на всех экранах.
/// Подмена InMemory-репозиториев на API-реализации (ПР4) делается здесь
/// и не затрагивает ни один экран.
class AppProviders extends StatelessWidget {
  final Widget child;

  const AppProviders({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => DevSettings()),
        Provider<BookRepository>(
          create: (context) =>
              InMemoryBookRepository(context.read<DevSettings>()),
        ),
        Provider<AuthorRepository>(
          create: (context) =>
              InMemoryAuthorRepository(context.read<DevSettings>()),
        ),
        Provider<ReferenceRepository>(
          create: (_) => InMemoryReferenceRepository(),
        ),
        ChangeNotifierProvider(
          create: (context) => BooksNotifier(context.read<BookRepository>()),
        ),
        ChangeNotifierProvider(
          create: (context) =>
              AuthorsNotifier(context.read<AuthorRepository>()),
        ),
        ChangeNotifierProvider(
          create: (context) => ReferenceNotifier(
            context.read<ReferenceRepository>(),
            context.read<AuthorRepository>(),
          )..load(),
        ),
      ],
      child: child,
    );
  }
}

class LibraryApp extends StatelessWidget {
  final GoRouter router;

  const LibraryApp({super.key, required this.router});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Библиотека',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      routerConfig: router,
    );
  }
}
