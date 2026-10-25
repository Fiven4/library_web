import 'package:dio/dio.dart';

import '../models/book.dart';
import '../models/book_query.dart';
import 'api_repository.dart';
import 'book_repository.dart';

class ApiBookRepository extends ApiRepository<Book, BookQuery>
    implements BookRepository {
  ApiBookRepository(Dio dio)
      : super(
          dio: dio,
          path: '/books',
          fromJson: Book.fromJson,
          toJson: (b) => {
            'title': b.title,
            'isbn': b.isbn,
            'year': b.year,
            'pages': b.pages,
            'publisherId': b.publisherId,
            'authorIds': b.authorIds,
            'genreIds': b.genreIds,
            'copiesTotal': b.copiesTotal,
          },
          idOf: (b) => b.id,
        );

  @override
  Future<int> countLinked({
    int? authorId,
    int? genreId,
    int? publisherId,
    bool includeDeleted = false,
  }) async {
    final res = await find(
      BookQuery(
        authorId: authorId,
        genreId: genreId,
        publisherId: publisherId,
        size: 1,
        includeDeleted: includeDeleted,
      ),
    );
    return res.total;
  }
}
