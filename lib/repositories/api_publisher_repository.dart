import 'package:dio/dio.dart';

import '../models/publisher.dart';
import '../models/publisher_query.dart';
import 'api_repository.dart';
import 'publisher_repository.dart';

class ApiPublisherRepository extends ApiRepository<Publisher, PublisherQuery>
    implements PublisherRepository {
  ApiPublisherRepository(Dio dio)
    : super(
        dio: dio,
        path: '/publishers',
        fromJson: Publisher.fromJson,
        toJson: (p) => {
          'name': p.name,
          'city': p.city,
          'foundedYear': p.foundedYear,
        },
        idOf: (p) => p.id,
      );
}
