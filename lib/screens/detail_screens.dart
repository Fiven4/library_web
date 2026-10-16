import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/author.dart';
import '../models/book.dart';
import '../state/entity_detail_notifier.dart';
import '../state/reference_notifier.dart';
import '../widgets/detail_view.dart';

/// Карточка книги.
class BookDetailScreen extends StatelessWidget {
  const BookDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ref = context.watch<ReferenceNotifier>();
    return DetailView<Book>(
      notifier: context.watch<BookDetailNotifier>(),
      listPath: '/books',
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

/// Карточка автора со списком его книг.
class AuthorDetailScreen extends StatelessWidget {
  const AuthorDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<AuthorDetailNotifier>();
    return DetailView<Author>(
      notifier: notifier,
      listPath: '/authors',
      titleOf: (a) => a.fullName,
      isDeleted: (a) => a.isDeleted,
      fields: (a) => [
        ('Страна', Text(a.country)),
        ('Год рождения', Text('${a.birthYear}')),
      ],
      extra: (a) => Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Книги автора',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              if (notifier.books.isEmpty)
                const Text('В каталоге нет книг этого автора.')
              else
                for (final b in notifier.books)
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
      ),
    );
  }
}
