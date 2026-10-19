import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'storage_notices.dart';

/// Хранение коллекции записей в localStorage (через shared_preferences).
///
/// Формат версионируется. Текущая версия лежит под ключом `<коллекция>_v2`
/// в виде `{"version": 2, "items": [...]}`. Данные старого формата
/// (`<коллекция>_v1`, голый список) переносятся автоматически. Если данные
/// нечитаемы, коллекция начинается заново с начального набора и пользователю
/// показывается сообщение, а приложение не падает.
class JsonStore<T> {
  JsonStore({
    required this.prefs,
    required this.collection,
    required this.title,
    required this.fromJson,
    required this.toJson,
    required this.seed,
    this.notices,
  });

  static const currentVersion = 2;

  final SharedPreferences prefs;
  final String collection;
  final String title;
  final T Function(Map<String, dynamic> json) fromJson;
  final Map<String, dynamic> Function(T item) toJson;
  final List<T> seed;
  final StorageNotices? notices;

  String get key => '${collection}_v$currentVersion';
  String get legacyKey => '${collection}_v1';

  List<T> load() {
    final raw = prefs.getString(key);
    if (raw != null) {
      final items = _readCurrent(raw);
      if (items != null) return items;
      return _reset(
        'Сохранённые данные раздела «$title» нельзя прочитать. '
        'Восстановлен начальный набор.',
      );
    }

    final legacy = prefs.getString(legacyKey);
    if (legacy != null) {
      final items = _readLegacy(legacy);
      if (items != null) {
        save(items);
        prefs.remove(legacyKey);
        notices?.add('Данные раздела «$title» перенесены в новый формат.');
        return items;
      }
      prefs.remove(legacyKey);
      return _reset(
        'Данные раздела «$title» устарели и не читаются. '
        'Восстановлен начальный набор.',
      );
    }

    // Первый запуск.
    final items = List<T>.of(seed);
    save(items);
    return items;
  }

  List<T> _reset(String message) {
    final items = List<T>.of(seed);
    save(items);
    notices?.add(message);
    return items;
  }

  List<T>? _readCurrent(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map || decoded['version'] != currentVersion) return null;
      return _parseList(decoded['items']);
    } catch (_) {
      return null;
    }
  }

  List<T>? _readLegacy(String raw) {
    try {
      return _parseList(jsonDecode(raw));
    } catch (_) {
      return null;
    }
  }

  List<T>? _parseList(Object? list) {
    if (list is! List) return null;
    return [
      for (final e in list)
        if (e is Map) fromJson(Map<String, dynamic>.from(e)),
    ];
  }

  /// Записывает коллекцию. Вызывать нужно после каждого изменения.
  Future<void> save(List<T> items) async {
    final payload = jsonEncode({
      'version': currentVersion,
      'items': [for (final item in items) toJson(item)],
    });
    await prefs.setString(key, payload);
  }
}
