import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:library_web/data/seed_data.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers.dart';

Finder field(String key) => find.byKey(ValueKey('field-$key'));

/// Прокручивает форму так, чтобы элемент оказался в центре видимой области.
Future<void> reveal(WidgetTester t, Finder target) async {
  await Scrollable.ensureVisible(
    t.element(target),
    alignment: 0.5,
    duration: Duration.zero,
  );
  await t.pumpAndSettle();
}

Future<void> type(WidgetTester t, String key, String text) async {
  await t.enterText(field(key), text);
  await t.pump();
}

/// Нажимает «Создать»/«Сохранить». Вызов обработчика напрямую надёжнее
/// нажатия по координатам: кнопка лежит в самом низу прокручиваемой формы.
Future<void> submit(WidgetTester t) async {
  final button = t.widget<FilledButton>(
    find.byKey(const ValueKey('submit-button')),
  );
  button.onPressed!();
  await t.pumpAndSettle();
}

Future<void> choose(WidgetTester t, Finder dropdown, String label) async {
  await reveal(t, dropdown);
  await t.tap(dropdown);
  await t.pumpAndSettle();
  await t.tap(find.text(label).last);
  await t.pumpAndSettle();
}

Future<void> fillValidBook(
  WidgetTester t, {
  String isbn = '978-5-00-000000-0',
}) async {
  await type(t, 'title', 'Тестовая книга');
  await type(t, 'isbn', isbn);
  await type(t, 'year', '2020');
  await type(t, 'pages', '300');
  await type(t, 'copiesTotal', '5');
  await choose(t, find.byType(DropdownButtonFormField<int>), 'Азбука');
  final chip = find.byKey(const ValueKey('chip-genreIds-1'));
  await reveal(t, chip);
  await t.tap(chip);
  await t.pump();
}

