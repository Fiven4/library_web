import 'package:flutter_test/flutter_test.dart';
import 'package:library_web/core/validators.dart';

void main() {
  group('обязательность и длина', () {
    test('required отклоняет пустое и пробельное значение', () {
      final v = V.required('Укажите');
      expect(v(null), 'Укажите');
      expect(v('   '), 'Укажите');
      expect(v('x'), isNull);
    });

    test('length проверяет границы и пропускает пустое значение', () {
      final v = V.length(min: 2, max: 5);
      expect(v('a'), isNotNull);
      expect(v('abcdef'), isNotNull);
      expect(v('abc'), isNull);
      expect(v(''), isNull);
    });

    test('combine возвращает первую сработавшую ошибку', () {
      final v = V.combine([V.required('пусто'), V.length(min: 3)]);
      expect(v(''), 'пусто');
      expect(v('ab'), 'Не короче 3 символов');
      expect(v('abc'), isNull);
    });
  });

  group('числа', () {
    test('integer: формат и диапазон', () {
      final v = V.integer(min: 1, max: 10);
      expect(v('abc'), 'Введите целое число');
      expect(v('0'), 'Значение не меньше 1');
      expect(v('11'), 'Значение не больше 10');
      expect(v('5'), isNull);
    });

    test('positive отклоняет ноль и отрицательные', () {
      final v = V.positive(max: 100);
      expect(v('0'), isNotNull);
      expect(v('-3'), isNotNull);
      expect(v('101'), isNotNull);
      expect(v('7'), isNull);
    });

    test('year не принимает будущий год', () {
      final v = V.year(min: 1450);
      expect(v('${DateTime.now().year + 1}'), isNotNull);
      expect(v('1000'), isNotNull);
      expect(v('1869'), isNull);
    });
  });

  group('форматы', () {
    test('email', () {
      final v = V.email();
      expect(v('abc'), 'Некорректный адрес почты');
      expect(v('a@b'), isNotNull);
      expect(v('ivanov@example.com'), isNull);
    });

    test('phone: пустой допустим, мусор нет', () {
      final v = V.phone();
      expect(v(''), isNull);
      expect(v('+7 900 100-10-01'), isNull);
      expect(v('телефон'), isNotNull);
      expect(v('12'), isNotNull);
    });

    test('isbn: допускает дефисы и проверяет число цифр', () {
      final v = V.isbn();
      expect(v('978-5-17-118366-4'), isNull);
      expect(v('9785171183664'), isNull);
      expect(v('123'), isNotNull);
      expect(v('978-5-17-118366-44'), isNotNull);
    });

    test('номер билета и дата', () {
      expect(V.cardNumber()('RC-000123'), isNull);
      expect(V.cardNumber()('RC-12'), isNotNull);
      expect(V.date()('2026-01-31'), isNull);
      expect(V.date()('31.01.2026'), isNotNull);
      expect(V.date()('2026-13-45'), isNotNull);
    });
  });

  test('нормализация для проверки уникальности', () {
    expect(normalizeIsbn('978-5-17-118366-4'), normalizeIsbn('9785171183664'));
    expect(normalizeEmail(' Ivanov@Example.COM '), 'ivanov@example.com');
  });
}
