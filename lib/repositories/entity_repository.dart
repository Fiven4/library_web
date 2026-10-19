import 'package:flutter/foundation.dart';

import '../models/page_result.dart';

class RepositoryException implements Exception {
  final String message;
  const RepositoryException(this.message);

  @override
  String toString() => message;
}

/// Нарушено ограничение целостности (аналог ответа 409 сервера):
/// например, удаляется издательство, на которое ссылаются книги.
class ConflictException extends RepositoryException {
  const ConflictException(super.message);
}

/// Ошибки валидации по полям (аналог ответа 422 сервера). Ключи совпадают
/// с именами полей формы, поэтому ошибку можно показать прямо в поле.
class ValidationException extends RepositoryException {
  final Map<String, String> errors;

  ValidationException(this.errors) : super('Ошибка валидации');
}

/// Операции над одной записью, общие для всех сущностей.
abstract interface class RecordStore<T> {
  /// Возвращает запись, в том числе логически удалённую:
  /// карточку удалённой записи нужно уметь открыть.
  Future<T?> findById(int id);

  /// Все записи, включая удалённые. Нужны для подписей и выпадающих списков.
  Future<List<T>> findAll();

  /// Создаёт запись; идентификатор присваивает хранилище.
  /// Может бросить [ValidationException].
  Future<T> create(T item);

  /// Изменяет запись. Может бросить [ValidationException].
  Future<T> update(T item);

  /// Логическое удаление: проставляет deletedAt.
  /// Может бросить [ConflictException].
  Future<void> softDelete(int id);

  /// Физическое удаление: запись стирается насовсем.
  /// Может бросить [ConflictException].
  Future<void> hardDelete(int id);

  /// Восстановление логически удалённой записи.
  Future<void> restore(int id);

  /// Логическое удаление нескольких записей. Возвращает число
  /// действительно удалённых (уже удалённые и защищённые связями
  /// пропускаются).
  Future<int> deleteMany(List<int> ids);
}

/// Хранилище с поиском по условиям [Q] и постраничной выдачей.
abstract interface class EntityRepository<T, Q> implements RecordStore<T> {
  Future<PageResult<T>> find(Q query);

  /// Оповещает об изменении данных (создание, правка, удаление).
  Listenable get changes;
}
