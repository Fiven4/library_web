import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:library_web/app.dart';
import 'package:library_web/core/auth_api.dart';
import 'package:library_web/core/dev_settings.dart';
import 'package:library_web/core/router.dart';
import 'package:library_web/models/app_user.dart';
import 'package:library_web/models/role.dart';
import 'package:library_web/state/auth_notifier.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers.dart';

class _FakeAuthApi extends Fake implements AuthApi {
  @override
  Future<AppUser> me([String? accessToken]) async {
    return const AppUser(
      id: 1,
      username: 'reader',
      fullName: 'Иван Читатель',
      email: 'reader@example.com',
      role: Role.reader,
    );
  }

  @override
  Future<void> logout(String? refreshToken) async {}
}

void main() {
  group('Практическая работа №6: обязательные тесты виджетов (п. 12)', () {
    testWidgets('1. Отображение состояния загрузки (индикатор прогресса)', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        AppProviders(child: LibraryApp(router: createRouter())),
      );
      // При первой отрисовке до завершения асинхронной загрузки виден индикатор
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.text('Загрузка…'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsWidgets);

      await tester.pumpAndSettle();
    });

    testWidgets(
      '2. Отображение пустого результата при отсутствии подходящих записей',
      (tester) async {
        await pumpApp(
          tester,
          location:
              '/books?search=%D0%BD%D0%B5%D1%82-%D1%82%D0%B0%D0%BA%D0%BE%D0%B9-%D0%BA%D0%BD%D0%B8%D0%B3%D0%B8',
        );

        expect(
          find.text('По заданным условиям книг не найдено.'),
          findsOneWidget,
        );
        expect(find.text('Сбросить условия'), findsOneWidget);
        expect(find.text('Повторить'), findsNothing);
      },
    );

    testWidgets('3. Отображение ошибки с кнопкой повтора при сбое загрузки', (
      tester,
    ) async {
      await pumpApp(tester, location: '/books');

      final dev = Provider.of<DevSettings>(
        tester.element(find.byType(MaterialApp)),
        listen: false,
      );
      dev.failing = true;

      await tester.tap(find.byTooltip('Следующая страница'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Не удалось загрузить список'),
        findsOneWidget,
      );
      expect(find.text('Повторить'), findsOneWidget);

      // Восстановление связи и повтор запроса без перезагрузки страницы
      dev.failing = false;
      await tester.tap(find.text('Повторить'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Не удалось загрузить список'), findsNothing);
      expect(find.textContaining('Страница 2 из 4'), findsOneWidget);
    });

    testWidgets('4. Срабатывание валидации формы при пустой отправке', (
      tester,
    ) async {
      await pumpApp(tester, location: '/books/new');

      // Нажимаем «Сохранить» при пустых полях формы
      final button = tester.widget<FilledButton>(
        find.byKey(const ValueKey('submit-button')),
      );
      button.onPressed!();
      await tester.pumpAndSettle();

      // Проверяем отображение сообщений об ошибках валидации
      expect(find.text('Укажите название'), findsOneWidget);
      expect(find.text('Выберите издательство'), findsOneWidget);
      expect(find.text('Укажите год'), findsOneWidget);
      expect(find.text('Укажите ISBN'), findsOneWidget);
    });

    testWidgets(
      '5. Сокрытие недоступного элемента при недостаточной роли (роль Читатель)',
      (tester) async {
        tester.view.physicalSize = const Size(1440, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        SharedPreferences.setMockInitialValues({
          'auth_access_token': 'reader-token',
          'auth_refresh_token': 'reader-refresh',
          'auth_user_data': jsonEncode({
            'id': 1,
            'username': 'reader',
            'fullName': 'Иван Читатель',
            'email': 'reader@example.com',
            'role': 'reader',
          }),
        });

        final prefs = await SharedPreferences.getInstance();
        final auth = AuthNotifier(prefs, _FakeAuthApi());
        await auth.restore();

        final router = createRouter(initialLocation: '/books', auth: auth);
        await tester.pumpWidget(
          AppProviders(
            prefs: prefs,
            authNotifier: auth,
            child: LibraryApp(router: router),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // Кнопка «Добавить» скрыта для читателя (требует роль librarian)
        expect(find.byKey(const ValueKey('create-button')), findsNothing);

        // Переключаем роль на Библиотекаря (librarian) через DevTools-эксперимент
        auth.simulateClientRoleBypass(Role.librarian);
        await tester.pump();

        // Кнопка «Добавить» теперь видна
        expect(find.byKey(const ValueKey('create-button')), findsOneWidget);

        // Очищаем дерево виджетов для корректного снятия фоновых таймеров
        await tester.pumpWidget(const SizedBox());
      },
    );
  });
}
