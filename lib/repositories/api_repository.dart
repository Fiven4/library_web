import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../models/list_query.dart';
import '../models/page_result.dart';
import 'entity_repository.dart';

class _RepoChanges extends ChangeNotifier {
  void notify() => notifyListeners();
}

abstract class ApiRepository<T, Q extends ListQuery<Q>>
    implements EntityRepository<T, Q> {
  final Dio dio;
  final String path;
  final T Function(Map<String, dynamic> json) fromJson;
  final Map<String, dynamic> Function(T item) toJson;
  final int Function(T item) idOf;

  ApiRepository({
    required this.dio,
    required this.path,
    required this.fromJson,
    required this.toJson,
    required this.idOf,
  });

  final _RepoChanges _changes = _RepoChanges();
  CancelToken? _activeCancelToken;
  List<T>? _cachedAll;

  @override
  Listenable get changes => _changes;

  void invalidateCache() {
    _cachedAll = null;
    _changes.notify();
  }

  Map<String, dynamic> buildQueryParams(Q q) {
    return <String, dynamic>{
      ...q.toParams(),
      'page': q.page,
      'size': q.size,
      'sort': '${q.sortField},${q.sortAscending ? 'asc' : 'desc'}',
    };
  }

  @override
  Future<PageResult<T>> find(Q query) async {
    // Отмена устаревших запросов через CancelToken при быстром вводе поиска
    _activeCancelToken?.cancel('superseded');
    final cancelToken = CancelToken();
    _activeCancelToken = cancelToken;

    return guard(() async {
      final response = await dio.get(
        path,
        queryParameters: buildQueryParams(query),
        cancelToken: cancelToken,
      );

      final data = response.data as Map<String, dynamic>;
      final itemsRaw = data['items'] as List? ?? const [];
      final items = itemsRaw
          .whereType<Map<String, dynamic>>()
          .map(fromJson)
          .toList();

      return PageResult(
        items: items,
        page: data['page'] as int? ?? query.page,
        size: data['size'] as int? ?? query.size,
        total: data['total'] as int? ?? items.length,
      );
    });
  }

  @override
  Future<T?> findById(int id) => guard(() async {
    try {
      final response = await dio.get('$path/$id');
      return fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404 || e.error is NotFoundException) {
        return null;
      }
      rethrow;
    }
  });

  @override
  Future<List<T>> findAll() async {
    // Кэширование справочников: запрашиваются один раз и не перезагружаются при каждом открытии
    if (_cachedAll != null) return _cachedAll!;

    return guard(() async {
      final response = await dio.get(
        path,
        queryParameters: {'size': 100, 'includeDeleted': false},
      );
      final data = response.data as Map<String, dynamic>;
      final itemsRaw = data['items'] as List? ?? const [];
      final items = itemsRaw
          .whereType<Map<String, dynamic>>()
          .map(fromJson)
          .toList();

      _cachedAll = items;
      return items;
    });
  }

  @override
  Future<T> create(T item) => guard(() async {
    final response = await dio.post(path, data: toJson(item));
    invalidateCache();
    return fromJson(response.data as Map<String, dynamic>);
  });

  @override
  Future<T> update(T item) => guard(() async {
    final response = await dio.put('$path/${idOf(item)}', data: toJson(item));
    invalidateCache();
    return fromJson(response.data as Map<String, dynamic>);
  });

  @override
  Future<void> softDelete(int id) => guard(() async {
    await dio.delete('$path/$id');
    invalidateCache();
  });

  @override
  Future<void> hardDelete(int id) => guard(() async {
    await dio.delete('$path/$id', queryParameters: {'hard': true});
    invalidateCache();
  });

  @override
  Future<void> restore(int id) => guard(() async {
    await dio.post('$path/$id/restore');
    invalidateCache();
  });

  @override
  Future<int> deleteMany(List<int> ids) => guard(() async {
    final response = await dio.post('$path/bulk-delete', data: {'ids': ids});
    invalidateCache();
    final data = response.data as Map<String, dynamic>;
    return data['deleted'] as int? ?? 0;
  });
}
