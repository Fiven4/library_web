import 'package:flutter_test/flutter_test.dart';
import 'package:library_web/models/author_query.dart';
import 'package:library_web/models/book.dart';
import 'package:library_web/models/book_query.dart';
import 'package:library_web/models/list_query.dart';
import 'package:library_web/models/page_result.dart';

const _book = Book(
  id: 1,
  title: 'Война и мир',
  isbn: '978',
  year: 1869,
  pages: 1300,
  publisherId: 1,
  authorIds: [1],
  genreIds: [1],
  copiesTotal: 4,
  copiesAvailable: 3,
);

void main() {
  group('Book.copyWith', () {
    test('меняет только переданные поля', () {
      final b = _book.copyWith(title: 'Другая', year: 1900);
      expect(b.title, 'Другая');
      expect(b.year, 1900);
      expect(b.isbn, _book.isbn);
      expect(b.id, _book.id);
    });

    test('clearDeletedAt отличает «не менять» от «сбросить»', () {
      final deleted = _book.copyWith(deletedAt: DateTime(2026, 1, 1));
      expect(deleted.isDeleted, isTrue);
      expect(deleted.copyWith(title: 'X').isDeleted, isTrue);
      expect(deleted.copyWith(clearDeletedAt: true).isDeleted, isFalse);
    });
  });

  group('PageResult', () {
    test('считает число страниц и соседние страницы', () {
      const r = PageResult<int>(items: [1], page: 2, size: 10, total: 36);
      expect(r.totalPages, 4);
      expect(r.hasPrevious, isTrue);
      expect(r.hasNext, isTrue);
      const last = PageResult<int>(items: [1], page: 4, size: 10, total: 36);
      expect(last.hasNext, isFalse);
    });

    test('пустая страница содержит одну страницу и ноль записей', () {
      final r = PageResult<int>.empty();
      expect(r.totalPages, 1);
      expect(r.items, isEmpty);
      expect(r.hasNext, isFalse);
    });
  });

  group('BookQuery', () {
    test('любое изменение условий возвращает на первую страницу', () {
      final q = const BookQuery(page: 3);
      expect(q.copyWith(search: 'война').page, 1);
      expect(q.copyWith(genreId: 2).page, 1);
      expect(q.withSort('year', false).page, 1);
      expect(q.withPage(5).page, 5);
    });

    test('null сбрасывает фильтр, отсутствие параметра не меняет его', () {
      final q = const BookQuery(genreId: 2, yearFrom: 1900);
      expect(q.copyWith(search: 'a').genreId, 2);
      expect(q.copyWith(genreId: null).genreId, isNull);
      expect(q.copyWith(genreId: null).yearFrom, 1900);
    });

    test('значения по умолчанию в адрес не попадают', () {
      expect(const BookQuery().toParams(), isEmpty);
    });

    test('все условия превращаются в параметры адреса и обратно', () {
      const q = BookQuery(
        search: 'война',
        genreId: 2,
        publisherId: 1,
        yearFrom: 1800,
        yearTo: 1900,
        sortField: 'year',
        sortAscending: false,
        page: 3,
        size: 25,
        includeDeleted: true,
      );
      expect(q.toParams(), {
        'search': 'война',
        'genreId': '2',
        'publisherId': '1',
        'yearFrom': '1800',
        'yearTo': '1900',
        'sort': 'year,desc',
        'page': '3',
        'size': '25',
        'includeDeleted': 'true',
      });
      expect(BookQuery.fromParams(q.toParams()), q);
    });

    test('испорченные параметры заменяются значениями по умолчанию', () {
      final q = BookQuery.fromParams({
        'page': '-4',
        'size': '999',
        'sort': 'password,desc',
        'genreId': 'abc',
      });
      expect(q.page, 1);
      expect(q.size, 10);
      expect(q.sortField, 'title');
      expect(q.genreId, isNull);
    });
  });

  group('AuthorQuery', () {
    test('круговое преобразование через параметры адреса', () {
      const q = AuthorQuery(
        search: 'рос',
        country: 'Россия',
        sortField: 'birthYear',
        sortAscending: false,
        page: 2,
      );
      expect(AuthorQuery.fromParams(q.toParams()), q);
    });
  });

  group('buildLocation', () {
    test('запятая остаётся читаемой, кириллица кодируется', () {
      final url = buildLocation('/books', {
        'search': 'война',
        'sort': 'year,desc',
      });
      expect(url, contains('sort=year,desc'));
      expect(Uri.parse(url).queryParameters['search'], 'война');
    });

    test('без параметров возвращает путь', () {
      expect(buildLocation('/books', {}), '/books');
    });
  });
}
