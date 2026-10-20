import 'package:flutter_test/flutter_test.dart';
import 'package:library_web/models/author_query.dart';
import 'package:library_web/models/book.dart';
import 'package:library_web/models/book_query.dart';
import 'package:library_web/repositories/local_author_repository.dart';
import 'package:library_web/repositories/local_book_repository.dart';

void main() {
  late LocalBookRepository books;
  setUp(() => books = LocalBookRepository());

  group('LocalBookRepository.find', () {
    test('начальный набор содержит не менее 20 книг', () async {
      final r = await books.find(const BookQuery(size: 50));
      expect(r.total, greaterThanOrEqualTo(20));
    });

    test('поиск по названию не зависит от регистра', () async {
      final r = await books.find(const BookQuery(search: 'ВОЙНА'));
      expect(r.items.map((b) => b.title), contains('Война и мир'));
    });

    test('поиск по ISBN', () async {
      final r = await books.find(const BookQuery(search: '978-5-17-080115-5'));
      expect(r.items.single.title, '1984');
    });

    test('фильтры комбинируются между собой и с поиском', () async {
      final r = await books.find(
        const BookQuery(genreId: 2, publisherId: 1, yearFrom: 1960, size: 50),
      );
      expect(r.items, isNotEmpty);
      for (final b in r.items) {
        expect(b.genreIds, contains(2));
        expect(b.publisherId, 1);
        expect(b.year, greaterThanOrEqualTo(1960));
      }
      final narrowed = await books.find(
        const BookQuery(
          genreId: 2,
          publisherId: 1,
          yearFrom: 1960,
          yearTo: 1966,
          search: 'бог',
        ),
      );
      expect(narrowed.items.map((b) => b.title), ['Трудно быть богом']);
    });

    test('фильтр по автору', () async {
      final r = await books.find(const BookQuery(authorId: 6, size: 50));
      expect(r.items.map((b) => b.title).toSet(), {'1984', 'Скотный двор'});
    });

    test('сортировка по году в обе стороны', () async {
      final asc = await books.find(
        const BookQuery(sortField: 'year', size: 50),
      );
      final years = asc.items.map((b) => b.year).toList();
      expect(years, [...years]..sort());
      final desc = await books.find(
        const BookQuery(sortField: 'year', sortAscending: false, size: 50),
      );
      expect(desc.items.first.year, years.last);
    });

    test(
      'постраничный вывод: размер, последняя неполная и пустая страницы',
      () async {
        final first = await books.find(const BookQuery());
        expect(first.items, hasLength(10));
        expect(first.totalPages, 4);
        final last = await books.find(const BookQuery(page: 4));
        expect(last.items, hasLength(6));
        final beyond = await books.find(const BookQuery(page: 9));
        expect(beyond.items, isEmpty);
        expect(beyond.total, 36);
      },
    );

    test('страницы не пересекаются и покрывают весь список', () async {
      final ids = <int>{};
      for (var p = 1; p <= 4; p++) {
        ids.addAll(
          (await books.find(BookQuery(page: p))).items.map((b) => b.id),
        );
      }
      expect(ids, hasLength(36));
    });
  });

  group('удаление', () {
    test('логическое удаление убирает запись из выборки', () async {
      await books.softDelete(1);
      final r = await books.find(const BookQuery(search: 'война'));
      expect(r.items.where((b) => b.id == 1), isEmpty);
      final all = await books.find(
        const BookQuery(search: 'война', includeDeleted: true),
      );
      expect(all.items.single.isDeleted, isTrue);
    });

    test('восстановление возвращает запись', () async {
      await books.softDelete(1);
      await books.restore(1);
      final b = await books.findById(1);
      expect(b!.isDeleted, isFalse);
    });

    test('физическое удаление стирает запись насовсем', () async {
      await books.hardDelete(1);
      expect(await books.findById(1), isNull);
    });

    test('карточку логически удалённой записи открыть можно', () async {
      await books.softDelete(2);
      expect((await books.findById(2))!.isDeleted, isTrue);
    });

    test('deleteMany удаляет только существующие и ещё не удалённые', () async {
      await books.softDelete(3);
      final count = await books.deleteMany([1, 2, 3, 9999]);
      expect(count, 2);
      final r = await books.find(
        const BookQuery(includeDeleted: true, size: 50),
      );
      expect(r.items.where((b) => b.isDeleted).map((b) => b.id).toSet(), {
        1,
        2,
        3,
      });
    });

    test('softDelete несуществующей записи сообщает об ошибке', () async {
      expect(() => books.softDelete(9999), throwsA(anything));
    });
  });

  test('create присваивает следующий идентификатор', () async {
    final created = await books.create(
      const Book(
        id: 0,
        title: 'Новая',
        isbn: '1',
        year: 2026,
        pages: 10,
        publisherId: 1,
        authorIds: [],
        genreIds: [],
        copiesTotal: 2,
        copiesAvailable: 0,
      ),
    );
    expect(created.id, 37);
    expect(created.copiesAvailable, 2);
    final updated = await books.update(created.copyWith(title: 'Правка'));
    expect((await books.findById(updated.id))!.title, 'Правка');
  });

  group('LocalAuthorRepository', () {
    late LocalAuthorRepository authors;
    setUp(() => authors = LocalAuthorRepository());

    test('начальный набор содержит не менее 8 авторов', () async {
      final r = await authors.find(const AuthorQuery(size: 50));
      expect(r.total, greaterThanOrEqualTo(8));
    });

    test('поиск по фамилии и по стране', () async {
      final byName = await authors.find(const AuthorQuery(search: 'толст'));
      expect(byName.items.single.fullName, 'Толстой Л. Н.');
      final byCountry = await authors.find(
        const AuthorQuery(search: 'сша', size: 50),
      );
      expect(byCountry.items.map((a) => a.country).toSet(), {'США'});
    });

    test('фильтр по стране и сортировка по году рождения', () async {
      final r = await authors.find(
        const AuthorQuery(country: 'Россия', sortField: 'birthYear', size: 50),
      );
      final years = r.items.map((a) => a.birthYear).toList();
      expect(years, [...years]..sort());
      expect(r.items.every((a) => a.country == 'Россия'), isTrue);
    });

    test('удаление и восстановление автора', () async {
      expect(await authors.deleteMany([1, 2]), 2);
      expect((await authors.find(const AuthorQuery(size: 50))).total, 10);
      await authors.restore(1);
      expect((await authors.find(const AuthorQuery(size: 50))).total, 11);
    });
  });
}
