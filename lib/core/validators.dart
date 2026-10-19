/// Переиспользуемые валидаторы полей. Функция возвращает текст ошибки
/// или null, если значение корректно (пустая строка ошибкой не считается).
typedef Validator = String? Function(String? value);

class V {
  V._();

  static final _currentYear = DateTime.now().year;

  /// Поле обязательно для заполнения.
  static Validator required([String message = 'Поле обязательно']) =>
      (value) => (value == null || value.trim().isEmpty) ? message : null;

  /// Длина строки в заданных границах. Пустое значение пропускается:
  /// обязательность проверяет [required].
  static Validator length({int min = 0, int max = 255}) => (value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    if (text.length < min) return 'Не короче $min символов';
    if (text.length > max) return 'Не длиннее $max символов';
    return null;
  };

  /// Целое число в заданных границах.
  static Validator integer({int? min, int? max}) => (value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    final n = int.tryParse(text);
    if (n == null) return 'Введите целое число';
    if (min != null && n < min) return 'Значение не меньше $min';
    if (max != null && n > max) return 'Значение не больше $max';
    return null;
  };

  /// Положительное целое (количества).
  static Validator positive({int max = 100000}) => (value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    final n = int.tryParse(text);
    if (n == null) return 'Введите целое число';
    if (n <= 0) return 'Значение должно быть больше нуля';
    if (n > max) return 'Значение не больше $max';
    return null;
  };

  /// Год не позже текущего.
  static Validator year({int min = 1000}) =>
      integer(min: min, max: _currentYear);

  static final _email = RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$');

  /// Адрес электронной почты.
  static Validator email() => (value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    return _email.hasMatch(text) ? null : 'Некорректный адрес почты';
  };

  static final _phone = RegExp(r'^\+?[0-9][0-9 ()\-]{6,19}$');

  /// Телефон: цифры, пробелы, скобки и дефисы, необязательный плюс.
  static Validator phone() => (value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    return _phone.hasMatch(text) ? null : 'Формат: +7 900 000-00-00';
  };

  static final _isbn = RegExp(r'^97[89]-?\d{1,5}-?\d{1,7}-?\d{1,7}-?\d$');

  /// ISBN-13, дефисы необязательны.
  static Validator isbn() => (value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    if (!_isbn.hasMatch(text)) return 'Формат: 978-5-17-118366-4';
    final digits = text.replaceAll('-', '');
    return digits.length == 13 ? null : 'В ISBN-13 должно быть 13 цифр';
  };

  static final _card = RegExp(r'^RC-\d{6}$');

  /// Номер читательского билета.
  static Validator cardNumber() => (value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    return _card.hasMatch(text) ? null : 'Формат: RC-000001';
  };

  /// Дата в формате ГГГГ-ММ-ДД.
  static Validator date() => (value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    final m = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(text);
    if (m == null) return 'Формат даты: 2026-01-31';
    final y = int.parse(m[1]!), mo = int.parse(m[2]!), d = int.parse(m[3]!);
    // Несуществующие даты (13-й месяц, 31 февраля) сдвигаются при создании.
    final date = DateTime(y, mo, d);
    final ok = date.year == y && date.month == mo && date.day == d;
    return ok ? null : 'Такой даты не существует';
  };

  /// Объединение проверок: возвращается первая сработавшая ошибка.
  static Validator combine(List<Validator> validators) => (value) {
    for (final v in validators) {
      final error = v(value);
      if (error != null) return error;
    }
    return null;
  };
}

/// Нормализация ISBN и почты для проверки уникальности:
/// без дефисов, пробелов и различий регистра.
String normalizeIsbn(String value) =>
    value.replaceAll(RegExp(r'[\s-]'), '').toLowerCase();

String normalizeEmail(String value) => value.trim().toLowerCase();
