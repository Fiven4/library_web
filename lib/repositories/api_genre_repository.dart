import 'package:dio/dio.dart';

import '../models/genre.dart';
import '../models/genre_query.dart';
import 'api_repository.dart';
import 'genre_repository.dart';

class ApiGenreRepository extends ApiRepository<Genre, GenreQuery>
    implements GenreRepository {
  ApiGenreRepository(Dio dio)
      : super(
          dio: dio,
          path: '/genres',
          fromJson: Genre.fromJson,
          toJson: (g) => {
            'name': g.name,
            'description': g.description,
          },
          idOf: (g) => g.id,
        );
}
