import '../models/author.dart';
import '../models/author_query.dart';
import '../models/book.dart';
import '../models/book_query.dart';
import '../models/genre.dart';
import '../models/genre_query.dart';
import '../models/publisher.dart';
import '../models/publisher_query.dart';
import '../models/reader.dart';
import '../models/reader_query.dart';
import '../repositories/author_repository.dart';
import '../repositories/book_repository.dart';
import '../repositories/genre_repository.dart';
import '../repositories/publisher_repository.dart';
import '../repositories/reader_repository.dart';
import 'entity_list_notifier.dart';

class BooksNotifier extends EntityListNotifier<Book, BookQuery> {
  BooksNotifier(BookRepository repository)
    : super(repository, const BookQuery(), (b) => b.id);
}

class AuthorsNotifier extends EntityListNotifier<Author, AuthorQuery> {
  AuthorsNotifier(AuthorRepository repository)
    : super(repository, const AuthorQuery(), (a) => a.id);
}

class GenresNotifier extends EntityListNotifier<Genre, GenreQuery> {
  GenresNotifier(GenreRepository repository)
    : super(repository, const GenreQuery(), (g) => g.id);
}

class PublishersNotifier extends EntityListNotifier<Publisher, PublisherQuery> {
  PublishersNotifier(PublisherRepository repository)
    : super(repository, const PublisherQuery(), (p) => p.id);
}

class ReadersNotifier extends EntityListNotifier<Reader, ReaderQuery> {
  ReadersNotifier(ReaderRepository repository)
    : super(repository, const ReaderQuery(), (r) => r.id);
}
