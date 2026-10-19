import '../models/genre.dart';
import '../models/genre_query.dart';
import 'entity_repository.dart';

abstract interface class GenreRepository
    implements EntityRepository<Genre, GenreQuery> {}
