import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:library_web/models/book.dart';
import 'package:library_web/models/library_card.dart';
import 'package:library_web/models/reader.dart';
import 'package:library_web/models/book_query.dart';
import 'package:library_web/repositories/local_book_repository.dart';
import 'package:library_web/storage/json_store.dart';
import 'package:library_web/storage/storage_notices.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _newBook = Book(
  id: 0,
  title: 'Сохранённая',
  isbn: '978-5-00-000000-0',
  year: 2026,
  pages: 100,
  publisherId: 1,
  authorIds: [1],
  genreIds: [1],
  copiesTotal: 3,
  copiesAvailable: 3,
);

Future<SharedPreferences> _prefs([
  Map<String, Object> initial = const {},
]) async {
  SharedPreferences.setMockInitialValues(initial);
  return SharedPreferences.getInstance();
}

void main() {
  group('toJson / fromJson', () {
    test('книга восстанавливается из собственного JSON', () {
      final book = _newBook.copyWith(deletedAt: DateTime.utc(2026, 1, 2));
      final copy = Book.fromJson(
        jsonDecode(jsonEncode(book.toJson())) as Map<String, dynamic>,
      );
      expect(copy.title, book.title);
      expect(copy.authorIds, [1]);
      expect(copy.deletedAt, DateTime.utc(2026, 1, 2));
    });

    test('разбор устойчив к отсутствующим, null и чужим по типу полям', () {
      final book = Book.fromJson({
        'id': 5,
        'title': null,
        'year': '1999',
        'pages': 12.0,
        'authorIds': [1, '2', 'x', null],
        'genreIds': 'не список',
        'deletedAt': 'не дата',
      });
      expect(book.id, 5);
      expect(book.title, '');
      expect(book.year, 1999);
      expect(book.pages, 12);
      expect(book.authorIds, [1, 2]);
      expect(book.genreIds, isEmpty);
      expect(book.deletedAt, isNull);
      expect(book.copiesTotal, 0);
    });

    test('читатель с билетом: круговое преобразование и пустой JSON', () {
      final reader = Reader(
        id: 1,
        fullName: 'Иванов И. И.',
        email: 'ivanov@example.com',
        phone: '',
        card: LibraryCard(
          id: 1,
          number: 'RC-000001',
          issuedAt: DateTime.utc(2026, 1, 1),
          expiresAt: DateTime.utc(2027, 1, 1),
        ),
      );
      final copy = Reader.fromJson(
        jsonDecode(jsonEncode(reader.toJson())) as Map<String, dynamic>,
      );
      expect(copy.card.number, 'RC-000001');
      expect(copy.card.expiresAt, DateTime.utc(2027, 1, 1));
      // Пустой объект не должен приводить к исключению.
      expect(Reader.fromJson(const {}).card.number, '');
    });
  });

  group('сохранение между перезагрузками', () {
    test('первый запуск записывает начальный набор', () async {
      final prefs = await _prefs();
      LocalBookRepository(prefs: prefs);
      final raw = jsonDecode(prefs.getString('books_v2')!) as Map;
      expect(raw['version'], 2);
      expect((raw['items'] as List), hasLength(36));
    });

    test('созданная книга видна после «перезагрузки»', () async {
      final prefs = await _prefs();
      final first = LocalBookRepository(prefs: prefs);
      final created = await first.create(_newBook);
      expect(created.id, 37);

      // Новый экземпляр читает те же данные из хранилища.
      final second = LocalBookRepository(prefs: prefs);
      final page = await second.find(const BookQuery(search: 'Сохранённая'));
      expect(page.items.single.id, 37);
    });

    test('изменение и удаление тоже сохраняются', () async {
      final prefs = await _prefs();
      final first = LocalBookRepository(prefs: prefs);
      await first.update(
        (await first.findById(1))!.copyWith(title: 'Новое имя'),
      );
      await first.softDelete(2);
      await first.hardDelete(3);

      final second = LocalBookRepository(prefs: prefs);
      expect((await second.findById(1))!.title, 'Новое имя');
      expect((await second.findById(2))!.isDeleted, isTrue);
      expect(await second.findById(3), isNull);
    });

    test(
      'идентификаторы не повторяются после удаления последней записи',
      () async {
        final prefs = await _prefs();
        final repo = LocalBookRepository(prefs: prefs);
        final a = await repo.create(_newBook);
        await repo.hardDelete(a.id);
        final b = await repo.create(
          _newBook.copyWith(isbn: '978-5-11-111111-1'),
        );
        expect(b.id, a.id); // максимальный id снова свободен, дублей нет
        final ids = (await repo.findAll()).map((e) => e.id);
        expect(ids.toSet(), hasLength(ids.length));
      },
    );
  });

  group('версии формата', () {
    test('старый формат (v1) переносится с сообщением', () async {
      final old = jsonEncode([
        {'id': 1, 'title': 'Из старой версии', 'isbn': '978-5-00-000000-0'},
        {'id': 2, 'title': null},
      ]);
      final prefs = await _prefs({'books_v1': old});
      final notices = StorageNotices();
      final repo = LocalBookRepository(prefs: prefs, notices: notices);

      final all = await repo.findAll();
      expect(all, hasLength(2));
      expect(all.first.title, 'Из старой версии');
      expect(prefs.getString('books_v1'), isNull);
      expect(prefs.getString('books_v2'), isNotNull);
      expect(notices.messages.single, contains('перенесены в новый формат'));
    });

    test(
      'испорченные данные не роняют приложение: начальный набор и сообщение',
      () async {
        final prefs = await _prefs({'books_v2': '{не json'});
        final notices = StorageNotices();
        final repo = LocalBookRepository(prefs: prefs, notices: notices);

        expect(await repo.findAll(), hasLength(36));
        expect(
          notices.messages.single,
          contains('Восстановлен начальный набор'),
        );
      },
    );

    test('неизвестная версия формата тоже сбрасывается', () async {
      final prefs = await _prefs({
        'books_v2': jsonEncode({'version': 99, 'items': []}),
      });
      final notices = StorageNotices();
      final repo = LocalBookRepository(prefs: prefs, notices: notices);
      expect(await repo.findAll(), hasLength(36));
      expect(notices.messages, hasLength(1));
    });

    test('нечитаемый старый формат удаляется и не мешает запуску', () async {
      final prefs = await _prefs({'books_v1': 'мусор'});
      final notices = StorageNotices();
      final repo = LocalBookRepository(prefs: prefs, notices: notices);
      expect(await repo.findAll(), hasLength(36));
      expect(prefs.getString('books_v1'), isNull);
    });

    test('ключ содержит версию формата', () async {
      final prefs = await _prefs();
      final store = JsonStore<Book>(
        prefs: prefs,
        collection: 'books',
        title: 'Книги',
        fromJson: Book.fromJson,
        toJson: (b) => b.toJson(),
        seed: const [],
      );
      expect(store.key, 'books_v2');
      expect(store.legacyKey, 'books_v1');
    });
  });
}
