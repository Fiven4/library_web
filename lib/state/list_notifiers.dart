import '../models/author.dart';
import '../models/author_query.dart';
import '../models/book.dart';
import '../models/book_query.dart';
import '../repositories/author_repository.dart';
import '../repositories/book_repository.dart';
import 'entity_list_notifier.dart';

class BooksNotifier extends EntityListNotifier<Book, BookQuery> {
  BooksNotifier(BookRepository repository)
    : super(repository, const BookQuery(), (b) => b.id);
}

class AuthorsNotifier extends EntityListNotifier<Author, AuthorQuery> {
  AuthorsNotifier(AuthorRepository repository)
    : super(repository, const AuthorQuery(), (a) => a.id);
}