void main() {
  group('форма книги', () {
    testWidgets('пустая отправка: ошибки под полями, форма остаётся открытой', (
      t,
    ) async {
      final router = await pumpApp(t, location: '/books/new');
      await submit(t);

      for (final message in [
        'Укажите название',
        'Укажите ISBN',
        'Укажите год',
        'Укажите число страниц',
        'Выберите издательство',
        'Выберите хотя бы один жанр',
        'Укажите количество',
      ]) {
        expect(find.text(message), findsOneWidget, reason: message);
      }
      expect(currentUri(router).path, '/books/new');
    });

    testWidgets('нетронутые поля не показывают ошибок до отправки формы', (
      t,
    ) async {
      await pumpApp(t, location: '/books/new');
      await type(t, 'title', 'Черновик');
      expect(find.text('Укажите ISBN'), findsNothing);
      expect(find.text('Выберите хотя бы один жанр'), findsNothing);
      await submit(t);
      expect(find.text('Укажите ISBN'), findsOneWidget);
    });

    testWidgets('форматы и диапазоны проверяются по каждому полю', (t) async {
      await pumpApp(t, location: '/books/new');
      await type(t, 'title', 'А');
      await type(t, 'isbn', '123');
      await type(t, 'year', '${DateTime.now().year + 5}');
      await type(t, 'pages', '0');
      await type(t, 'copiesTotal', '-2');
      await submit(t);

      expect(find.text('Не короче 2 символов'), findsOneWidget);
      expect(find.text('Формат: 978-5-17-118366-4'), findsOneWidget);
      expect(find.textContaining('Значение не больше'), findsOneWidget);
      expect(find.text('Значение не меньше 1'), findsOneWidget);
      expect(find.text('Значение должно быть больше нуля'), findsOneWidget);
    });

    testWidgets('корректная форма создаёт книгу и возвращает к списку', (
      t,
    ) async {
      final router = await pumpApp(t, location: '/books/new');
      await fillValidBook(t);
      await submit(t);

      expect(currentUri(router).path, '/books');
      expect(find.text('Запись создана'), findsOneWidget);
      expect(find.textContaining('всего записей: 37'), findsOneWidget);
    });

    testWidgets(
      'дубликат ISBN даёт ошибку в поле ISBN и пропадает при правке',
      (t) async {
        final router = await pumpApp(t, location: '/books/new');
        await fillValidBook(t, isbn: seedBooks.first.isbn);
        await submit(t);

        expect(find.text('Книга с таким ISBN уже существует'), findsOneWidget);
        expect(currentUri(router).path, '/books/new');

        await type(t, 'isbn', '978-5-00-111111-1');
        expect(find.text('Книга с таким ISBN уже существует'), findsNothing);
        await submit(t);
        expect(currentUri(router).path, '/books');
      },
    );

    testWidgets(
      'форма изменения открывается заполненной, один экран на оба случая',
      (t) async {
        await pumpApp(t, location: '/books/1/edit');
        final title = t.widget<TextFormField>(field('title'));
        expect(title.controller!.text, 'Война и мир');
        expect(
          t.widget<TextFormField>(field('isbn')).controller!.text,
          seedBooks.first.isbn,
        );
        expect(find.text('Изменение: Война и мир'), findsOneWidget);
        expect(find.text('Сохранить'), findsOneWidget);
        // выбранные значения связей на месте
        final chip = t.widget<FilterChip>(
          find.byKey(const ValueKey('chip-authorIds-1')),
        );
        expect(chip.selected, isTrue);
        expect(find.text('Доступно экземпляров *'), findsOneWidget);
      },
    );

    testWidgets('сохранение изменений обновляет запись', (t) async {
      final router = await pumpApp(t, location: '/books/1/edit');
      await type(t, 'title', 'Война и мир (новое издание)');
      await submit(t);
      expect(find.text('Изменения сохранены'), findsOneWidget);
      expect(currentUri(router).path, '/books');

      router.go('/books/1');
      await t.pumpAndSettle();
      expect(find.text('Война и мир (новое издание)'), findsWidgets);
    });

    testWidgets('доступных экземпляров не может быть больше, чем всего', (
      t,
    ) async {
      await pumpApp(t, location: '/books/1/edit');
      await type(t, 'copiesAvailable', '99');
      await submit(t);
      expect(
        find.text('Не больше общего числа экземпляров (4)'),
        findsOneWidget,
      );
    });
  });

  group('несохранённые изменения', () {
    testWidgets('при изменённых полях выход требует подтверждения', (t) async {
      final router = await pumpApp(t, location: '/books/new');
      await type(t, 'title', 'Черновик');

      await t.tap(find.byKey(const ValueKey('back-button')));
      await t.pumpAndSettle();
      expect(find.text('Несохранённые изменения'), findsOneWidget);

      await t.tap(find.byKey(const ValueKey('stay')));
      await t.pumpAndSettle();
      expect(currentUri(router).path, '/books/new');
      expect(
        t.widget<TextFormField>(field('title')).controller!.text,
        'Черновик',
      );

      await t.tap(find.byKey(const ValueKey('back-button')));
      await t.pumpAndSettle();
      await t.tap(find.byKey(const ValueKey('leave')));
      await t.pumpAndSettle();
      expect(currentUri(router).path, '/books');
    });

    testWidgets('без правок выход происходит сразу', (t) async {
      final router = await pumpApp(t, location: '/books/new');
      await reveal(t, find.byKey(const ValueKey('cancel-button')));
      await t.pumpAndSettle();
      await t.tap(find.byKey(const ValueKey('cancel-button')));
      await t.pumpAndSettle();
      expect(find.text('Несохранённые изменения'), findsNothing);
      expect(currentUri(router).path, '/books');
    });

    testWidgets('возврат значения к исходному снимает предупреждение', (
      t,
    ) async {
      await pumpApp(t, location: '/books/1/edit');
      await type(t, 'title', 'Другое');
      await type(t, 'title', 'Война и мир');
      await reveal(t, find.byKey(const ValueKey('cancel-button')));
      await t.pumpAndSettle();
      await t.tap(find.byKey(const ValueKey('cancel-button')));
      await t.pumpAndSettle();
      expect(find.text('Несохранённые изменения'), findsNothing);
    });
  });

  group('связи в форме книги', () {
    testWidgets('после выбора издательства список авторов сужается', (t) async {
      await pumpApp(t, location: '/books/new');
      // до выбора издательства доступны все авторы
      expect(find.byKey(const ValueKey('chip-authorIds-1')), findsOneWidget);
      expect(find.byKey(const ValueKey('chip-authorIds-2')), findsOneWidget);

      await choose(t, find.byType(DropdownButtonFormField<int>), 'Азбука');
      // «Азбука» издаёт только Достоевского
      expect(find.byKey(const ValueKey('chip-authorIds-2')), findsOneWidget);
      expect(find.byKey(const ValueKey('chip-authorIds-1')), findsNothing);

      // переключатель показывает всех авторов
      final toggle = find.byKey(const ValueKey('switch-narrowAuthors'));
      await reveal(t, toggle);
      await t.tap(toggle);
      await t.pumpAndSettle();
      expect(find.byKey(const ValueKey('chip-authorIds-1')), findsOneWidget);
    });

    testWidgets(
      'жанр, добавленный в справочник, сразу доступен в форме книги',
      (t) async {
        final prefs = await _prefs();
        await pumpApp(t, location: '/genres/new', prefs: prefs);
        await type(t, 'name', 'Киберпанк');
        await submit(t);

        await pumpApp(t, location: '/books/new', prefs: prefs);
        expect(find.text('Киберпанк'), findsOneWidget);
      },
    );
  });

  group('издательство, жанр и автор со связанными книгами', () {
    testWidgets('удалить издательство с книгами нельзя: сообщение с числом', (
      t,
    ) async {
      await pumpApp(t, location: '/publishers');
      // первая строка по алфавиту — «Азбука»
      await t.tap(find.byTooltip('Действия').first);
      await t.pumpAndSettle();
      await t.tap(find.text('Удалить').last);
      await t.pumpAndSettle();
      await t.tap(find.widgetWithText(FilledButton, 'Удалить'));
      await t.pumpAndSettle();

      final linked = seedBooks.where((b) => b.publisherId == 3).length;
      expect(find.byKey(const ValueKey('conflict-dialog')), findsOneWidget);
      expect(find.text('Удаление невозможно'), findsOneWidget);
      expect(
        find.textContaining('на него ссылаются книги ($linked)'),
        findsOneWidget,
      );

      await t.tap(find.text('Понятно'));
      await t.pumpAndSettle();
      expect(find.text('Азбука'), findsOneWidget); // запись на месте
    });

    testWidgets('то же из карточки издательства', (t) async {
      await pumpApp(t, location: '/publishers/1');
      // Кнопка лежит под длинным списком книг: вызываем обработчик напрямую.
      t
          .widget<OutlinedButton>(find.byKey(const ValueKey('detail-delete')))
          .onPressed!();
      await t.pumpAndSettle();
      await t.tap(find.widgetWithText(FilledButton, 'Удалить'));
      await t.pumpAndSettle();
      expect(find.byKey(const ValueKey('conflict-dialog')), findsOneWidget);
    });

    testWidgets('групповое удаление сообщает, сколько записей не удалено', (
      t,
    ) async {
      await pumpApp(t, location: '/genres');
      await t.tap(find.byType(Checkbox).at(1));
      await t.pump();
      await t.tap(find.byKey(const ValueKey('delete-selected')));
      await t.pumpAndSettle();
      await t.tap(find.textContaining('Удалить (1)'));
      await t.pumpAndSettle();
      expect(find.textContaining('Не удалено: 1'), findsOneWidget);
    });
  });

  group('читатель с билетом', () {
    testWidgets('форма содержит вложенную группу полей билета', (t) async {
      await pumpApp(t, location: '/readers/new');
      expect(find.text('Читательский билет'), findsOneWidget);
      expect(field('card.number'), findsOneWidget);
      expect(field('card.issuedAt'), findsOneWidget);
      expect(field('card.expiresAt'), findsOneWidget);
      // даты предзаполнены: выдача сегодня, срок через год
      final issued = t
          .widget<TextFormField>(field('card.issuedAt'))
          .controller!
          .text;
      expect(DateTime.tryParse(issued), isNotNull);
    });

    testWidgets('пустая форма: ошибки полей читателя и билета', (t) async {
      await pumpApp(t, location: '/readers/new');
      await submit(t);
      expect(find.text('Укажите ФИО'), findsOneWidget);
      expect(find.text('Укажите почту'), findsOneWidget);
      expect(find.text('Укажите номер билета'), findsOneWidget);
    });

    testWidgets('формат почты, телефона и номера билета', (t) async {
      await pumpApp(t, location: '/readers/new');
      await type(t, 'fullName', 'Тестов Т. Т.');
      await type(t, 'email', 'не-почта');
      await type(t, 'phone', 'abc');
      await type(t, 'card.number', 'RC-12');
      await submit(t);
      expect(find.text('Некорректный адрес почты'), findsOneWidget);
      expect(find.text('Формат: +7 900 000-00-00'), findsOneWidget);
      expect(find.text('Формат: RC-000001'), findsOneWidget);
    });

    testWidgets('срок действия должен быть позже даты выдачи', (t) async {
      await pumpApp(t, location: '/readers/new');
      await type(t, 'card.issuedAt', '2026-05-01');
      await type(t, 'card.expiresAt', '2026-04-01');
      await submit(t);
      expect(
        find.text('Срок действия должен быть позже даты выдачи'),
        findsOneWidget,
      );
    });

    testWidgets('дубликат почты и номера билета показывается в своих полях', (
      t,
    ) async {
      await pumpApp(t, location: '/readers/new');
      await type(t, 'fullName', 'Тестов Т. Т.');
      await type(t, 'email', 'popov@example.com');
      await type(t, 'card.number', 'RC-000001');
      await submit(t);
      expect(
        find.text('Читатель с такой почтой уже зарегистрирован'),
        findsOneWidget,
      );
      expect(find.text('Билет с таким номером уже выдан'), findsOneWidget);
    });

    testWidgets('читатель с билетом создаётся и открывается карточка', (
      t,
    ) async {
      final router = await pumpApp(t, location: '/readers/new');
      await type(t, 'fullName', 'Тестов Т. Т.');
      await type(t, 'email', 'testov@example.com');
      await type(t, 'card.number', 'RC-000050');
      await submit(t);
      expect(currentUri(router).path, '/readers');

      router.go('/readers/7');
      await t.pumpAndSettle();
      expect(find.text('RC-000050'), findsOneWidget);
      expect(find.text('testov@example.com'), findsOneWidget);
    });
  });

  group('остальные сущности', () {
    testWidgets('списки жанров, издательств и читателей открываются', (
      t,
    ) async {
      await pumpApp(t, location: '/genres');
      expect(find.text('Роман'), findsOneWidget);
      await pumpApp(t, location: '/publishers');
      expect(find.text('АСТ'), findsOneWidget);
      await pumpApp(t, location: '/readers');
      expect(find.text('Смирнов П. А.'), findsOneWidget);
    });

    testWidgets('читатели: фильтр по статусу билета и поиск по номеру', (
      t,
    ) async {
      await pumpApp(t, location: '/readers?card=expired');
      expect(find.text('Попов Д. С.'), findsOneWidget);
      expect(find.text('Смирнов П. А.'), findsNothing);
      await pumpApp(t, location: '/readers?search=RC-000004');
      expect(find.text('Васильева Е. О.'), findsOneWidget);
    });

    testWidgets('создание автора, жанра и издательства через форму', (t) async {
      final router = await pumpApp(t, location: '/authors/new');
      await type(t, 'fullName', 'Тестовый А. А.');
      await type(t, 'birthYear', '1980');
      await type(t, 'country', 'Россия');
      await submit(t);
      expect(currentUri(router).path, '/authors');

      router.go('/genres/new');
      await t.pumpAndSettle();
      await type(t, 'name', 'Тест-жанр');
      await submit(t);
      expect(currentUri(router).path, '/genres');
      expect(find.text('Запись создана'), findsOneWidget);
    });

    testWidgets('несуществующая запись в форме изменения', (t) async {
      await pumpApp(t, location: '/books/999/edit');
      expect(
        find.text('Запись не найдена или удалена навсегда.'),
        findsOneWidget,
      );
    });

    testWidgets('навигация содержит пять разделов', (t) async {
      await pumpApp(t);
      for (final label in [
        'Книги',
        'Авторы',
        'Жанры',
        'Издательства',
        'Читатели',
      ]) {
        expect(find.text(label), findsWidgets, reason: label);
      }
    });

    testWidgets(
      'список читателей на узком окне: карточки и кнопка добавления',
      (t) async {
        await pumpApp(t, location: '/readers', size: const Size(420, 900));
        expect(find.byKey(const ValueKey('create-button')), findsOneWidget);
        expect(find.byType(DataTable), findsNothing);
      },
    );
  });

  group('сохранение данных', () {
    testWidgets('созданный автор виден после перезапуска приложения', (
      t,
    ) async {
      final prefs = await _prefs();
      await pumpApp(t, location: '/authors/new', prefs: prefs);
      await type(t, 'fullName', 'Сохранённый А. А.');
      await type(t, 'birthYear', '1975');
      await type(t, 'country', 'Россия');
      await submit(t);

      // «Перезагрузка страницы»: приложение собирается заново на тех же данных.
      await t.pumpWidget(const SizedBox());
      await pumpApp(t, location: '/authors?search=Сохранённый', prefs: prefs);
      expect(find.text('Сохранённый А. А.'), findsOneWidget);
    });

    testWidgets(
      'испорченные данные: приложение запускается и показывает сообщение',
      (t) async {
        final prefs = await _prefs({'authors_v2': '{сломано'});
        await pumpApp(t, location: '/authors', prefs: prefs);
        expect(find.byKey(const ValueKey('storage-notice')), findsOneWidget);
        expect(
          find.textContaining('Восстановлен начальный набор'),
          findsOneWidget,
        );
        expect(find.text('Брэдбери Р.'), findsOneWidget);
      },
    );
  });
}

Future<SharedPreferences> _prefs([
  Map<String, Object> initial = const {},
]) async {
  SharedPreferences.setMockInitialValues(initial);
  return SharedPreferences.getInstance();
}
