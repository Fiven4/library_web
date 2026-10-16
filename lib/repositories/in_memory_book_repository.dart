import '../core/dev_settings.dart';
import '../data/seed_data.dart';
import '../models/book.dart';
import '../models/book_query.dart';
import '../models/page_result.dart';
import 'book_repository.dart';
import 'entity_repository.dart';

class InMemoryBookRepository implements BookRepository {
  InMemoryBookRepository([this._dev]);

  final DevSettings? _dev;
  final List<Book> _books = [...seedBooks];
  int _nextId = seedBooks.length + 1;

  /// Небольшая задержка имитирует сеть: без неё индикатор загрузки
  /// невозможно увидеть, а при подключении сервера он понадобится по-настоящему.
  Future<void> _simulateNetwork() async {
    await Future.delayed(_dev?.delay ?? Duration.zero);
    if (_dev?.failing ?? false) {
      throw const RepositoryException('сервер недоступен (имитация сбоя)');
    }
  }

  @override
  Future<PageResult<Book>> find(BookQuery q) async {
    await _simulateNetwork();

    var rows = _books.where((b) => q.includeDeleted || !b.isDeleted).toList();

    if (q.search.trim().isNotEmpty) {
      final needle = q.search.trim().toLowerCase();
      rows = rows
          .where(
            (b) =>
                b.title.toLowerCase().contains(needle) ||
                b.isbn.toLowerCase().contains(needle),
          )
          .toList();
    }
    if (q.genreId != null) {
      rows = rows.where((b) => b.genreIds.contains(q.genreId)).toList();
    }
    if (q.publisherId != null) {
      rows = rows.where((b) => b.publisherId == q.publisherId).toList();
    }
    if (q.authorId != null) {
      rows = rows.where((b) => b.authorIds.contains(q.authorId)).toList();
    }
    if (q.yearFrom != null) {
      rows = rows.where((b) => b.year >= q.yearFrom!).toList();
    }
    if (q.yearTo != null) {
      rows = rows.where((b) => b.year <= q.yearTo!).toList();
    }

    rows.sort((a, b) {
      final result = switch (q.sortField) {
        'year' => a.year.compareTo(b.year),
        'pages' => a.pages.compareTo(b.pages),
        _ => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
      };
      // При равенстве ключей порядок задаёт id, иначе строки «прыгают».
      final ordered = result != 0 ? result : a.id.compareTo(b.id);
      return q.sortAscending ? ordered : -ordered;
    });

    final total = rows.length;
    final from = (q.page - 1) * q.size;
    // num.clamp возвращает num, а не int, и в sublist его передать нельзя,
    // поэтому верхнюю границу считаем явно.
    final to = (from + q.size) > total ? total : (from + q.size);
    final items = from >= total ? <Book>[] : rows.sublist(from, to);
    return PageResult(items: items, page: q.page, size: q.size, total: total);
  }

  @override
  Future<Book?> findById(int id) async {
    await _simulateNetwork();
    final i = _books.indexWhere((b) => b.id == id);
    return i == -1 ? null : _books[i];
  }

  @override
  Future<Book> create(Book book) async {
    await _simulateNetwork();
    final created = Book(
      id: _nextId++,
      title: book.title,
      isbn: book.isbn,
      year: book.year,
      pages: book.pages,
      publisherId: book.publisherId,
      authorIds: book.authorIds,
      genreIds: book.genreIds,
      copiesTotal: book.copiesTotal,
      copiesAvailable: book.copiesTotal,
    );
    _books.add(created);
    return created;
  }

  @override
  Future<Book> update(Book book) async {
    await _simulateNetwork();
    final i = _books.indexWhere((b) => b.id == book.id);
    if (i == -1) throw RepositoryException('Книга ${book.id} не найдена');
    _books[i] = book;
    return book;
  }

  @override
  Future<void> softDelete(int id) async {
    await _simulateNetwork();
    final i = _books.indexWhere((b) => b.id == id);
    if (i == -1) throw RepositoryException('Книга $id не найдена');
    _books[i] = _books[i].copyWith(deletedAt: DateTime.now());
  }

  @override
  Future<void> hardDelete(int id) async {
    await _simulateNetwork();
    _books.removeWhere((b) => b.id == id);
  }

  @override
  Future<void> restore(int id) async {
    await _simulateNetwork();
    final i = _books.indexWhere((b) => b.id == id);
    if (i == -1) throw RepositoryException('Книга $id не найдена');
    _books[i] = _books[i].copyWith(clearDeletedAt: true);
  }

  @override
  Future<int> deleteMany(List<int> ids) async {
    await _simulateNetwork();
    var count = 0;
    for (final id in ids) {
      // Ошибка исходного кода: в замыкании было написано `!b[i].isDeleted`.
      // Элемент `b` уже является книгой, а переменная `i` в этот момент ещё
      // не объявлена (она получает значение только после indexWhere), поэтому
      // код не компилировался. Правильная проверка — `!b.isDeleted`.
      final i = _books.indexWhere((b) => b.id == id && !b.isDeleted);
      if (i != -1) {
        _books[i] = _books[i].copyWith(deletedAt: DateTime.now());
        count++;
      }
    }
    return count;
  }
}
