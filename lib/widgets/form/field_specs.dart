import 'package:flutter/services.dart';

import '../../core/validators.dart';

/// Значения полей формы по ключам. Типы: текст и дата — String, выпадающий
/// список — `int?`, множественный выбор — `List<int>`, переключатель — bool.
typedef FormValues = Map<String, Object?>;

/// Вариант выбора: идентификатор и подпись.
typedef Option = (int id, String label);

/// Проверка текстового поля. Вторым параметром приходят значения всех полей:
/// так задаются проверки, зависящие от нескольких полей сразу.
typedef TextValidator = String? Function(String? value, FormValues values);

/// Описание поля формы. Форма сущности — это список таких описаний,
/// а один общий виджет умеет их отображать, проверять и отправлять.
sealed class FieldSpec {
  const FieldSpec();
}

/// Адаптер: обычный валидатор из validators.dart как проверка поля формы.
TextValidator plain(Validator v) =>
    (value, _) => v(value);

class TextSpec extends FieldSpec {
  final String key;
  final String label;
  final bool required;
  final TextValidator? validator;
  final TextInputType? keyboard;
  final int maxLines;
  final String? hint;
  final bool digitsOnly;

  const TextSpec({
    required this.key,
    required this.label,
    this.required = false,
    this.validator,
    this.keyboard,
    this.maxLines = 1,
    this.hint,
    this.digitsOnly = false,
  });

  List<TextInputFormatter>? get formatters =>
      digitsOnly ? [FilteringTextInputFormatter.digitsOnly] : null;
}

/// Дата в виде текста ГГГГ-ММ-ДД с кнопкой выбора в календаре.
class DateSpec extends FieldSpec {
  final String key;
  final String label;
  final bool required;
  final TextValidator? validator;

  const DateSpec({
    required this.key,
    required this.label,
    this.required = false,
    this.validator,
  });
}

/// Связь «многие к одному»: выпадающий список. Значение — идентификатор.
class DropdownSpec extends FieldSpec {
  final String key;
  final String label;
  final bool required;
  final String? requiredMessage;
  final List<Option> Function(FormValues values) options;

  const DropdownSpec({
    required this.key,
    required this.label,
    required this.options,
    this.required = false,
    this.requiredMessage,
  });
}

/// Связь «многие ко многим»: множественный выбор набором FilterChip.
class MultiSpec extends FieldSpec {
  final String key;
  final String label;
  final bool required;
  final String? requiredMessage;
  final String? helper;
  final List<Option> Function(FormValues values) options;

  const MultiSpec({
    required this.key,
    required this.label,
    required this.options,
    this.required = false,
    this.requiredMessage,
    this.helper,
  });
}

class SwitchSpec extends FieldSpec {
  final String key;
  final String label;

  const SwitchSpec({required this.key, required this.label});
}

/// Вложенная группа полей (связь «один к одному»: билет читателя).
class GroupSpec extends FieldSpec {
  final String title;
  final List<FieldSpec> fields;

  const GroupSpec({required this.title, required this.fields});
}

/// Ключи всех полей описания, включая вложенные группы.
Iterable<String> keysOf(List<FieldSpec> specs) sync* {
  for (final s in specs) {
    switch (s) {
      case TextSpec(:final key) ||
          DateSpec(:final key) ||
          DropdownSpec(:final key) ||
          MultiSpec(:final key) ||
          SwitchSpec(:final key):
        yield key;
      case GroupSpec(:final fields):
        yield* keysOf(fields);
    }
  }
}
