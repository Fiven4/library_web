import 'package:flutter/foundation.dart';

import '../models/author.dart';
import '../models/book.dart';
import '../models/genre.dart';
import '../models/publisher.dart';
import '../repositories/author_repository.dart';
import '../repositories/book_repository.dart';
import '../repositories/entity_repository.dart';
import '../repositories/genre_repository.dart';
import '../repositories/publisher_repository.dart';

/// Справочные данные для подписей в таблицах и для выпадающих списков.
/// Заполняются из репозиториев (не константами) и обновляются при любом
/// изменении данных: новый жанр сразу появляется в форме книги.
class ReferenceNotifier extends ChangeNotifier {
  ReferenceNotifier({
    required GenreRepository genres,
    required PublisherRepository publishers,
    required AuthorRepository authors,
    required BookRepository books,
  }) : _genreRepo = genres,
       _publisherRepo = publishers,
       _authorRepo = authors,
       _bookRepo = books {
    for (final r in <EntityRepository<Object?, Object?>>[
      genres,
      publishers,
      authors,
      books,
    ]) {
      r.changes.addListener(load);
    }
  }

  final GenreRepository _genreRepo;
  final PublisherRepository _publisherRepo;
  final AuthorRepository _authorRepo;
  final BookRepository _bookRepo;

  List<Genre> _genres = const [];
  List<Publisher> _publishers = const [];
  List<Author> _authors = const [];
  List<Book> _books = const [];
  bool _loaded = false;
  bool _disposed = false;

  bool get loaded => _loaded;

  /// Для выбора в формах и фильтрах: только неудалённые, по алфавиту.
  List<Genre> get genres => _sorted([
    for (final g in _genres)
      if (!g.isDeleted) g,
  ], (g) => g.name);
  List<Publisher> get publishers => _sorted([
    for (final p in _publishers)
      if (!p.isDeleted) p,
  ], (p) => p.name);
  List<Author> get authors => _sorted([
    for (final a in _authors)
      if (!a.isDeleted) a,
  ], (a) => a.fullName);

  /// Страны и города без повторов, по алфавиту.
  List<String> get countries =>
      (_authors.map((a) => a.country).toSet().toList()..sort());
  List<String> get cities =>
      (_publishers.map((p) => p.city).toSet().toList()..sort());

  List<T> _sorted<T>(List<T> list, String Function(T) key) =>
      list
        ..sort((a, b) => key(a).toLowerCase().compareTo(key(b).toLowerCase()));

  @override
  void dispose() {
    _disposed = true;
    for (final r in <EntityRepository<Object?, Object?>>[
      _genreRepo,
      _publisherRepo,
      _authorRepo,
      _bookRepo,
    ]) {
      r.changes.removeListener(load);
    }
    super.dispose();
  }

  Future<void> load() async {
    try {
      final results = await Future.wait([
        _genreRepo.findAll(),
        _publisherRepo.findAll(),
        _authorRepo.findAll(),
        _bookRepo.findAll(),
      ]);
      _genres = results[0] as List<Genre>;
      _publishers = results[1] as List<Publisher>;
      _authors = results[2] as List<Author>;
      _books = results[3] as List<Book>;
    } catch (_) {
      // Подписи необязательны: при сбое таблицы покажут прочерки.
    }
    _loaded = true;
    if (!_disposed) notifyListeners();
  }

  /// Авторы, у которых уже есть книги этого издательства. Нужны для
  /// каскадного сужения списка авторов в форме книги.
  Set<int> authorIdsOfPublisher(int publisherId) => {
    for (final b in _books)
      if (!b.isDeleted && b.publisherId == publisherId) ...b.authorIds,
  };

  String genreName(int id) =>
      _genres.where((g) => g.id == id).map((g) => g.name).firstOrNull ?? '—';

  String publisherName(int id) =>
      _publishers.where((p) => p.id == id).map((p) => p.name).firstOrNull ??
      '—';

  String genreNames(List<int> ids) =>
      ids.isEmpty ? '—' : ids.map(genreName).join(', ');

  String authorNames(List<int> ids) {
    if (ids.isEmpty) return '—';
    return ids
        .map(
          (id) =>
              _authors
                  .where((a) => a.id == id)
                  .map((a) => a.fullName)
                  .firstOrNull ??
              '—',
        )
        .join(', ');
  }
}
