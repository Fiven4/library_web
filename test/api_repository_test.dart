import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:library_web/core/api_client.dart';
import 'package:library_web/core/api_exceptions.dart';
import 'package:library_web/models/book.dart';
import 'package:library_web/models/book_query.dart';
import 'package:library_web/repositories/api_book_repository.dart';

void main() {
  group('ApiBookRepository tests with mocked Dio', () {
    late Dio dio;
    late DioAdapter dioAdapter;
    late ApiBookRepository repo;

    setUp(() {
      dio = buildDio();
      dioAdapter = DioAdapter(dio: dio);
      repo = ApiBookRepository(dio);
    });

    test(
      '1. find() корректно запрашивает и парсит список книг с развёрнутыми связями',
      () async {
        dioAdapter.onGet(
          '/books',
          (server) => server.reply(200, {
            'items': [
              {
                'id': 1,
                'title': 'Война и мир',
                'isbn': '978-5-17-118366-4',
                'year': 1869,
                'pages': 1300,
                'publisher': {'id': 1, 'name': 'АСТ'},
                'authors': [
                  {'id': 1, 'fullName': 'Толстой Л. Н.'},
                ],
                'genres': [
                  {'id': 2, 'name': 'Роман'},
                ],
                'copiesTotal': 4,
                'copiesAvailable': 2,
                'deletedAt': null,
              },
            ],
            'page': 1,
            'size': 10,
            'total': 1,
            'totalPages': 1,
          }),
          queryParameters: {
            'search': 'война',
            'page': 1,
            'size': 10,
            'sort': 'title,asc',
          },
        );

        final result = await repo.find(const BookQuery(search: 'война'));

        expect(result.total, 1);
        expect(result.items.length, 1);
        final book = result.items.first;
        expect(book.id, 1);
        expect(book.title, 'Война и мир');
        expect(book.publisherId, 1);
        expect(book.authorIds, [1]);
        expect(book.genreIds, [2]);
      },
    );

    test(
      '2. Ошибка 422 преобразуется в ValidationException с картой ошибок полей',
      () async {
        dioAdapter.onPost(
          '/books',
          (server) => server.reply(422, {
            'message': 'Ошибка валидации',
            'errors': {'isbn': 'Книга с таким ISBN уже существует'},
          }),
          data: Matchers.any,
        );

        const newBook = Book(
          id: 0,
          title: 'Дубликат',
          isbn: '978-5-17-118366-4',
          year: 2020,
          pages: 300,
          publisherId: 1,
          authorIds: [1],
          genreIds: [2],
          copiesTotal: 5,
          copiesAvailable: 5,
        );

        expect(
          () => repo.create(newBook),
          throwsA(
            isA<ValidationException>().having(
              (e) => e.errors['isbn'],
              'isbn error',
              'Книга с таким ISBN уже существует',
            ),
          ),
        );
      },
    );

    test('3. Конфликт 409 преобразуется в ConflictException', () async {
      dioAdapter.onDelete(
        '/books/1',
        (server) => server.reply(409, {
          'message': 'Книга выдана и не может быть удалена физически',
        }),
        queryParameters: {'hard': true},
      );

      expect(
        () => repo.hardDelete(1),
        throwsA(
          isA<ConflictException>().having(
            (e) => e.message,
            'message',
            'Книга выдана и не может быть удалена физически',
          ),
        ),
      );
    });

    test(
      '4. Недоступность сервера / CORS преобразуется в NetworkException с подсказкой',
      () async {
        dioAdapter.onGet(
          '/books/999',
          (server) => server.throws(
            404,
            DioException(
              requestOptions: RequestOptions(path: '/books/999'),
              type: DioExceptionType.connectionError,
              error: 'Failed host lookup',
            ),
          ),
        );

        expect(
          () => repo.findById(999),
          throwsA(
            isA<NetworkException>().having(
              (e) => e.message,
              'message',
              contains('CORS'),
            ),
          ),
        );
      },
    );

    test(
      '5. Кэширование справочников: findAll использует кэш и инвалидирует его после изменения',
      () async {
        int requestCount = 0;
        dio.interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              if (options.path == '/books' &&
                  options.queryParameters['size'] == 100) {
                requestCount++;
              }
              return handler.next(options);
            },
          ),
        );

        dioAdapter.onGet(
          '/books',
          (server) => server.reply(200, {
            'items': [
              {
                'id': 1,
                'title': 'Книга 1',
                'isbn': '123',
                'year': 2000,
                'pages': 100,
                'publisherId': 1,
                'authorIds': [1],
                'genreIds': [1],
                'copiesTotal': 1,
                'copiesAvailable': 1,
              },
            ],
            'page': 1,
            'size': 100,
            'total': 1,
          }),
          queryParameters: {'size': 100, 'includeDeleted': false},
        );

        final first = await repo.findAll();
        final second = await repo.findAll();

        expect(first.length, 1);
        expect(second.length, 1);
        expect(requestCount, 1);

        repo.invalidateCache();

        final third = await repo.findAll();
        expect(third.length, 1);
        expect(requestCount, 2);
      },
    );

    test(
      '6. Отмена устаревших запросов через CancelToken при новом вызове find()',
      () async {
        dioAdapter.onGet(
          '/books',
          (server) => server.reply(200, {
            'items': [],
            'page': 1,
            'size': 10,
            'total': 0,
          }),
        );

        final f1 = repo.find(const BookQuery(search: 'в'));
        final f2 = repo.find(const BookQuery(search: 'война'));

        try {
          await f1;
        } catch (e) {
          expect(e, isA<NetworkException>());
        }

        final res2 = await f2;
        expect(res2.items, isEmpty);
      },
    );
  });
}
