import 'package:flutter/foundation.dart';

import '../core/dev_settings.dart';
import '../models/list_query.dart';
import '../models/page_result.dart';
import '../storage/json_store.dart';
import 'entity_repository.dart';

/// Общая реализация хранилища записей в памяти с необязательным сохранением
/// в localStorage. Конкретные репозитории описывают только то, что отличает
/// сущности друг от друга: отбор, порядок, уникальность и защиту от удаления.
abstract class LocalRepository<T, Q extends ListQuery<Q>>
    implements EntityRepository<T, Q> {
  LocalRepository({
    required List<T> seed,
    JsonStore<T>? store,
    DevSettings? dev,
  }) : _store = store,
       _dev = dev,
       _items = store?.load() ?? List<T>.of(seed);

  final JsonStore<T>? _store;
  final DevSettings? _dev;
  final List<T> _items;

  // Репозиторий отдаётся через Provider, поэтому сам не должен быть Listenable:
  // оповещения вынесены в отдельный объект.
  final _Changes _changes = _Changes();

  @override
  Listenable get changes => _changes;

  // ---- что должна описать конкретная сущность ----

  int idOf(T item);
  bool isDeletedItem(T item);
  T withDeleted(T item, DateTime? deletedAt);
  T withId(T item, int id);
  bool matches(T item, Q query);
  int compare(T a, T b, Q query);
  String notFound(int id);

  /// Проверка уникальности. [others] — остальные неудалённые записи.
  /// Бросает [ValidationException] с ошибками по полям.
  void validate(T candidate, List<T> others) {}

  /// Проверка перед удалением. Бросает [ConflictException].
  Future<void> checkDeletable(T item, {required bool hard}) async {}

  // ---- общая логика ----

  /// Небольшая задержка имитирует сеть: без неё индикатор загрузки
  /// невозможно увидеть, а при подключении сервера он понадобится по-настоящему.
  Future<void> _simulateNetwork() async {
    await Future.delayed(_dev?.delay ?? Duration.zero);
    if (_dev?.failing ?? false) {
      throw const RepositoryException('сервер недоступен (имитация сбоя)');
    }
  }

  Future<void> _commit() async {
    await _store?.save(_items);
    _changes.ping();
  }

  int _indexOf(int id) => _items.indexWhere((e) => idOf(e) == id);

  List<T> _others(int? exceptId) => [
    for (final e in _items)
      if (!isDeletedItem(e) && idOf(e) != exceptId) e,
  ];

  @override
  Future<PageResult<T>> find(Q q) async {
    await _simulateNetwork();

    final rows = _items
        .where((e) => (q.includeDeleted || !isDeletedItem(e)) && matches(e, q))
        .toList();

    rows.sort((a, b) {
      final result = compare(a, b, q);
      // При равенстве ключей порядок задаёт id, иначе строки «прыгают».
      final ordered = result != 0 ? result : idOf(a).compareTo(idOf(b));
      return q.sortAscending ? ordered : -ordered;
    });

    final total = rows.length;
    final from = (q.page - 1) * q.size;
    // num.clamp возвращает num, а не int, и в sublist его передать нельзя,
    // поэтому верхнюю границу считаем явно.
    final to = (from + q.size) > total ? total : (from + q.size);
    final items = from >= total ? <T>[] : rows.sublist(from, to);
    return PageResult(items: items, page: q.page, size: q.size, total: total);
  }

  @override
  Future<T?> findById(int id) async {
    await _simulateNetwork();
    final i = _indexOf(id);
    return i == -1 ? null : _items[i];
  }

  @override
  Future<List<T>> findAll() async {
    // Справочное чтение для подписей и списков выбора: без имитации сети.
    return List.unmodifiable(_items);
  }

  @override
  Future<T> create(T item) async {
    await _simulateNetwork();
    validate(item, _others(null));
    final nextId = _items.fold<int>(0, (m, e) => idOf(e) > m ? idOf(e) : m) + 1;
    final created = withId(item, nextId);
    _items.add(created);
    await _commit();
    return created;
  }

  @override
  Future<T> update(T item) async {
    await _simulateNetwork();
    final i = _indexOf(idOf(item));
    if (i == -1) throw RepositoryException(notFound(idOf(item)));
    validate(item, _others(idOf(item)));
    _items[i] = item;
    await _commit();
    return item;
  }

  @override
  Future<void> softDelete(int id) async {
    await _simulateNetwork();
    final i = _indexOf(id);
    if (i == -1) throw RepositoryException(notFound(id));
    await checkDeletable(_items[i], hard: false);
    _items[i] = withDeleted(_items[i], DateTime.now());
    await _commit();
  }

  @override
  Future<void> hardDelete(int id) async {
    await _simulateNetwork();
    final i = _indexOf(id);
    if (i == -1) return;
    await checkDeletable(_items[i], hard: true);
    _items.removeAt(i);
    await _commit();
  }

  @override
  Future<void> restore(int id) async {
    await _simulateNetwork();
    final i = _indexOf(id);
    if (i == -1) throw RepositoryException(notFound(id));
    final restored = withDeleted(_items[i], null);
    try {
      validate(restored, _others(id));
    } on ValidationException catch (e) {
      throw ConflictException(
        'Нельзя восстановить запись: ${e.errors.values.first}',
      );
    }
    _items[i] = restored;
    await _commit();
  }

  @override
  Future<int> deleteMany(List<int> ids) async {
    await _simulateNetwork();
    var count = 0;
    for (final id in ids) {
      final i = _indexOf(id);
      if (i == -1 || isDeletedItem(_items[i])) continue;
      try {
        await checkDeletable(_items[i], hard: false);
      } on ConflictException {
        continue; // защищённые связями записи пропускаются
      }
      _items[i] = withDeleted(_items[i], DateTime.now());
      count++;
    }
    if (count > 0) await _commit();
    return count;
  }
}

class _Changes extends ChangeNotifier {
  void ping() => notifyListeners();
}
