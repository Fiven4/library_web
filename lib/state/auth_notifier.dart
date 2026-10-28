import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/api_exceptions.dart';
import '../core/auth_api.dart';
import '../models/app_user.dart';
import '../models/role.dart';

class AuthNotifier extends ChangeNotifier {
  static const _kAccess = 'auth_access_token';
  static const _kRefresh = 'auth_refresh_token';
  static const _kUser = 'auth_user_data';
  static const _kLastActivity = 'auth_last_activity';
  static const _kSessionStart = 'auth_session_start';

  final SharedPreferences? _prefs;
  final AuthApi _api;

  AppUser? _user;
  AppUser? _actualServerUser; // для возврата после эксперимента с подменой роли
  String? _accessToken;
  String? _refreshToken;
  DateTime? _sessionStart;
  DateTime? _lastActivity;
  bool _isRefreshing = false;
  bool _isInitialized = false;

  Duration maxSessionDuration = const Duration(hours: 1);
  Duration inactivityTimeout = const Duration(minutes: 3);

  AuthNotifier(this._prefs, this._api);

  AppUser? get user => _user;
  String? get accessToken => _accessToken;
  String? get refreshToken => _refreshToken;
  bool get isAuthenticated => _user != null && _accessToken != null;
  bool get isInitialized => _isInitialized;
  DateTime? get sessionStart => _sessionStart;
  DateTime? get lastActivity => _lastActivity;

  bool has(Role role) => _user != null && _user!.role.level >= role.level;

  /// Восстановление сессии при запуске приложения.
  /// Вызывается один раз до построения дерева виджетов.
  Future<void> restore() async {
    final access = _prefs?.getString(_kAccess);
    final refresh = _prefs?.getString(_kRefresh);
    final sessionStartMs = _prefs?.getInt(_kSessionStart);
    final lastActivityMs = _prefs?.getInt(_kLastActivity);
    final cachedUserJson = _prefs?.getString(_kUser);

    if (sessionStartMs != null) {
      _sessionStart = DateTime.fromMillisecondsSinceEpoch(sessionStartMs);
    }
    if (lastActivityMs != null) {
      _lastActivity = DateTime.fromMillisecondsSinceEpoch(lastActivityMs);
    }

    // Проверка предельной длительности сессии
    if (_sessionStart != null &&
        DateTime.now().difference(_sessionStart!) > maxSessionDuration) {
      await logout();
      _isInitialized = true;
      notifyListeners();
      return;
    }

    // Проверка таймаута неактивности через перезагрузку
    if (_lastActivity != null &&
        DateTime.now().difference(_lastActivity!) > inactivityTimeout) {
      await logout();
      _isInitialized = true;
      notifyListeners();
      return;
    }

    if (access == null) {
      _isInitialized = true;
      notifyListeners();
      return;
    }

    _accessToken = access;
    _refreshToken = refresh;

    if (cachedUserJson != null) {
      try {
        _user = AppUser.fromJson(
          jsonDecode(cachedUserJson) as Map<String, dynamic>,
        );
        _actualServerUser = _user;
      } catch (_) {}
    }

    try {
      final user = await _api.me(access);
      _user = user;
      _actualServerUser = user;
      await _saveUserToPrefs(user);
      recordActivity();
    } on UnauthorizedException {
      if (refresh != null) {
        try {
          await _refreshWith(refresh);
        } catch (_) {
          await logout();
        }
      } else {
        await logout();
      }
    } catch (_) {
      // Сервер временно недоступен: сессию не сбрасываем, оставляем кэшированного пользователя
    }

    _isInitialized = true;
    notifyListeners();
  }

  Future<void> login(String username, String password) async {
    final result = await _api.login(username, password);
    _accessToken = result.accessToken;
    _refreshToken = result.refreshToken;
    _user = result.user;
    _actualServerUser = result.user;
    _sessionStart = DateTime.now();
    _lastActivity = DateTime.now();

    await _prefs?.setString(_kAccess, result.accessToken);
    await _prefs?.setString(_kRefresh, result.refreshToken);
    await _prefs?.setInt(_kSessionStart, _sessionStart!.millisecondsSinceEpoch);
    await _prefs?.setInt(_kLastActivity, _lastActivity!.millisecondsSinceEpoch);
    await _saveUserToPrefs(result.user);

    notifyListeners();
  }

  Future<void> register(
    String username,
    String password, {
    String? email,
    String? fullName,
  }) async {
    await _api.register(
      username: username,
      password: password,
      email: email,
      fullName: fullName,
    );
    // Сразу авторизуем после регистрации
    await login(username, password);
  }

  Future<bool> refreshTokens() async {
    if (_isRefreshing || _refreshToken == null) return false;
    _isRefreshing = true;
    try {
      await _refreshWith(_refreshToken!);
      return true;
    } catch (e) {
      await logout();
      return false;
    } finally {
      _isRefreshing = false;
    }
  }

  Future<void> _refreshWith(String refresh) async {
    final result = await _api.refresh(refresh);
    _accessToken = result.accessToken;
    _refreshToken = result.refreshToken;
    _user = result.user;
    _actualServerUser = result.user;
    recordActivity();

    await _prefs?.setString(_kAccess, result.accessToken);
    await _prefs?.setString(_kRefresh, result.refreshToken);
    await _saveUserToPrefs(result.user);
    notifyListeners();
  }

  Future<void> logout() async {
    final token = _refreshToken;
    _user = null;
    _actualServerUser = null;
    _accessToken = null;
    _refreshToken = null;
    _sessionStart = null;
    _lastActivity = null;

    await _prefs?.remove(_kAccess);
    await _prefs?.remove(_kRefresh);
    await _prefs?.remove(_kUser);
    await _prefs?.remove(_kSessionStart);
    await _prefs?.remove(_kLastActivity);

    notifyListeners();

    if (token != null) {
      await _api.logout(token);
    }
  }

  void recordActivity() {
    _lastActivity = DateTime.now();
    _prefs?.setInt(_kLastActivity, _lastActivity!.millisecondsSinceEpoch);
  }

  Future<void> _saveUserToPrefs(AppUser user) async {
    await _prefs?.setString(_kUser, jsonEncode(user.toJson()));
  }

  // ──────────────────────────── Эксперимент п. 17 ────────────────────────────
  // Симуляция подмены роли в DevTools / localStorage на стороне клиента.
  // Это изменяет только локальное представление пользователя в браузере,
  // в то время как JWT токен остаётся подписан сервером под исходной ролью.
  void simulateClientRoleBypass(Role fakeRole) {
    _actualServerUser ??= _user;
    if (_user == null) {
      _user = AppUser(
        id: 999,
        username: 'test_user',
        fullName: 'Тестовый Пользователь',
        email: 'test@example.com',
        role: fakeRole,
      );
    } else {
      _user = _user!.copyWith(role: fakeRole);
    }
    _saveUserToPrefs(_user!);
    notifyListeners();
  }

  void resetRoleBypass() {
    if (_actualServerUser != null) {
      _user = _actualServerUser;
      _saveUserToPrefs(_user!);
      notifyListeners();
    }
  }
}
