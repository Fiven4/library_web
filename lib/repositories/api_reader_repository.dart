import 'package:dio/dio.dart';

import '../models/reader.dart';
import '../models/reader_query.dart';
import 'api_repository.dart';
import 'reader_repository.dart';

class ApiReaderRepository extends ApiRepository<Reader, ReaderQuery>
    implements ReaderRepository {
  ApiReaderRepository(Dio dio)
    : super(
        dio: dio,
        path: '/readers',
        fromJson: Reader.fromJson,
        toJson: (r) => {
          'fullName': r.fullName,
          'email': r.email,
          'phone': r.phone,
          'card': r.card.toJson(),
        },
        idOf: (r) => r.id,
      );
}
