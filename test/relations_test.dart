import 'package:flutter_test/flutter_test.dart';
import 'package:library_web/data/seed_data.dart';
import 'package:library_web/models/author.dart';
import 'package:library_web/models/author_query.dart';
import 'package:library_web/models/book.dart';
import 'package:library_web/models/genre.dart';
import 'package:library_web/models/genre_query.dart';
import 'package:library_web/models/library_card.dart';
import 'package:library_web/models/publisher.dart';
import 'package:library_web/models/publisher_query.dart';
import 'package:library_web/models/reader.dart';
import 'package:library_web/models/reader_query.dart';
import 'package:library_web/repositories/entity_repository.dart';
import 'package:library_web/repositories/local_author_repository.dart';
import 'package:library_web/repositories/local_book_repository.dart';
import 'package:library_web/repositories/local_genre_repository.dart';
import 'package:library_web/repositories/local_publisher_repository.dart';
import 'package:library_web/repositories/local_reader_repository.dart';

Reader _reader({
  String email = 'new@example.com',
  String number = 'RC-000099',
}) => Reader(
  id: 0,
  fullName: 'Новый Ч. Ч.',
  email: email,
  phone: '',
  card: LibraryCard(
    id: 0,
    number: number,
    issuedAt: DateTime.utc(2026, 1, 1),
    expiresAt: DateTime.utc(2027, 1, 1),
  ),
);

