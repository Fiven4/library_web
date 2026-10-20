import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:library_web/core/dev_settings.dart';
import 'package:library_web/widgets/entity_card_list.dart';
import 'package:library_web/widgets/entity_table.dart';
import 'package:provider/provider.dart';

import 'package:library_web/app.dart';
import 'package:library_web/core/router.dart';

import 'helpers.dart';

void main() {
  testWidgets('список книг: таблица, 10 строк и подпись пагинации', (
    tester,
  ) async {
    await pumpApp(tester);
    expect(find.byType(EntityTable<dynamic>), findsNothing);
    expect(
      find.textContaining('Страница 1 из 4 · всего записей: 36'),
      findsOneWidget,
    );
    expect(find.text('1984'), findsOneWidget);
    expect(find.text('Название'), findsOneWidget);
  });

  testWidgets('поиск ждёт паузу в наборе и пишет условия в адрес', (
    tester,
  ) async {
    final router = await pumpApp(tester);

    await tester.enterText(find.byKey(const ValueKey('search-field')), 'война');
    await tester.pump(const Duration(milliseconds: 200));
    expect(currentUri(router).queryParameters, isEmpty);

    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    expect(currentUri(router).queryParameters['search'], 'война');
    expect(find.text('Война и мир'), findsOneWidget);
    expect(find.textContaining('всего записей: 1'), findsOneWidget);
  });

  testWidgets('несколько быстрых нажатий дают одну выборку', (tester) async {
    final router = await pumpApp(tester);
    final field = find.byKey(const ValueKey('search-field'));
    await tester.enterText(field, 'в');
    await tester.pump(const Duration(milliseconds: 150));
    await tester.enterText(field, 'во');
    await tester.pump(const Duration(milliseconds: 150));
    await tester.enterText(field, 'вой');
    await tester.pump(const Duration(milliseconds: 150));
    expect(currentUri(router).queryParameters, isEmpty);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
    expect(currentUri(router).queryParameters['search'], 'вой');
  });

  testWidgets('адрес с условиями восстанавливает то же состояние списка', (
    tester,
  ) async {
    await pumpApp(
      tester,
      location: '/books?search=бог&genreId=2&sort=year,desc&page=1',
    );
    final field = tester.widget<TextField>(
      find.byKey(const ValueKey('search-field')),
    );
    expect(field.controller!.text, 'бог');
    expect(find.text('Трудно быть богом'), findsOneWidget);
    expect(find.textContaining('всего записей: 1'), findsOneWidget);
  });

  testWidgets('несуществующая страница исправляется на последнюю', (
    tester,
  ) async {
    final router = await pumpApp(tester, location: '/books?page=99');
    await tester.pumpAndSettle();
    expect(currentUri(router).queryParameters['page'], '4');
    expect(find.textContaining('Страница 4 из 4'), findsOneWidget);
  });

  testWidgets('переходы по страницам и смена размера страницы', (tester) async {
    final router = await pumpApp(tester);

    await tester.tap(find.byTooltip('Следующая страница'));
    await tester.pumpAndSettle();
    expect(currentUri(router).queryParameters['page'], '2');
    expect(find.textContaining('Страница 2 из 4'), findsOneWidget);

    await tester.tap(find.byTooltip('Последняя страница'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Страница 4 из 4'), findsOneWidget);
    expect(rows, findsNWidgets(6));

    await tester.tap(find.byTooltip('Первая страница'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Страница 1 из 4'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('page-size')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('25').last);
    await tester.pumpAndSettle();
    expect(currentUri(router).queryParameters['size'], '25');
    expect(find.textContaining('Страница 1 из 2'), findsOneWidget);
    expect(rows, findsNWidgets(25));
  });

  testWidgets('щелчок по заголовку меняет сортировку и направление', (
    tester,
  ) async {
    final router = await pumpApp(tester);

    await tester.tap(find.text('Год'));
    await tester.pumpAndSettle();
    expect(currentUri(router).queryParameters['sort'], 'year,asc');

    await tester.tap(find.text('Год'));
    await tester.pumpAndSettle();
    expect(currentUri(router).queryParameters['sort'], 'year,desc');
    final table = tester.widget<DataTable>(find.byType(DataTable));
    expect(table.sortAscending, isFalse);
    expect(table.columns[table.sortColumnIndex!].label, isA<Text>());
  });

  testWidgets('состояние списка целиком определяется адресом', (tester) async {
    final router = await pumpApp(tester);
    await tester.tap(find.byTooltip('Действия').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Удалить').last);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Удалить'));
    await tester.pumpAndSettle();
    expect(find.textContaining('всего записей: 35'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('show-deleted')));
    await tester.pumpAndSettle();
    expect(currentUri(router).queryParameters['includeDeleted'], 'true');
    expect(find.textContaining('всего записей: 36'), findsOneWidget);

    router.go('/books');
    await tester.pumpAndSettle();
    expect(find.textContaining('всего записей: 35'), findsOneWidget);
    expect(find.text('удалена'), findsNothing);
  });

  testWidgets('пустой результат отличается от ошибки', (tester) async {
    await pumpApp(tester, location: '/books?search=такой-книги-нет');
    expect(find.text('По заданным условиям книг не найдено.'), findsOneWidget);
    expect(find.text('Сбросить условия'), findsOneWidget);
    expect(find.text('Повторить'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('сбой загрузки показывает ошибку и кнопку повтора', (
    tester,
  ) async {
    await pumpApp(tester);
    final dev = Provider.of<DevSettings>(
      tester.element(find.byType(MaterialApp)),
      listen: false,
    );
    dev.failing = true;
    await tester.tap(find.byTooltip('Следующая страница'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Не удалось загрузить список'), findsOneWidget);
    expect(find.text('Повторить'), findsOneWidget);
    expect(find.text('Сбросить условия'), findsNothing);

    dev.failing = false;
    await tester.tap(find.text('Повторить'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Не удалось загрузить список'), findsNothing);
    expect(find.textContaining('Страница 2 из 4'), findsOneWidget);
  });

  testWidgets('во время загрузки виден индикатор', (tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      AppProviders(child: LibraryApp(router: createRouter())),
    );
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('Загрузка…'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text('Загрузка…'), findsNothing);
  });

  testWidgets('узкое окно показывает карточки, широкое — таблицу', (
    tester,
  ) async {
    await pumpApp(tester, size: const Size(420, 900));
    expect(find.byType(DataTable), findsNothing);
    expect(find.byWidgetPredicate((w) => w is EntityCardList), findsOneWidget);

    tester.view.physicalSize = const Size(1400, 900);
    await tester.pumpAndSettle();
    expect(find.byType(DataTable), findsOneWidget);
    expect(find.byWidgetPredicate((w) => w is EntityCardList), findsNothing);
  });

  testWidgets('на узком окне фильтры раскрываются по кнопке', (tester) async {
    await pumpApp(tester, size: const Size(420, 900));
    expect(find.text('Жанр'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('filters-toggle')));
    await tester.pumpAndSettle();
    expect(find.text('Жанр'), findsOneWidget);
    expect(find.text('Издательство'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('filters-toggle')));
    await tester.pumpAndSettle();
    expect(find.text('Жанр'), findsNothing);
  });

  testWidgets('счётчик на кнопке фильтров показывает число условий', (
    tester,
  ) async {
    await pumpApp(
      tester,
      location: '/books?genreId=2&publisherId=1',
      size: const Size(420, 900),
    );
    expect(find.text('2'), findsOneWidget);
  });

  testWidgets('выделение нескольких строк и удаление с подтверждением', (
    tester,
  ) async {
    await pumpApp(tester);
    final checkboxes = find.byType(Checkbox);
    await tester.tap(checkboxes.at(1));
    await tester.tap(checkboxes.at(2));
    await tester.pump();
    expect(find.text('Выбрано: 2'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('delete-selected')));
    await tester.pumpAndSettle();
    expect(find.text('Удалить выбранные записи?'), findsOneWidget);
    await tester.tap(find.textContaining('Удалить (2)'));
    await tester.pumpAndSettle();

    expect(find.textContaining('всего записей: 34'), findsOneWidget);
    expect(find.byKey(const ValueKey('selection-bar')), findsNothing);
  });

  testWidgets('отказ в подтверждении ничего не удаляет', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.byType(Checkbox).at(1));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('delete-selected')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Отмена'));
    await tester.pumpAndSettle();
    expect(find.textContaining('всего записей: 36'), findsOneWidget);
  });

  testWidgets('удалённую запись можно показать и восстановить', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.byTooltip('Действия').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Удалить').last);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Удалить'));
    await tester.pumpAndSettle();
    expect(find.textContaining('всего записей: 35'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('show-deleted')));
    await tester.pumpAndSettle();
    expect(find.textContaining('всего записей: 36'), findsOneWidget);
    expect(find.text('удалена'), findsOneWidget);

    await tester.tap(find.byTooltip('Действия').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Восстановить'));
    await tester.pumpAndSettle();
    expect(find.text('удалена'), findsNothing);
  });

  testWidgets('физическое удаление стирает запись навсегда', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.byTooltip('Действия').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Удалить навсегда'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Удалить навсегда'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('show-deleted')));
    await tester.pumpAndSettle();
    expect(find.textContaining('всего записей: 35'), findsOneWidget);
  });

  testWidgets('карточка книги открывается и по ссылке, и из списка', (
    tester,
  ) async {
    await pumpApp(tester, location: '/books/1');
    expect(find.text('Война и мир'), findsWidgets);
    expect(find.text('978-5-17-118366-4'), findsOneWidget);
    expect(find.text('Толстой Л. Н.'), findsOneWidget);
  });

  testWidgets('несуществующая карточка показывает «не найдено»', (
    tester,
  ) async {
    await pumpApp(tester, location: '/books/999');
    expect(
      find.text('Запись не найдена или удалена навсегда.'),
      findsOneWidget,
    );
    await pumpApp(tester, location: '/books/abc');
    expect(
      find.text('Запись не найдена или удалена навсегда.'),
      findsOneWidget,
    );
  });

  testWidgets('неизвестный адрес открывает экран 404', (tester) async {
    await pumpApp(tester, location: '/qwerty');
    expect(find.text('404'), findsOneWidget);
  });

  testWidgets('авторы: поиск по стране и тот же универсальный список', (
    tester,
  ) async {
    await pumpApp(tester, location: '/authors?search=сша');
    expect(find.text('Брэдбери Р.'), findsOneWidget);
    expect(find.text('Хемингуэй Э.'), findsOneWidget);
    expect(find.text('Толстой Л. Н.'), findsNothing);
    expect(find.textContaining('всего записей: 2'), findsOneWidget);
  });

  testWidgets('карточка автора содержит его книги', (tester) async {
    await pumpApp(tester, location: '/authors/6');
    expect(find.text('Оруэлл Дж.'), findsWidgets);
    expect(find.text('1984'), findsOneWidget);
    expect(find.text('Скотный двор'), findsOneWidget);
  });
}
