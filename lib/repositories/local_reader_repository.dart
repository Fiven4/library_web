import 'package:shared_preferences/shared_preferences.dart';

import '../core/validators.dart';
import '../data/seed_data.dart';
import '../models/library_card.dart';
import '../models/reader.dart';
import '../models/reader_query.dart';
import '../storage/json_store.dart';
import '../storage/storage_notices.dart';
import 'entity_repository.dart';
import 'local_repository.dart';
import 'reader_repository.dart';

class LocalReaderRepository extends LocalRepository<Reader, ReaderQuery>
    implements ReaderRepository {
  LocalReaderRepository({
    SharedPreferences? prefs,
    super.dev,
    StorageNotices? notices,
  }) : super(
         seed: seedReaders,
         store: prefs == null
             ? null
             : JsonStore<Reader>(
                 prefs: prefs,
                 collection: 'readers',
                 title: 'Читатели',
                 fromJson: Reader.fromJson,
                 toJson: (r) => r.toJson(),
                 seed: seedReaders,
                 notices: notices,
               ),
       );

  @override
  int idOf(Reader item) => item.id;
  @override
  bool isDeletedItem(Reader item) => item.isDeleted;
  @override
  Reader withDeleted(Reader item, DateTime? at) => at == null
      ? item.copyWith(clearDeletedAt: true)
      : item.copyWith(deletedAt: at);
  @override
  Reader withId(Reader item, int id) => Reader(
    id: id,
    fullName: item.fullName,
    email: item.email,
    phone: item.phone,
    card: LibraryCard(
      id: id,
      number: item.card.number,
      issuedAt: item.card.issuedAt,
      expiresAt: item.card.expiresAt,
    ),
    deletedAt: item.deletedAt,
  );
  @override
  String notFound(int id) => 'Читатель $id не найден';

  @override
  bool matches(Reader r, ReaderQuery q) {
    if (q.search.trim().isNotEmpty) {
      final needle = q.search.trim().toLowerCase();
      if (!r.fullName.toLowerCase().contains(needle) &&
          !r.email.toLowerCase().contains(needle) &&
          !r.phone.toLowerCase().contains(needle) &&
          !r.card.number.toLowerCase().contains(needle)) {
        return false;
      }
    }
    return switch (q.cardStatus) {
      CardStatus.active => !r.card.isExpired(),
      CardStatus.expired => r.card.isExpired(),
      null => true,
    };
  }

  @override
  int compare(Reader a, Reader b, ReaderQuery q) => switch (q.sortField) {
    'email' => a.email.toLowerCase().compareTo(b.email.toLowerCase()),
    'expiresAt' => a.card.expiresAt.compareTo(b.card.expiresAt),
    _ => a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()),
  };

  @override
  void validate(Reader candidate, List<Reader> others) {
    final errors = <String, String>{};
    final email = normalizeEmail(candidate.email);
    if (others.any((r) => normalizeEmail(r.email) == email)) {
      errors['email'] = 'Читатель с такой почтой уже зарегистрирован';
    }
    final number = candidate.card.number.trim().toLowerCase();
    if (others.any((r) => r.card.number.trim().toLowerCase() == number)) {
      errors['card.number'] = 'Билет с таким номером уже выдан';
    }
    if (errors.isNotEmpty) throw ValidationException(errors);
  }
}
