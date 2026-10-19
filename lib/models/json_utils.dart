/// Устойчивый разбор данных из внешнего источника (хранилище, сервер).
/// Поля может не быть, оно может оказаться null или другого типа,
/// поэтому все функции возвращают значение по умолчанию, а не бросают исключение.
int intOf(Object? value, [int fallback = 0]) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}

String stringOf(Object? value, [String fallback = '']) {
  if (value is String) return value;
  if (value == null) return fallback;
  return '$value';
}

List<int> intListOf(Object? value) {
  if (value is! List) return const [];
  return [
    for (final e in value)
      if (e is num)
        e.toInt()
      else if (e is String && int.tryParse(e) != null)
        int.parse(e),
  ];
}

DateTime? dateOf(Object? value) =>
    value is String ? DateTime.tryParse(value) : null;

Map<String, dynamic> mapOf(Object? value) =>
    value is Map ? Map<String, dynamic>.from(value) : const {};
