import 'package:dio/dio.dart';
import '../models/app_user.dart';
import 'api_exceptions.dart';

class AuthResponse {
  final String accessToken;
  final String refreshToken;
  final int expiresIn;
  final AppUser user;

  const AuthResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
    required this.user,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
      expiresIn: (json['expiresIn'] as num?)?.toInt() ?? 900,
      user: AppUser.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}

class AuthApi {
  final Dio dio;

  const AuthApi(this.dio);

  Future<AuthResponse> login(String username, String password) async {
    try {
      final response = await dio.post(
        '/auth/login',
        data: {'username': username, 'password': password},
      );
      return AuthResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _wrapError(e);
    }
  }

  Future<AppUser> register({
    required String username,
    required String password,
    String? email,
    String? fullName,
  }) async {
    try {
      final response = await dio.post(
        '/auth/register',
        data: {
          'username': username,
          'password': password,
          if (email != null && email.isNotEmpty) 'email': email,
          if (fullName != null && fullName.isNotEmpty) 'fullName': fullName,
        },
      );
      return AppUser.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _wrapError(e);
    }
  }

  Future<AuthResponse> refresh(String refreshToken) async {
    try {
      final response = await dio.post(
        '/auth/refresh',
        data: {'refreshToken': refreshToken},
      );
      return AuthResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _wrapError(e);
    }
  }

  Future<AppUser> me([String? accessToken]) async {
    try {
      final options = Options();
      if (accessToken != null) {
        options.headers = {'Authorization': 'Bearer $accessToken'};
      }
      final response = await dio.get('/auth/me', options: options);
      return AppUser.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _wrapError(e);
    }
  }

  Future<void> logout(String? refreshToken) async {
    if (refreshToken == null) return;
    try {
      await dio.post('/auth/logout', data: {'refreshToken': refreshToken});
    } catch (_) {}
  }

  Object _wrapError(DioException e) {
    if (e.error is ApiException) return e.error!;
    final status = e.response?.statusCode;
    if (status != null) {
      return mapHttpError(status, e.response?.data);
    }
    return NetworkException('Ошибка сети: ${e.message}');
  }
}
