import 'package:shared_preferences/shared_preferences.dart';

import '../data/seed_data.dart';
import '../models/genre.dart';
import '../models/genre_query.dart';
import '../storage/json_store.dart';
import '../storage/storage_notices.dart';
import 'book_repository.dart';
import 'entity_repository.dart';
import 'genre_repository.dart';
import 'local_repository.dart';

class LocalGenreRepository extends LocalRepository<Genre, GenreQuery>
    implements GenreRepository {
  LocalGenreRepository({
    SharedPreferences? prefs,
    super.dev,
    StorageNotices? notices,
    BookRepository? books,
  }) : _books = books,
       super(
         seed: seedGenres,
         store: prefs == null
             ? null
             : JsonStore<Genre>(
                 prefs: prefs,
                 collection: 'genres',
                 title: 'Жанры',
                 fromJson: Genre.fromJson,
                 toJson: (e) => e.toJson(),
                 seed: seedGenres,
                 notices: notices,
               ),
       );

  final BookRepository? _books;

  @override
  int idOf(Genre item) => item.id;
  @override
  bool isDeletedItem(Genre item) => item.isDeleted;
  @override
  Genre withDeleted(Genre item, DateTime? at) => at == null
      ? item.copyWith(clearDeletedAt: true)
      : item.copyWith(deletedAt: at);
  @override
  Genre withId(Genre item, int id) => Genre(
    id: id,
    name: item.name,
    description: item.description,
    deletedAt: item.deletedAt,
  );
  @override
  String notFound(int id) => 'Жанр $id не найден';

  @override
  bool matches(Genre g, GenreQuery q) {
    if (q.search.trim().isEmpty) return true;
    final needle = q.search.trim().toLowerCase();
    return g.name.toLowerCase().contains(needle) ||
        g.description.toLowerCase().contains(needle);
  }

  @override
  int compare(Genre a, Genre b, GenreQuery q) => switch (q.sortField) {
    'description' => a.description.toLowerCase().compareTo(
      b.description.toLowerCase(),
    ),
    'id' => a.id.compareTo(b.id),
    _ => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
  };

  @override
  void validate(Genre candidate, List<Genre> others) {
    final name = candidate.name.trim().toLowerCase();
    if (others.any((g) => g.name.trim().toLowerCase() == name)) {
      throw ValidationException({
        'name': 'Жанр с таким названием уже существует',
      });
    }
  }

  @override
  Future<void> checkDeletable(Genre item, {required bool hard}) async {
    final count =
        await _books?.countLinked(genreId: item.id, includeDeleted: hard) ?? 0;
    if (count > 0) {
      throw ConflictException(
        'Нельзя удалить жанр «${item.name}»: на него ссылаются книги ($count)',
      );
    }
  }
}
