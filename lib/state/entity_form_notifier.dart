import 'package:flutter/foundation.dart';

import '../repositories/entity_repository.dart';
import 'load_status.dart';

/// Состояние формы создания и изменения записи. Один класс обслуживает
/// любую сущность: при [id] == null запись создаётся, иначе изменяется.
class EntityFormNotifier<T> extends ChangeNotifier {
  EntityFormNotifier(this._store, this.id);

  final RecordStore<T> _store;
  final int? id;

  T? _item;
  LoadStatus _status = LoadStatus.idle;
  String? _error;
  Map<String, String> _fieldErrors = const {};
  bool _saving = false;
  bool _disposed = false;

  bool get isEditing => id != null;
  T? get item => _item;
  LoadStatus get status => _status;

  /// Общая ошибка (не относящаяся к конкретному полю).
  String? get error => _error;

  /// Ошибки сервера по полям, например «ISBN уже существует».
  Map<String, String> get fieldErrors => _fieldErrors;
  bool get saving => _saving;

  /// Редактируемая запись не найдена (адрес набран вручную).
  bool get notFound =>
      isEditing && _status == LoadStatus.success && _item == null;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void _safeNotify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> load() async {
    if (!isEditing) {
      _status = LoadStatus.success;
      _safeNotify();
      return;
    }
    _status = LoadStatus.loading;
    _safeNotify();
    try {
      _item = await _store.findById(id!);
      _status = LoadStatus.success;
    } catch (e) {
      _error = 'Не удалось загрузить запись: $e';
      _status = LoadStatus.error;
    }
    _safeNotify();
  }

  /// Забывает ошибку поля: она относилась к прежнему значению.
  void clearFieldError(String key) {
    if (_fieldErrors.containsKey(key)) {
      _fieldErrors = {..._fieldErrors}..remove(key);
      _safeNotify();
    }
  }

  /// Сохраняет запись. Возвращает сохранённую запись или null при ошибке;
  /// ошибки по полям доступны в [fieldErrors], остальные в [error].
  Future<T?> submit(T entity) async {
    _saving = true;
    _error = null;
    _fieldErrors = const {};
    _safeNotify();
    try {
      final saved = isEditing
          ? await _store.update(entity)
          : await _store.create(entity);
      _saving = false;
      _safeNotify();
      return saved;
    } on ValidationException catch (e) {
      _fieldErrors = e.errors;
    } on RepositoryException catch (e) {
      _error = 'Не удалось сохранить: ${e.message}';
    } catch (e) {
      _error = 'Не удалось сохранить: $e';
    }
    _saving = false;
    _safeNotify();
    return null;
  }
}
