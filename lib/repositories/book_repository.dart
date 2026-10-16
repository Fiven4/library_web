import '../models/book.dart';
import '../models/book_query.dart';
import 'entity_repository.dart';

abstract interface class BookRepository
    implements EntityRepository<Book, BookQuery> {
  Future<Book> create(Book book);
  Future<Book> update(Book book);
}
