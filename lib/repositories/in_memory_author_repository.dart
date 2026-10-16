import '../core/dev_settings.dart';
import '../data/seed_data.dart';
import '../models/author.dart';
import '../models/author_query.dart';
import '../models/page_result.dart';
import 'author_repository.dart';
import 'entity_repository.dart';

class InMemoryAuthorRepository implements AuthorRepository {
  InMemoryAuthorRepository([this._dev]);

  final DevSettings? _dev;
  final List<Author> _authors = [...seedAuthors];
  int _nextId = seedAuthors.length + 1;

  Future<void> _simulateNetwork() async {
    await Future.delayed(_dev?.delay ?? Duration.zero);
    if (_dev?.failing ?? false) {
      throw const RepositoryException('сервер недоступен (имитация сбоя)');
    }
  }

  @override
  Future<PageResult<Author>> find(AuthorQuery q) async {
    await _simulateNetwork();

    var rows = _authors.where((a) => q.includeDeleted || !a.isDeleted).toList();

    if (q.search.trim().isNotEmpty) {
      final needle = q.search.trim().toLowerCase();
      rows = rows
          .where(
            (a) =>
                a.fullName.toLowerCase().contains(needle) ||
                a.country.toLowerCase().contains(needle),
          )
          .toList();
    }
    if (q.country != null) {
      rows = rows.where((a) => a.country == q.country).toList();
    }

    rows.sort((a, b) {
      final result = switch (q.sortField) {
        'birthYear' => a.birthYear.compareTo(b.birthYear),
        'country' => a.country.toLowerCase().compareTo(b.country.toLowerCase()),
        _ => a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()),
      };
      final ordered = result != 0 ? result : a.id.compareTo(b.id);
      return q.sortAscending ? ordered : -ordered;
    });

    final total = rows.length;
    final from = (q.page - 1) * q.size;
    final to = (from + q.size) > total ? total : (from + q.size);
    final items = from >= total ? <Author>[] : rows.sublist(from, to);
    return PageResult(items: items, page: q.page, size: q.size, total: total);
  }

  @override
  Future<List<Author>> findAll() async {
    await _simulateNetwork();
    return List.unmodifiable(_authors);
  }

  @override
  Future<Author?> findById(int id) async {
    await _simulateNetwork();
    final i = _authors.indexWhere((a) => a.id == id);
    return i == -1 ? null : _authors[i];
  }

  @override
  Future<Author> create(Author author) async {
    await _simulateNetwork();
    final created = Author(
      id: _nextId++,
      fullName: author.fullName,
      birthYear: author.birthYear,
      country: author.country,
    );
    _authors.add(created);
    return created;
  }

  @override
  Future<Author> update(Author author) async {
    await _simulateNetwork();
    final i = _authors.indexWhere((a) => a.id == author.id);
    if (i == -1) throw RepositoryException('Автор ${author.id} не найден');
    _authors[i] = author;
    return author;
  }

  @override
  Future<void> softDelete(int id) async {
    await _simulateNetwork();
    final i = _authors.indexWhere((a) => a.id == id);
    if (i == -1) throw RepositoryException('Автор $id не найден');
    _authors[i] = _authors[i].copyWith(deletedAt: DateTime.now());
  }

  @override
  Future<void> hardDelete(int id) async {
    await _simulateNetwork();
    _authors.removeWhere((a) => a.id == id);
  }

  @override
  Future<void> restore(int id) async {
    await _simulateNetwork();
    final i = _authors.indexWhere((a) => a.id == id);
    if (i == -1) throw RepositoryException('Автор $id не найден');
    _authors[i] = _authors[i].copyWith(clearDeletedAt: true);
  }

  @override
  Future<int> deleteMany(List<int> ids) async {
    await _simulateNetwork();
    var count = 0;
    for (final id in ids) {
      final i = _authors.indexWhere((a) => a.id == id && !a.isDeleted);
      if (i != -1) {
        _authors[i] = _authors[i].copyWith(deletedAt: DateTime.now());
        count++;
      }
    }
    return count;
  }
}
