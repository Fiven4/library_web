import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/author.dart';
import '../models/author_query.dart';
import '../models/book_query.dart';
import '../models/genre.dart';
import '../models/genre_query.dart';
import '../models/publisher.dart';
import '../models/publisher_query.dart';
import '../models/reader.dart';
import '../models/reader_query.dart';
import '../models/role.dart';
import '../repositories/author_repository.dart';
import '../repositories/book_repository.dart';
import '../repositories/genre_repository.dart';
import '../repositories/publisher_repository.dart';
import '../repositories/reader_repository.dart';
import '../screens/app_shell.dart';
import '../screens/authors_screen.dart';
import '../screens/books_screen.dart';
import '../screens/detail_screens.dart';
import '../screens/forbidden_screen.dart';
import '../screens/form_screens.dart';
import '../screens/genres_screen.dart';
import '../screens/login_screen.dart';
import '../screens/not_found_screen.dart';
import '../screens/publishers_screen.dart';
import '../screens/readers_screen.dart';
import '../screens/register_screen.dart';
import '../screens/users_screen.dart';
import '../state/auth_notifier.dart';
import '../state/entity_detail_notifier.dart';

int? _id(GoRouterState state) => int.tryParse(state.pathParameters['id'] ?? '');

List<GoRoute> _entityRoutes({
  required String path,
  required Widget Function(GoRouterState state) list,
  required Widget Function(int? id) form,
  required Widget Function(BuildContext context, int? id) detail,
  AuthNotifier? auth,
}) => [
  GoRoute(path: '/$path', builder: (context, state) => list(state)),
  GoRoute(
    path: '/$path/new',
    builder: (context, state) => form(null),
    redirect: (context, state) =>
        (auth?.has(Role.librarian) ?? true) ? null : '/forbidden',
  ),
  GoRoute(
    path: '/$path/:id',
    builder: (context, state) => detail(context, _id(state)),
  ),
  GoRoute(
    path: '/$path/:id/edit',
    builder: (context, state) => form(_id(state)),
    redirect: (context, state) =>
        (auth?.has(Role.librarian) ?? true) ? null : '/forbidden',
  ),
];

GoRouter createRouter({String initialLocation = '/books', AuthNotifier? auth}) {
  return GoRouter(
    initialLocation: initialLocation,
    refreshListenable: auth,
    redirect: (context, state) {
      if (auth == null) return null;
      final loggedIn = auth.isAuthenticated;
      final target = state.matchedLocation;
      final isPublic = target == '/login' || target == '/register';

      // Не вошёл и идёт на закрытый экран — на вход, запомнив from
      if (!loggedIn && !isPublic) {
        final from = Uri.encodeComponent(state.uri.toString());
        return '/login?from=$from';
      }

      // Уже вошёл и идёт на экран входа/регистрации — на главную
      if (loggedIn && isPublic) {
        return '/books';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (c, s) => LoginScreen(from: s.uri.queryParameters['from']),
      ),
      GoRoute(path: '/register', builder: (c, s) => const RegisterScreen()),
      GoRoute(path: '/forbidden', builder: (c, s) => const ForbiddenScreen()),
      GoRoute(path: '/', redirect: (_, _) => '/books'),
      ShellRoute(
        builder: (context, state, child) =>
            AppShell(location: state.uri.path, child: child),
        routes: [
          ..._entityRoutes(
            path: 'books',
            auth: auth,
            list: (s) =>
                BooksScreen(query: BookQuery.fromParams(s.uri.queryParameters)),
            form: (id) => BookFormScreen(id: id),
            detail: (context, id) => ChangeNotifierProvider(
              key: ValueKey('book-$id'),
              create: (context) =>
                  BookDetailNotifier(context.read<BookRepository>(), id)
                    ..load(),
              child: BookDetailScreen(id: id),
            ),
          ),
          ..._entityRoutes(
            path: 'authors',
            auth: auth,
            list: (s) => AuthorsScreen(
              query: AuthorQuery.fromParams(s.uri.queryParameters),
            ),
            form: (id) => AuthorFormScreen(id: id),
            detail: (context, id) => ChangeNotifierProvider(
              key: ValueKey('author-$id'),
              create: (context) => RelatedBooksNotifier<Author>(
                context.read<AuthorRepository>(),
                id,
                context.read<BookRepository>(),
                (id) => BookQuery(authorId: id, size: 50),
              )..load(),
              child: AuthorDetailScreen(id: id),
            ),
          ),
          ..._entityRoutes(
            path: 'genres',
            auth: auth,
            list: (s) => GenresScreen(
              query: GenreQuery.fromParams(s.uri.queryParameters),
            ),
            form: (id) => GenreFormScreen(id: id),
            detail: (context, id) => ChangeNotifierProvider(
              key: ValueKey('genre-$id'),
              create: (context) => RelatedBooksNotifier<Genre>(
                context.read<GenreRepository>(),
                id,
                context.read<BookRepository>(),
                (id) => BookQuery(genreId: id, size: 50),
              )..load(),
              child: GenreDetailScreen(id: id),
            ),
          ),
          ..._entityRoutes(
            path: 'publishers',
            auth: auth,
            list: (s) => PublishersScreen(
              query: PublisherQuery.fromParams(s.uri.queryParameters),
            ),
            form: (id) => PublisherFormScreen(id: id),
            detail: (context, id) => ChangeNotifierProvider(
              key: ValueKey('publisher-$id'),
              create: (context) => RelatedBooksNotifier<Publisher>(
                context.read<PublisherRepository>(),
                id,
                context.read<BookRepository>(),
                (id) => BookQuery(publisherId: id, size: 50),
              )..load(),
              child: PublisherDetailScreen(id: id),
            ),
          ),
          ..._entityRoutes(
            path: 'readers',
            auth: auth,
            list: (s) => ReadersScreen(
              query: ReaderQuery.fromParams(s.uri.queryParameters),
            ),
            form: (id) => ReaderFormScreen(id: id),
            detail: (context, id) => ChangeNotifierProvider(
              key: ValueKey('reader-$id'),
              create: (context) => EntityDetailNotifier<Reader>(
                context.read<ReaderRepository>(),
                id,
              )..load(),
              child: ReaderDetailScreen(id: id),
            ),
          ),
          GoRoute(
            path: '/admin/users',
            builder: (c, s) => const UsersScreen(),
            redirect: (context, state) =>
                (auth?.has(Role.admin) ?? true) ? null : '/forbidden',
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) =>
        NotFoundScreen(location: state.uri.toString()),
  );
}
