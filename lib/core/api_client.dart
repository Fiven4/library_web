import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'api_exceptions.dart';
import 'config.dart';

Dio buildDio({
  String? Function()? tokenProvider,
  Future<bool> Function()? onRefreshToken,
}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
      validateStatus: (status) => status != null && status < 500,
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        final token =
            tokenProvider?.call() ??
            (apiDefaultToken.isNotEmpty ? apiDefaultToken : null);
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        if (kDebugMode) {
          debugPrint('[API] ${options.method} ${options.uri}');
        }
        return handler.next(options);
      },
      onResponse: (response, handler) {
        final status = response.statusCode ?? 0;
        if (kDebugMode) {
          debugPrint(
            '[API] ${response.requestOptions.method} ${response.requestOptions.uri} -> $status',
          );
        }

        if (status >= 400) {
          return handler.reject(
            DioException(
              requestOptions: response.requestOptions,
              response: response,
              type: DioExceptionType.badResponse,
              error: mapHttpError(status, response.data),
            ),
            true,
          );
        }
        return handler.next(response);
      },
      onError: (error, handler) async {
        final status = error.response?.statusCode;
        final requestOptions = error.requestOptions;

        if (status == 401 &&
            !requestOptions.path.contains('/auth/') &&
            onRefreshToken != null) {
          try {
            final refreshed = await onRefreshToken();
            if (refreshed) {
              final newOptions = requestOptions;
              final token = tokenProvider?.call();
              if (token != null) {
                newOptions.headers['Authorization'] = 'Bearer $token';
              }
              final response = await dio.fetch(newOptions);
              return handler.resolve(response);
            }
          } catch (_) {}
        }

        final isGet = requestOptions.method.toUpperCase() == 'GET';
        final isNetworkError =
            error.type != DioExceptionType.badResponse &&
            error.type != DioExceptionType.cancel;
        final retryCount = (requestOptions.extra['retry_count'] as int?) ?? 0;
        const maxRetries = 3;

        if (isGet && isNetworkError && retryCount < maxRetries) {
          final nextRetry = retryCount + 1;
          requestOptions.extra['retry_count'] = nextRetry;
          final delayMs = 500 * (1 << retryCount);
          if (kDebugMode) {
            debugPrint(
              '[API] Повтор чтения ($nextRetry/$maxRetries) через $delayMs мс: ${requestOptions.uri}',
            );
          }
          await Future.delayed(Duration(milliseconds: delayMs));
          try {
            final response = await dio.fetch(requestOptions);
            return handler.resolve(response);
          } on DioException catch (retryErr) {
            return handler.next(retryErr);
          }
        }

        if (kDebugMode) {
          debugPrint('[API] сбой ${error.requestOptions.uri}: ${error.type}');
        }
        return handler.next(error);
      },
    ),
  );

  return dio;
}
