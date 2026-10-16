import '../data/seed_data.dart';
import '../models/reference.dart';

/// Справочники жанров и издательств (только чтение).
abstract interface class ReferenceRepository {
  Future<List<Genre>> genres();
  Future<List<Publisher>> publishers();
}

class InMemoryReferenceRepository implements ReferenceRepository {
  @override
  Future<List<Genre>> genres() async => List.unmodifiable(seedGenres);

  @override
  Future<List<Publisher>> publishers() async =>
      List.unmodifiable(seedPublishers);
}