void main() {
  late LocalBookRepository books;
  setUp(() => books = LocalBookRepository());

  group('уникальность', () {
    test('ISBN книги не повторяется, дефисы не важны', () async {
      final existing = (await books.findById(1))!;
      final dup = existing.copyWith(isbn: existing.isbn.replaceAll('-', ''));
      await expectLater(
        books.create(dup),
        throwsA(
          isA<ValidationException>().having(
            (e) => e.errors['isbn'],
            'ошибка поля isbn',
            'Книга с таким ISBN уже существует',
          ),
        ),
      );
    });

    test('при изменении книга не конфликтует сама с собой', () async {
      final b = (await books.findById(1))!;
      final saved = await books.update(b.copyWith(title: 'Правка'));
      expect(saved.title, 'Правка');
    });

    test('при изменении ISBN на чужой — ошибка', () async {
      final a = (await books.findById(1))!;
      final b = (await books.findById(2))!;
      await expectLater(
        books.update(a.copyWith(isbn: b.isbn)),
        throwsA(isA<ValidationException>()),
      );
    });

    test('адрес почты и номер билета читателя уникальны', () async {
      final readers = LocalReaderRepository();
      await expectLater(
        readers.create(_reader(email: 'SMIRNOV@example.com')),
        throwsA(
          isA<ValidationException>().having(
            (e) => e.errors.keys,
            'поля',
            contains('email'),
          ),
        ),
      );
      await expectLater(
        readers.create(_reader(number: 'RC-000001')),
        throwsA(
          isA<ValidationException>().having(
            (e) => e.errors.keys,
            'поля',
            contains('card.number'),
          ),
        ),
      );
      final created = await readers.create(_reader());
      expect(created.id, 7);
      expect(created.card.id, 7); // билет получает идентификатор читателя
    });

    test(
      'ISBN удалённой логически книги можно занять, но тогда её нельзя восстановить',
      () async {
        await books.softDelete(1);
        final deleted = (await books.findById(1))!;
        final copy = await books.create(
          Book(
            id: 0,
            title: 'Дубль',
            isbn: deleted.isbn,
            year: 2000,
            pages: 1,
            publisherId: 1,
            authorIds: const [],
            genreIds: const [1],
            copiesTotal: 1,
            copiesAvailable: 1,
          ),
        );
        expect(copy.id, 37);
        await expectLater(books.restore(1), throwsA(isA<ConflictException>()));
      },
    );
  });

  group('защита от удаления связанных записей', () {
    test(
      'издательство с книгами не удаляется, сообщение содержит число',
      () async {
        final publishers = LocalPublisherRepository(books: books);
        final linked = seedBooks.where((b) => b.publisherId == 1).length;
        await expectLater(
          publishers.softDelete(1),
          throwsA(
            isA<ConflictException>().having(
              (e) => e.message,
              'сообщение',
              allOf(contains('«АСТ»'), contains('($linked)')),
            ),
          ),
        );
        await expectLater(
          publishers.hardDelete(1),
          throwsA(isA<ConflictException>()),
        );
        // запись осталась на месте
        expect((await publishers.findById(1))!.isDeleted, isFalse);
      },
    );

    test('после удаления книг издательство удаляется', () async {
      final publishers = LocalPublisherRepository(books: books);
      await books.hardDelete(35); // единственная книга «МИФ»
      await publishers.softDelete(6);
      expect((await publishers.findById(6))!.isDeleted, isTrue);
    });

    test('физическое удаление учитывает и удалённые логически книги', () async {
      final publishers = LocalPublisherRepository(books: books);
      await books.softDelete(35);
      await publishers.softDelete(6); // логически удалённая книга не мешает
      await expectLater(
        publishers.hardDelete(6),
        throwsA(isA<ConflictException>()),
      );
    });

    test('автор и жанр с книгами не удаляются', () async {
      final authors = LocalAuthorRepository(books: books);
      final genres = LocalGenreRepository(books: books);
      await expectLater(
        authors.softDelete(6),
        throwsA(isA<ConflictException>()),
      );
      await expectLater(
        genres.softDelete(1),
        throwsA(isA<ConflictException>()),
      );
    });

    test('множественное удаление пропускает защищённые записи', () async {
      final publishers = LocalPublisherRepository(books: books);
      await books.hardDelete(35);
      final deleted = await publishers.deleteMany([1, 2, 6]);
      expect(deleted, 1); // только «МИФ»
    });

    test('читатель удаляется без ограничений', () async {
      final readers = LocalReaderRepository();
      await readers.softDelete(1);
      expect((await readers.findById(1))!.isDeleted, isTrue);
    });
  });

  group('списки остальных сущностей', () {
    test('жанры: поиск и сортировка', () async {
      final genres = LocalGenreRepository(books: books);
      final byName = await genres.find(const GenreQuery(search: 'фант'));
      expect(byName.items.single.name, 'Фантастика');
      final desc = await genres.find(
        const GenreQuery(sortField: 'name', sortAscending: false),
      );
      expect(desc.items.first.name, 'Фантастика');
    });

    test('издательства: поиск по городу, фильтр, сортировка по году', () async {
      final publishers = LocalPublisherRepository(books: books);
      final spb = await publishers.find(
        const PublisherQuery(city: 'Санкт-Петербург'),
      );
      expect(spb.items.map((p) => p.name).toSet(), {'Азбука', 'Питер'});
      final search = await publishers.find(
        const PublisherQuery(search: 'москва'),
      );
      expect(search.total, 4);
      final sorted = await publishers.find(
        const PublisherQuery(sortField: 'foundedYear', size: 50),
      );
      expect(sorted.items.first.name, 'Просвещение');
    });

    test('читатели: поиск по номеру билета и фильтр по статусу', () async {
      final readers = LocalReaderRepository();
      final byCard = await readers.find(const ReaderQuery(search: 'RC-000004'));
      expect(byCard.items.single.fullName, 'Васильева Е. О.');
      final expired = await readers.find(
        const ReaderQuery(cardStatus: CardStatus.expired),
      );
      expect(expired.items.map((r) => r.id).toSet(), {3, 5});
      final active = await readers.find(
        const ReaderQuery(cardStatus: CardStatus.active),
      );
      expect(active.total, 4);
    });

    test(
      'создание жанра и издательства с повторяющимся названием запрещено',
      () async {
        final genres = LocalGenreRepository(books: books);
        await expectLater(
          genres.create(const Genre(id: 0, name: ' роман ')),
          throwsA(isA<ValidationException>()),
        );
        final publishers = LocalPublisherRepository(books: books);
        await expectLater(
          publishers.create(
            const Publisher(
              id: 0,
              name: 'АСТ',
              city: 'Тула',
              foundedYear: 2000,
            ),
          ),
          throwsA(isA<ValidationException>()),
        );
      },
    );

    test('создание автора присваивает идентификатор', () async {
      final authors = LocalAuthorRepository(books: books);
      final created = await authors.create(
        const Author(
          id: 0,
          fullName: 'Новый А. А.',
          birthYear: 1990,
          country: 'Россия',
        ),
      );
      expect(created.id, 13);
      expect((await authors.find(const AuthorQuery(search: 'новый'))).total, 1);
    });
  });
}
