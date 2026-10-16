import 'package:flutter/foundation.dart';

import '../models/author.dart';
import '../models/reference.dart';
import '../repositories/author_repository.dart';
import '../repositories/reference_repository.dart';

/// Справочные данные для подписей в таблицах и для выпадающих списков
/// фильтров. Загружаются один раз при запуске приложения.
class ReferenceNotifier extends ChangeNotifier {
  ReferenceNotifier(this._reference, this._authors);

  final ReferenceRepository _reference;
  final AuthorRepository _authors;

  List<Genre> _genres = const [];
  List<Publisher> _publishers = const [];
  List<Author> _allAuthors = const [];
  bool _loaded = false;
  bool _disposed = false;

  List<Genre> get genres => _genres;
  List<Publisher> get publishers => _publishers;
  bool get loaded => _loaded;

  /// Страны авторов без повторов, по алфавиту.
  List<String> get countries =>
      (_allAuthors.map((a) => a.country).toSet().toList()..sort());

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<void> load() async {
    try {
      _genres = await _reference.genres();
      _publishers = await _reference.publishers();
      _allAuthors = await _authors.findAll();
    } catch (_) {
      // Подписи необязательны: при сбое таблицы покажут прочерки.
    }
    _loaded = true;
    if (!_disposed) notifyListeners();
  }

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
              _allAuthors
                  .where((a) => a.id == id)
                  .map((a) => a.fullName)
                  .firstOrNull ??
              '—',
        )
        .join(', ');
  }
}
