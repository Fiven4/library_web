import 'package:dio/dio.dart';

import '../models/author.dart';
import '../models/author_query.dart';
import 'api_repository.dart';
import 'author_repository.dart';

class ApiAuthorRepository extends ApiRepository<Author, AuthorQuery>
    implements AuthorRepository {
  ApiAuthorRepository(Dio dio)
    : super(
        dio: dio,
        path: '/authors',
        fromJson: Author.fromJson,
        toJson: (a) => {
          'fullName': a.fullName,
          'birthYear': a.birthYear,
          'country': a.country,
        },
        idOf: (a) => a.id,
      );
}
