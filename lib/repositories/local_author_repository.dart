import 'package:shared_preferences/shared_preferences.dart';

import '../data/seed_data.dart';
import '../models/author.dart';
import '../models/author_query.dart';
import '../storage/json_store.dart';
import '../storage/storage_notices.dart';
import 'book_repository.dart';
import 'entity_repository.dart';
import 'author_repository.dart';
import 'local_repository.dart';

class LocalAuthorRepository extends LocalRepository<Author, AuthorQuery>
    implements AuthorRepository {
  LocalAuthorRepository({
    SharedPreferences? prefs,
    super.dev,
    StorageNotices? notices,
    BookRepository? books,
  }) : _books = books,
       super(
         seed: seedAuthors,
         store: prefs == null
             ? null
             : JsonStore<Author>(
                 prefs: prefs,
                 collection: 'authors',
                 title: 'Авторы',
                 fromJson: Author.fromJson,
                 toJson: (e) => e.toJson(),
                 seed: seedAuthors,
                 notices: notices,
               ),
       );

  final BookRepository? _books;

  @override
  int idOf(Author item) => item.id;
  @override
  bool isDeletedItem(Author item) => item.isDeleted;
  @override
  Author withDeleted(Author item, DateTime? at) => at == null
      ? item.copyWith(clearDeletedAt: true)
      : item.copyWith(deletedAt: at);
  @override
  Author withId(Author item, int id) => Author(
    id: id,
    fullName: item.fullName,
    birthYear: item.birthYear,
    country: item.country,
    deletedAt: item.deletedAt,
  );
  @override
  String notFound(int id) => 'Автор $id не найден';

  @override
  bool matches(Author a, AuthorQuery q) {
    if (q.search.trim().isNotEmpty) {
      final needle = q.search.trim().toLowerCase();
      if (!a.fullName.toLowerCase().contains(needle) &&
          !a.country.toLowerCase().contains(needle)) {
        return false;
      }
    }
    return q.country == null || a.country == q.country;
  }

  @override
  int compare(Author a, Author b, AuthorQuery q) => switch (q.sortField) {
    'birthYear' => a.birthYear.compareTo(b.birthYear),
    'country' => a.country.toLowerCase().compareTo(b.country.toLowerCase()),
    _ => a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()),
  };

  @override
  Future<void> checkDeletable(Author item, {required bool hard}) async {
    final count =
        await _books?.countLinked(authorId: item.id, includeDeleted: hard) ?? 0;
    if (count > 0) {
      throw ConflictException(
        'Нельзя удалить автора «${item.fullName}»: на него ссылаются книги ($count)',
      );
    }
  }
}
