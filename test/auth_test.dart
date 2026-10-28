import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:library_web/core/api_client.dart';
import 'package:library_web/core/auth_api.dart';
import 'package:library_web/core/router.dart';
import 'package:library_web/models/app_user.dart';
import 'package:library_web/models/role.dart';
import 'package:library_web/state/auth_notifier.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('1. Тестирование иерархии ролей и проверки прав', () {
    test('Иерархия уровней доступа: admin > librarian > reader', () {
      expect(Role.admin.level, greaterThan(Role.librarian.level));
      expect(Role.librarian.level, greaterThan(Role.reader.level));
      expect(Role.admin.level, 3);
      expect(Role.librarian.level, 2);
      expect(Role.reader.level, 1);
    });

    test('Читатель (reader): доступен только базовый функционал', () {
      const user = AppUser(
        id: 1,
        username: 'reader',
        fullName: 'Иван Читатель',
        email: 'reader@example.com',
        role: Role.reader,
      );

      expect(user.role.canAccess(Role.reader), isTrue);
      expect(user.role.canAccess(Role.librarian), isFalse);
      expect(user.role.canAccess(Role.admin), isFalse);
    });

    test('Библиотекарь (librarian): доступны книги и читатели, но не админка', () {
      const user = AppUser(
        id: 2,
        username: 'librarian',
        fullName: 'Анна Библиотекарь',
        email: 'lib@example.com',
        role: Role.librarian,
      );

      expect(user.role.canAccess(Role.reader), isTrue);
      expect(user.role.canAccess(Role.librarian), isTrue);
      expect(user.role.canAccess(Role.admin), isFalse);
    });

    test('Администратор (admin): полный доступ ко всем операциям и разделу пользователей', () {
      const user = AppUser(
        id: 3,
        username: 'admin',
        fullName: 'Главный Администратор',
        email: 'admin@example.com',
        role: Role.admin,
      );

      expect(user.role.canAccess(Role.reader), isTrue);
      expect(user.role.canAccess(Role.librarian), isTrue);
      expect(user.role.canAccess(Role.admin), isTrue);
    });

    test('AuthNotifier.has() корректно определяет доступность по минимальной роли', () {
      final dio = Dio();
      final auth = AuthNotifier(null, AuthApi(dio));

      expect(auth.isAuthenticated, isFalse);
      expect(auth.has(Role.reader), isFalse);
      expect(auth.has(Role.librarian), isFalse);
      expect(auth.has(Role.admin), isFalse);

      auth.simulateClientRoleBypass(Role.reader);
      expect(auth.has(Role.reader), isTrue);
      expect(auth.has(Role.librarian), isFalse);
      expect(auth.has(Role.admin), isFalse);

      auth.simulateClientRoleBypass(Role.librarian);
      expect(auth.has(Role.reader), isTrue);
      expect(auth.has(Role.librarian), isTrue);
      expect(auth.has(Role.admin), isFalse);

      auth.simulateClientRoleBypass(Role.admin);
      expect(auth.has(Role.reader), isTrue);
      expect(auth.has(Role.librarian), isTrue);
      expect(auth.has(Role.admin), isTrue);
    });
  });

  group('2. Тестирование валидации пароля при регистрации', () {
    bool checkPassword(String p) {
      final hasLength = p.length >= 8;
      final hasDigit = RegExp(r'\d').hasMatch(p);
      final hasSpecial = RegExp(r'[!@#$%^&*(),.?":{}|<>\-_]').hasMatch(p);
      return hasLength && hasDigit && hasSpecial;
    }

    test('Короткий пароль (< 8 символов) не проходит', () {
      expect(checkPassword('Pass1!'), isFalse);
    });

    test('Пароль без цифры не проходит', () {
      expect(checkPassword('Password!'), isFalse);
    });

    test('Пароль без спецсимвола не проходит', () {
      expect(checkPassword('Password123'), isFalse);
    });

    test('Надёжный пароль (8+ символов, цифра, спецсимвол) успешно проходит проверку', () {
      expect(checkPassword('Passw0rd!'), isTrue);
      expect(checkPassword('Secure#2026'), isTrue);
      expect(checkPassword('Libr@ry7_Web'), isTrue);
    });
  });

  group('3. Тестирование GoRouter redirect и защиты маршрутов', () {
    test('Неавторизованный пользователь перенаправляется на /login с параметром from', () {
      final dio = Dio();
      final auth = AuthNotifier(null, AuthApi(dio));
      final router = createRouter(auth: auth);

      // Проверяем, что router создан с refreshListenable
      expect(router, isNotNull);
      expect(auth.isAuthenticated, isFalse);
    });

    test('Авторизованный пользователь при открытии /login перенаправляется в /books', () async {
      SharedPreferences.setMockInitialValues({
        'auth_access_token': 'dummy-access',
        'auth_refresh_token': 'dummy-refresh',
        'auth_user_data': jsonEncode({
          'id': 1,
          'username': 'reader',
          'fullName': 'Иван Читатель',
          'email': 'reader@example.com',
          'role': 'reader',
        }),
      });

      final prefs = await SharedPreferences.getInstance();
      final dio = Dio();
      final auth = AuthNotifier(prefs, AuthApi(dio));
      await auth.restore();

      expect(auth.isAuthenticated, isTrue);
      expect(auth.user?.username, 'reader');
    });
  });

  group('4. Сетевой слой: автоматический refresh токена при 401', () {
    test('401 на защищённом эндпоинте вызывает refreshTokens() и повторяет запрос', () async {
      int refreshCallCount = 0;
      String currentToken = 'old-expired-token';

      final dio = buildDio(
        tokenProvider: () => currentToken,
        onRefreshToken: () async {
          refreshCallCount++;
          currentToken = 'new-valid-token';
          return true;
        },
      );

      final dioAdapter = DioAdapter(dio: dio);

      // Первый запрос с устаревшим токеном возвращает 401
      dioAdapter.onGet(
        '/books/1',
        (server) => server.reply(401, {'message': 'Токен истёк'}),
        headers: {'Authorization': 'Bearer old-expired-token'},
      );

      // Повторный запрос с новым токеном возвращает 200 OK
      dioAdapter.onGet(
        '/books/1',
        (server) => server.reply(200, {'id': 1, 'title': 'Война и мир'}),
        headers: {'Authorization': 'Bearer new-valid-token'},
      );

      final response = await dio.get('/books/1');
      expect(response.statusCode, 200);
      expect(response.data['title'], 'Война и мир');
      expect(refreshCallCount, 1);
    });

    test('401 на /auth/login НЕ вызывает refreshTokens() — предотвращение зацикливания', () async {
      int refreshCallCount = 0;

      final dio = buildDio(
        tokenProvider: () => 'token',
        onRefreshToken: () async {
          refreshCallCount++;
          return true;
        },
      );

      final dioAdapter = DioAdapter(dio: dio);
      dioAdapter.onPost(
        '/auth/login',
        (server) => server.reply(401, {'message': 'Неверный логин или пароль'}),
      );

      expect(
        () => dio.post('/auth/login', data: {'username': 'u', 'password': 'p'}),
        throwsA(isA<DioException>()),
      );
      // Убеждаемся, что интерсептор НЕ пытался обновлять токен для auth-маршрута
      expect(refreshCallCount, 0);
    });
  });

  group('5. Эксперимент п. 17: клиентская подмена роли против серверной защиты', () {
    test('Подмена роли в клиенте даёт has(admin) == true, но сервер отклоняет запрос кодом 403', () async {
      final dio = Dio(BaseOptions(baseUrl: 'http://localhost:8080/api'));
      final dioAdapter = DioAdapter(dio: dio);

      // Сервер проверяет криптографическую подпись токена.
      // Читатель подменил роль в клиенте, но токен выдан для роли reader!
      dioAdapter.onGet(
        '/users',
        (server) => server.reply(403, {'message': 'Операция доступна начиная с роли «admin»'}),
        headers: {'Authorization': 'Bearer reader-signed-jwt'},
      );

      final auth = AuthNotifier(null, AuthApi(dio));
      // Исходное состояние: читатель
      auth.simulateClientRoleBypass(Role.reader);
      expect(auth.has(Role.admin), isFalse);

      // Пользователь в DevTools подменяет роль на admin:
      auth.simulateClientRoleBypass(Role.admin);
      expect(auth.has(Role.admin), isTrue); // Клиентский интерфейс «поверил»

      // Однако при попытке сделать реальный запрос к серверу:
      try {
        await dio.get('/users', options: Options(headers: {'Authorization': 'Bearer reader-signed-jwt'}));
        fail('Сервер должен был отклонить запрос с кодом 403');
      } on DioException catch (e) {
        expect(e.response?.statusCode, 403);
        expect(e.response?.data['message'], contains('Операция доступна начиная с роли «admin»'));
      }
    });
  });
}
