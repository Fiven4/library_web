import '../models/page_result.dart';

class RepositoryException implements Exception {
  final String message;
  const RepositoryException(this.message);

  @override
  String toString() => message;
}

/// Операции над одной записью, общие для всех сущностей.
abstract interface class RecordStore<T> {
  /// Возвращает запись, в том числе логически удалённую:
  /// карточку удалённой записи нужно уметь открыть.
  Future<T?> findById(int id);

  /// Логическое удаление: проставляет deletedAt.
  Future<void> softDelete(int id);

  /// Физическое удаление: запись стирается насовсем.
  Future<void> hardDelete(int id);

  /// Восстановление логически удалённой записи.
  Future<void> restore(int id);

  /// Логическое удаление нескольких записей. Возвращает число
  /// действительно удалённых (уже удалённые не считаются).
  Future<int> deleteMany(List<int> ids);
}

/// Хранилище с поиском по условиям [Q] и постраничной выдачей.
abstract interface class EntityRepository<T, Q> implements RecordStore<T> {
  Future<PageResult<T>> find(Q query);
}
