import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/api_client.dart';
import 'core/dev_settings.dart';
import 'repositories/api_author_repository.dart';
import 'repositories/api_book_repository.dart';
import 'repositories/api_genre_repository.dart';
import 'repositories/api_publisher_repository.dart';
import 'repositories/api_reader_repository.dart';
import 'repositories/author_repository.dart';
import 'repositories/book_repository.dart';
import 'repositories/genre_repository.dart';
import 'repositories/local_author_repository.dart';
import 'repositories/local_book_repository.dart';
import 'repositories/local_genre_repository.dart';
import 'repositories/local_publisher_repository.dart';
import 'repositories/local_reader_repository.dart';
import 'repositories/publisher_repository.dart';
import 'repositories/reader_repository.dart';
import 'state/auth_notifier.dart';
import 'state/list_notifiers.dart';
import 'state/reference_notifier.dart';
import 'storage/storage_notices.dart';
import 'widgets/inactivity_watcher.dart';

class AppProviders extends StatelessWidget {
  final Widget child;
  final SharedPreferences? prefs;
  final Dio? dio;
  final bool useApi;
  final AuthNotifier? authNotifier;

  const AppProviders({
    super.key,
    required this.child,
    this.prefs,
    this.dio,
    this.useApi = false,
    this.authNotifier,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveDio = dio ??
        buildDio(
          tokenProvider: () => authNotifier?.accessToken,
          onRefreshToken: () =>
              authNotifier?.refreshTokens() ?? Future.value(false),
        );

    return MultiProvider(
      providers: [
        if (authNotifier != null)
          ChangeNotifierProvider.value(value: authNotifier),
        ChangeNotifierProvider(create: (_) => DevSettings()),
        Provider(create: (_) => StorageNotices()),
        if (useApi) ...[
          Provider<Dio>.value(value: effectiveDio),
          ProxyProvider<Dio, BookRepository>(
            update: (_, dioInstance, _) => ApiBookRepository(dioInstance),
          ),
          ProxyProvider<Dio, AuthorRepository>(
            update: (_, dioInstance, _) => ApiAuthorRepository(dioInstance),
          ),
          ProxyProvider<Dio, GenreRepository>(
            update: (_, dioInstance, _) => ApiGenreRepository(dioInstance),
          ),
          ProxyProvider<Dio, PublisherRepository>(
            update: (_, dioInstance, _) => ApiPublisherRepository(dioInstance),
          ),
          ProxyProvider<Dio, ReaderRepository>(
            update: (_, dioInstance, _) => ApiReaderRepository(dioInstance),
          ),
        ] else ...[
          Provider<BookRepository>(
            create: (context) => LocalBookRepository(
              prefs: prefs,
              dev: context.read<DevSettings>(),
              notices: context.read<StorageNotices>(),
            ),
          ),
          Provider<AuthorRepository>(
            create: (context) => LocalAuthorRepository(
              prefs: prefs,
              dev: context.read<DevSettings>(),
              notices: context.read<StorageNotices>(),
              books: context.read<BookRepository>(),
            ),
          ),
          Provider<GenreRepository>(
            create: (context) => LocalGenreRepository(
              prefs: prefs,
              dev: context.read<DevSettings>(),
              notices: context.read<StorageNotices>(),
              books: context.read<BookRepository>(),
            ),
          ),
          Provider<PublisherRepository>(
            create: (context) => LocalPublisherRepository(
              prefs: prefs,
              dev: context.read<DevSettings>(),
              notices: context.read<StorageNotices>(),
              books: context.read<BookRepository>(),
            ),
          ),
          Provider<ReaderRepository>(
            create: (context) => LocalReaderRepository(
              prefs: prefs,
              dev: context.read<DevSettings>(),
              notices: context.read<StorageNotices>(),
            ),
          ),
        ],
        ChangeNotifierProvider(
          create: (context) => BooksNotifier(context.read<BookRepository>()),
        ),
        ChangeNotifierProvider(
          create: (context) =>
              AuthorsNotifier(context.read<AuthorRepository>()),
        ),
        ChangeNotifierProvider(
          create: (context) => GenresNotifier(context.read<GenreRepository>()),
        ),
        ChangeNotifierProvider(
          create: (context) =>
              PublishersNotifier(context.read<PublisherRepository>()),
        ),
        ChangeNotifierProvider(
          create: (context) =>
              ReadersNotifier(context.read<ReaderRepository>()),
        ),
        ChangeNotifierProvider(
          create: (context) => ReferenceNotifier(
            genres: context.read<GenreRepository>(),
            publishers: context.read<PublisherRepository>(),
            authors: context.read<AuthorRepository>(),
            books: context.read<BookRepository>(),
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
    final auth = Provider.of<AuthNotifier?>(context);

    Widget app = MaterialApp.router(
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

    if (auth != null && auth.isAuthenticated) {
      app = InactivityWatcher(
        timeout: auth.inactivityTimeout,
        warningDuration: const Duration(seconds: 30),
        onActivity: auth.recordActivity,
        onTimeout: () {
          auth.logout();
          router.go('/login');
        },
        child: app,
      );
    }

    return app;
  }
}
