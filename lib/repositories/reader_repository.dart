import '../models/reader.dart';
import '../models/reader_query.dart';
import 'entity_repository.dart';

abstract interface class ReaderRepository
    implements EntityRepository<Reader, ReaderQuery> {}
