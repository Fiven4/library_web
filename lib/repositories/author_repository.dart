import '../models/author.dart';
import '../models/author_query.dart';
import 'entity_repository.dart';

abstract interface class AuthorRepository
    implements EntityRepository<Author, AuthorQuery> {
  /// Все авторы, включая удалённых: нужны для подписей в списке книг.
  Future<List<Author>> findAll();

  Future<Author> create(Author author);
  Future<Author> update(Author author);
}
