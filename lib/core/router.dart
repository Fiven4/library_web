import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/author_query.dart';
import '../models/book_query.dart';
import '../repositories/author_repository.dart';
import '../repositories/book_repository.dart';
import '../screens/app_shell.dart';
import '../screens/authors_screen.dart';
import '../screens/books_screen.dart';
import '../screens/detail_screens.dart';
import '../screens/not_found_screen.dart';
import '../state/entity_detail_notifier.dart';

/// Маршруты приложения. Условия отбора списков передаются параметрами адреса:
/// /books?search=война&genreId=2&sort=year,desc&page=3
GoRouter createRouter({String initialLocation = '/books'}) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(path: '/', redirect: (_, _) => '/books'),
      ShellRoute(
        builder: (context, state, child) =>
            AppShell(location: state.uri.path, child: child),
        routes: [
          GoRoute(
            path: '/books',
            builder: (context, state) => BooksScreen(
              query: BookQuery.fromParams(state.uri.queryParameters),
            ),
          ),
          GoRoute(
            path: '/books/:id',
            builder: (context, state) {
              final id = int.tryParse(state.pathParameters['id'] ?? '');
              return ChangeNotifierProvider(
                // Ключ пересоздаёт состояние при переходе к другой записи.
                key: ValueKey('book-$id'),
                create: (context) =>
                    BookDetailNotifier(context.read<BookRepository>(), id)
                      ..load(),
                child: const BookDetailScreen(),
              );
            },
          ),
          GoRoute(
            path: '/authors',
            builder: (context, state) => AuthorsScreen(
              query: AuthorQuery.fromParams(state.uri.queryParameters),
            ),
          ),
          GoRoute(
            path: '/authors/:id',
            builder: (context, state) {
              final id = int.tryParse(state.pathParameters['id'] ?? '');
              return ChangeNotifierProvider(
                key: ValueKey('author-$id'),
                create: (context) => AuthorDetailNotifier(
                  context.read<AuthorRepository>(),
                  id,
                  context.read<BookRepository>(),
                )..load(),
                child: const AuthorDetailScreen(),
              );
            },
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) =>
        NotFoundScreen(location: state.uri.toString()),
  );
}
