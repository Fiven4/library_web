import 'package:flutter/foundation.dart';

import '../models/page_result.dart';

export '../core/api_exceptions.dart';

abstract interface class RecordStore<T> {
  Future<T?> findById(int id);

  Future<List<T>> findAll();

  Future<T> create(T item);

  Future<T> update(T item);

  Future<void> softDelete(int id);

  Future<void> hardDelete(int id);

  Future<void> restore(int id);

  Future<int> deleteMany(List<int> ids);
}

abstract interface class EntityRepository<T, Q> implements RecordStore<T> {
  Future<PageResult<T>> find(Q query);

  Listenable get changes;
}
