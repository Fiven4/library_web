import '../models/book.dart';
import '../models/book_query.dart';
import 'entity_repository.dart';

abstract interface class BookRepository
    implements EntityRepository<Book, BookQuery> {
  /// Число книг, ссылающихся на автора, жанр или издательство.
  /// Нужно, чтобы запретить удаление записи, на которую есть ссылки.
  Future<int> countLinked({
    int? authorId,
    int? genreId,
    int? publisherId,
    bool includeDeleted = false,
  });
}
