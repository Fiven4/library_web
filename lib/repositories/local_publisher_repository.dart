import 'package:shared_preferences/shared_preferences.dart';

import '../data/seed_data.dart';
import '../models/publisher.dart';
import '../models/publisher_query.dart';
import '../storage/json_store.dart';
import '../storage/storage_notices.dart';
import 'book_repository.dart';
import 'entity_repository.dart';
import 'publisher_repository.dart';
import 'local_repository.dart';

class LocalPublisherRepository
    extends LocalRepository<Publisher, PublisherQuery>
    implements PublisherRepository {
  LocalPublisherRepository({
    SharedPreferences? prefs,
    super.dev,
    StorageNotices? notices,
    BookRepository? books,
  }) : _books = books,
       super(
         seed: seedPublishers,
         store: prefs == null
             ? null
             : JsonStore<Publisher>(
                 prefs: prefs,
                 collection: 'publishers',
                 title: 'Издательства',
                 fromJson: Publisher.fromJson,
                 toJson: (e) => e.toJson(),
                 seed: seedPublishers,
                 notices: notices,
               ),
       );

  final BookRepository? _books;

  @override
  int idOf(Publisher item) => item.id;
  @override
  bool isDeletedItem(Publisher item) => item.isDeleted;
  @override
  Publisher withDeleted(Publisher item, DateTime? at) => at == null
      ? item.copyWith(clearDeletedAt: true)
      : item.copyWith(deletedAt: at);
  @override
  Publisher withId(Publisher item, int id) => Publisher(
    id: id,
    name: item.name,
    city: item.city,
    foundedYear: item.foundedYear,
    deletedAt: item.deletedAt,
  );
  @override
  String notFound(int id) => 'Издательство $id не найдено';

  @override
  bool matches(Publisher p, PublisherQuery q) {
    if (q.search.trim().isNotEmpty) {
      final needle = q.search.trim().toLowerCase();
      if (!p.name.toLowerCase().contains(needle) &&
          !p.city.toLowerCase().contains(needle)) {
        return false;
      }
    }
    return q.city == null || p.city == q.city;
  }

  @override
  int compare(Publisher a, Publisher b, PublisherQuery q) =>
      switch (q.sortField) {
        'city' => a.city.toLowerCase().compareTo(b.city.toLowerCase()),
        'foundedYear' => a.foundedYear.compareTo(b.foundedYear),
        _ => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      };

  @override
  void validate(Publisher candidate, List<Publisher> others) {
    final name = candidate.name.trim().toLowerCase();
    if (others.any((p) => p.name.trim().toLowerCase() == name)) {
      throw ValidationException({
        'name': 'Издательство с таким названием уже существует',
      });
    }
  }

  /// Издательство, на которое ссылаются книги, удалить нельзя: сообщение
  /// содержит число связанных записей.
  @override
  Future<void> checkDeletable(Publisher item, {required bool hard}) async {
    final count =
        await _books?.countLinked(publisherId: item.id, includeDeleted: hard) ??
        0;
    if (count > 0) {
      throw ConflictException(
        'Нельзя удалить издательство «${item.name}»: на него ссылаются книги ($count)',
      );
    }
  }
}
