import 'package:shared_preferences/shared_preferences.dart';

import '../core/validators.dart';
import '../data/seed_data.dart';
import '../models/book.dart';
import '../models/book_query.dart';
import '../storage/json_store.dart';
import '../storage/storage_notices.dart';
import 'book_repository.dart';
import 'entity_repository.dart';
import 'local_repository.dart';

class LocalBookRepository extends LocalRepository<Book, BookQuery>
    implements BookRepository {
  LocalBookRepository({
    SharedPreferences? prefs,
    super.dev,
    StorageNotices? notices,
  }) : super(
         seed: seedBooks,
         store: prefs == null
             ? null
             : JsonStore<Book>(
                 prefs: prefs,
                 collection: 'books',
                 title: 'Книги',
                 fromJson: Book.fromJson,
                 toJson: (b) => b.toJson(),
                 seed: seedBooks,
                 notices: notices,
               ),
       );

  @override
  int idOf(Book item) => item.id;
  @override
  bool isDeletedItem(Book item) => item.isDeleted;
  @override
  Book withDeleted(Book item, DateTime? at) => at == null
      ? item.copyWith(clearDeletedAt: true)
      : item.copyWith(deletedAt: at);
  @override
  Book withId(Book item, int id) => Book(
    id: id,
    title: item.title,
    isbn: item.isbn,
    year: item.year,
    pages: item.pages,
    publisherId: item.publisherId,
    authorIds: item.authorIds,
    genreIds: item.genreIds,
    copiesTotal: item.copiesTotal,
    copiesAvailable: item.copiesTotal,
    deletedAt: item.deletedAt,
  );
  @override
  String notFound(int id) => 'Книга $id не найдена';

  @override
  bool matches(Book b, BookQuery q) {
    if (q.search.trim().isNotEmpty) {
      final needle = q.search.trim().toLowerCase();
      if (!b.title.toLowerCase().contains(needle) &&
          !b.isbn.toLowerCase().contains(needle)) {
        return false;
      }
    }
    if (q.genreId != null && !b.genreIds.contains(q.genreId)) return false;
    if (q.publisherId != null && b.publisherId != q.publisherId) return false;
    if (q.authorId != null && !b.authorIds.contains(q.authorId)) return false;
    if (q.yearFrom != null && b.year < q.yearFrom!) return false;
    if (q.yearTo != null && b.year > q.yearTo!) return false;
    return true;
  }

  @override
  int compare(Book a, Book b, BookQuery q) => switch (q.sortField) {
    'year' => a.year.compareTo(b.year),
    'pages' => a.pages.compareTo(b.pages),
    _ => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
  };

  @override
  void validate(Book candidate, List<Book> others) {
    final isbn = normalizeIsbn(candidate.isbn);
    if (others.any((b) => normalizeIsbn(b.isbn) == isbn)) {
      throw ValidationException({'isbn': 'Книга с таким ISBN уже существует'});
    }
  }

  @override
  Future<int> countLinked({
    int? authorId,
    int? genreId,
    int? publisherId,
    bool includeDeleted = false,
  }) async {
    final all = await findAll();
    return all.where((b) {
      if (!includeDeleted && b.isDeleted) return false;
      if (authorId != null && b.authorIds.contains(authorId)) return true;
      if (genreId != null && b.genreIds.contains(genreId)) return true;
      if (publisherId != null && b.publisherId == publisherId) return true;
      return false;
    }).length;
  }
}
