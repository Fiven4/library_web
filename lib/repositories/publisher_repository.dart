import '../models/publisher.dart';
import '../models/publisher_query.dart';
import 'entity_repository.dart';

abstract interface class PublisherRepository
    implements EntityRepository<Publisher, PublisherQuery> {}
