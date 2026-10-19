import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/format.dart';
import '../models/author.dart';
import '../models/book.dart';
import '../models/genre.dart';
import '../models/publisher.dart';
import '../models/reader.dart';
import '../state/entity_detail_notifier.dart';
import '../state/reference_notifier.dart';
import '../widgets/detail_view.dart';

/// Карточка книги.
class BookDetailScreen extends StatelessWidget {
  final int? id;

  const BookDetailScreen({super.key, this.id});

  @override
  Widget build(BuildContext context) {
    final ref = context.watch<ReferenceNotifier>();
    return DetailView<Book>(
      notifier: context.watch<BookDetailNotifier>(),
      listPath: '/books',
      editPath: '/books/$id/edit',
      titleOf: (b) => b.title,
      isDeleted: (b) => b.isDeleted,
      fields: (b) => [
        ('ISBN', Text(b.isbn)),
        ('Авторы', Text(ref.authorNames(b.authorIds))),
        ('Жанры', Text(ref.genreNames(b.genreIds))),
        ('Издательство', Text(ref.publisherName(b.publisherId))),
        ('Год издания', Text('${b.year}')),
        ('Страниц', Text('${b.pages}')),
        (
          'Экземпляры',
          Text('доступно ${b.copiesAvailable} из ${b.copiesTotal}'),
        ),
      ],
    );
  }
}

/// Список книг, которые ссылаются на запись (автора, жанр, издательство).
Widget _relatedBooks(BuildContext context, List<Book> books) => Card(
  margin: EdgeInsets.zero,
  child: Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Книги', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        if (books.isEmpty)
          const Text('В каталоге нет связанных книг.')
        else
          for (final b in books)
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: Text(b.title),
              subtitle: Text('${b.year}'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/books/${b.id}'),
            ),
      ],
    ),
  ),
);

/// Карточка автора со списком его книг.
class AuthorDetailScreen extends StatelessWidget {
  final int? id;

  const AuthorDetailScreen({super.key, this.id});

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<RelatedBooksNotifier<Author>>();
    return DetailView<Author>(
      notifier: notifier,
      listPath: '/authors',
      editPath: '/authors/$id/edit',
      titleOf: (a) => a.fullName,
      isDeleted: (a) => a.isDeleted,
      fields: (a) => [
        ('Страна', Text(a.country)),
        ('Год рождения', Text('${a.birthYear}')),
      ],
      extra: (_) => _relatedBooks(context, notifier.books),
    );
  }
}

class GenreDetailScreen extends StatelessWidget {
  final int? id;

  const GenreDetailScreen({super.key, this.id});

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<RelatedBooksNotifier<Genre>>();
    return DetailView<Genre>(
      notifier: notifier,
      listPath: '/genres',
      editPath: '/genres/$id/edit',
      titleOf: (g) => g.name,
      isDeleted: (g) => g.isDeleted,
      fields: (g) => [
        ('Описание', Text(g.description.isEmpty ? '—' : g.description)),
      ],
      extra: (_) => _relatedBooks(context, notifier.books),
    );
  }
}

class PublisherDetailScreen extends StatelessWidget {
  final int? id;

  const PublisherDetailScreen({super.key, this.id});

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<RelatedBooksNotifier<Publisher>>();
    return DetailView<Publisher>(
      notifier: notifier,
      listPath: '/publishers',
      editPath: '/publishers/$id/edit',
      titleOf: (p) => p.name,
      isDeleted: (p) => p.isDeleted,
      fields: (p) => [
        ('Город', Text(p.city)),
        ('Основано', Text('${p.foundedYear}')),
      ],
      extra: (_) => _relatedBooks(context, notifier.books),
    );
  }
}

/// Карточка читателя с читательским билетом (связь «один к одному»).
class ReaderDetailScreen extends StatelessWidget {
  final int? id;

  const ReaderDetailScreen({super.key, this.id});

  @override
  Widget build(BuildContext context) {
    return DetailView<Reader>(
      notifier: context.watch<EntityDetailNotifier<Reader>>(),
      listPath: '/readers',
      editPath: '/readers/$id/edit',
      titleOf: (r) => r.fullName,
      isDeleted: (r) => r.isDeleted,
      fields: (r) => [
        ('Почта', Text(r.email)),
        ('Телефон', Text(r.phone.isEmpty ? '—' : r.phone)),
        ('Билет', Text(r.card.number)),
        ('Выдан', Text(formatDate(r.card.issuedAt))),
        (
          'Действует до',
          Text(
            formatDate(r.card.expiresAt) +
                (r.card.isExpired() ? ' (истёк)' : ''),
          ),
        ),
      ],
    );
  }
}
