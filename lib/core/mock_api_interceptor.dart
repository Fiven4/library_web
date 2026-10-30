import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/seed_data.dart';

class MockApiInterceptor extends Interceptor {
  final SharedPreferences? prefs;
  final List<Map<String, dynamic>> _books = [];
  final List<Map<String, dynamic>> _authors = [];
  final List<Map<String, dynamic>> _genres = [];
  final List<Map<String, dynamic>> _publishers = [];
  final List<Map<String, dynamic>> _readers = [];
  final List<Map<String, dynamic>> _users = [];

  MockApiInterceptor([this.prefs]) {
    _initData();
  }

  void _initData() {
    _publishers.addAll([for (final p in seedPublishers) p.toJson()]);
    _genres.addAll([for (final g in seedGenres) g.toJson()]);
    _authors.addAll([for (final a in seedAuthors) a.toJson()]);
    _books.addAll([for (final b in seedBooks) b.toJson()]);
    _readers.addAll([for (final r in seedReaders) r.toJson()]);
    _users.addAll([
      {
        'id': 1,
        'username': 'admin',
        'password': 'admin123',
        'fullName': 'Администратор',
        'email': 'admin@library.local',
        'role': 'admin',
        'readerId': null,
      },
      {
        'id': 2,
        'username': 'librarian',
        'password': 'librarian123',
        'fullName': 'Петрова А. С.',
        'email': 'petrova@library.local',
        'role': 'librarian',
        'readerId': null,
      },
      {
        'id': 3,
        'username': 'reader',
        'password': 'reader123',
        'fullName': 'Смирнов П. А.',
        'email': 'smirnov@example.com',
        'role': 'reader',
        'readerId': 1,
      },
    ]);

    if (prefs != null) {
      _loadFromPrefs('mock_books', _books);
      _loadFromPrefs('mock_authors', _authors);
      _loadFromPrefs('mock_genres', _genres);
      _loadFromPrefs('mock_publishers', _publishers);
      _loadFromPrefs('mock_readers', _readers);
      _loadFromPrefs('mock_users', _users);
    }
  }

  void _loadFromPrefs(String key, List<Map<String, dynamic>> target) {
    final raw = prefs?.getString(key);
    if (raw == null) return;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        target.clear();
        for (final item in decoded) {
          if (item is Map) {
            target.add(Map<String, dynamic>.from(item));
          }
        }
      }
    } catch (_) {}
  }

  void _saveToPrefs(String key, List<Map<String, dynamic>> source) {
    prefs?.setString(key, jsonEncode(source));
  }

  Map<String, dynamic> _expandBook(Map<String, dynamic> b) {
    final pubId = b['publisherId'] as int?;
    final pub = _publishers.where((p) => p['id'] == pubId).firstOrNull;

    final authorIds = (b['authorIds'] as List?)?.cast<int>() ?? const [];
    final authorsList = [
      for (final aid in authorIds)
        if (_authors.any((a) => a['id'] == aid))
          {
            'id': aid,
            'fullName': _authors.firstWhere((a) => a['id'] == aid)['fullName'],
          },
    ];

    final genreIds = (b['genreIds'] as List?)?.cast<int>() ?? const [];
    final genresList = [
      for (final gid in genreIds)
        if (_genres.any((g) => g['id'] == gid))
          {
            'id': gid,
            'name': _genres.firstWhere((g) => g['id'] == gid)['name'],
          },
    ];

    return {
      'id': b['id'],
      'title': b['title'],
      'isbn': b['isbn'],
      'year': b['year'],
      'pages': b['pages'],
      'publisherId': pubId,
      'publisher': pub != null ? {'id': pub['id'], 'name': pub['name']} : null,
      'authorIds': authorIds,
      'authors': authorsList,
      'genreIds': genreIds,
      'genres': genresList,
      'copiesTotal': b['copiesTotal'] ?? 1,
      'copiesAvailable': b['copiesAvailable'] ?? b['copiesTotal'] ?? 1,
      'deletedAt': b['deletedAt'],
    };
  }

  int _nextId(List<Map<String, dynamic>> list) {
    if (list.isEmpty) return 1;
    return list
            .map((e) => (e['id'] as num?)?.toInt() ?? 0)
            .reduce((a, b) => a > b ? a : b) +
        1;
  }

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final baseUrl = options.baseUrl;
    final isBrowserWeb = kIsWeb;
    final isDummyHost =
        baseUrl.contains('localhost') ||
        baseUrl.contains('example.com') ||
        baseUrl.isEmpty;

    if (isBrowserWeb || isDummyHost) {
      try {
        final resp = await _handleRequest(options);
        if (resp != null) {
          return handler.resolve(resp);
        }
      } catch (e) {
        if (e is DioException) {
          return handler.reject(e);
        }
      }
    }

    return handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    try {
      final resp = await _handleRequest(err.requestOptions);
      if (resp != null) {
        return handler.resolve(resp);
      }
    } catch (_) {}
    return handler.next(err);
  }

  Future<Response?> _handleRequest(RequestOptions options) async {
    String path = options.path;
    if (path.startsWith('/api')) {
      path = path.substring(4);
    }
    if (!path.startsWith('/')) {
      path = '/$path';
    }

    final method = options.method.toUpperCase();
    final query = options.queryParameters;
    final data = options.data is Map ? options.data as Map : null;

    if (path == '/auth/login' && method == 'POST') {
      final username = (data?['username'] as String?)?.trim() ?? '';
      final password = (data?['password'] as String?) ?? '';
      final user = _users.where((u) {
        return u['username'] == username && u['password'] == password;
      }).firstOrNull;

      if (user == null) {
        throw DioException(
          requestOptions: options,
          type: DioExceptionType.badResponse,
          response: Response(
            requestOptions: options,
            statusCode: 401,
            data: {'message': 'Неверный логин или пароль'},
          ),
        );
      }

      final safeUser = {
        'id': user['id'],
        'username': user['username'],
        'fullName': user['fullName'],
        'email': user['email'],
        'role': user['role'],
        if (user['readerId'] != null) 'readerId': user['readerId'],
      };

      return Response(
        requestOptions: options,
        statusCode: 200,
        data: {
          'accessToken': 'mock_access_token_${user['id']}',
          'refreshToken': 'mock_refresh_token_${user['id']}',
          'expiresIn': 900,
          'user': safeUser,
        },
      );
    }

    if (path == '/auth/register' && method == 'POST') {
      final username = (data?['username'] as String?)?.trim() ?? '';
      final password = (data?['password'] as String?) ?? '';
      final email = (data?['email'] as String?) ?? '';
      final fullName = (data?['fullName'] as String?) ?? username;

      final exists = _users.any((u) => u['username'] == username);
      if (exists) {
        throw DioException(
          requestOptions: options,
          type: DioExceptionType.badResponse,
          response: Response(
            requestOptions: options,
            statusCode: 409,
            data: {
              'message': 'Пользователь с именем $username уже зарегистрирован',
            },
          ),
        );
      }

      final newId = _nextId(_users);
      final newUser = {
        'id': newId,
        'username': username,
        'password': password,
        'fullName': fullName,
        'email': email,
        'role': 'reader',
        'readerId': null,
      };
      _users.add(newUser);
      _saveToPrefs('mock_users', _users);

      return Response(
        requestOptions: options,
        statusCode: 201,
        data: {
          'id': newId,
          'username': username,
          'fullName': fullName,
          'email': email,
          'role': 'reader',
        },
      );
    }

    if (path == '/auth/me' && method == 'GET') {
      final authHeader = options.headers['Authorization'] as String?;
      Map<String, dynamic> user = _users[2];
      if (authHeader != null && authHeader.contains('mock_access_token_')) {
        final idStr = authHeader.split('mock_access_token_').last.trim();
        final uid = int.tryParse(idStr);
        if (uid != null) {
          final found = _users.where((u) => u['id'] == uid).firstOrNull;
          if (found != null) user = found;
        }
      }

      return Response(
        requestOptions: options,
        statusCode: 200,
        data: {
          'id': user['id'],
          'username': user['username'],
          'fullName': user['fullName'],
          'email': user['email'],
          'role': user['role'],
          if (user['readerId'] != null) 'readerId': user['readerId'],
        },
      );
    }

    if (path == '/auth/refresh' && method == 'POST') {
      final user = _users[2];
      return Response(
        requestOptions: options,
        statusCode: 200,
        data: {
          'accessToken': 'mock_access_token_${user['id']}',
          'refreshToken': 'mock_refresh_token_${user['id']}',
          'expiresIn': 900,
          'user': {
            'id': user['id'],
            'username': user['username'],
            'fullName': user['fullName'],
            'email': user['email'],
            'role': user['role'],
            if (user['readerId'] != null) 'readerId': user['readerId'],
          },
        },
      );
    }

    if (path == '/auth/logout' && method == 'POST') {
      return Response(
        requestOptions: options,
        statusCode: 200,
        data: {'message': 'Сессия завершена'},
      );
    }

    if (path == '/users' && method == 'GET') {
      return Response(
        requestOptions: options,
        statusCode: 200,
        data: {
          'items': [
            for (final u in _users)
              {
                'id': u['id'],
                'username': u['username'],
                'fullName': u['fullName'],
                'email': u['email'],
                'role': u['role'],
                if (u['readerId'] != null) 'readerId': u['readerId'],
              },
          ],
          'total': _users.length,
        },
      );
    }

    if (path == '/books' && method == 'GET') {
      return _paginate(
        options,
        _books,
        query,
        mapper: _expandBook,
        filter: (b, q) {
          final s = (q['search'] as String?)?.toLowerCase();
          if (s != null && s.isNotEmpty) {
            final t = (b['title'] as String?)?.toLowerCase() ?? '';
            final i = (b['isbn'] as String?)?.toLowerCase() ?? '';
            if (!t.contains(s) && !i.contains(s)) return false;
          }
          final aid = int.tryParse(q['authorId']?.toString() ?? '');
          if (aid != null) {
            final aids = (b['authorIds'] as List?)?.cast<int>() ?? const [];
            if (!aids.contains(aid)) return false;
          }
          final gid = int.tryParse(q['genreId']?.toString() ?? '');
          if (gid != null) {
            final gids = (b['genreIds'] as List?)?.cast<int>() ?? const [];
            if (!gids.contains(gid)) return false;
          }
          final pid = int.tryParse(q['publisherId']?.toString() ?? '');
          if (pid != null && b['publisherId'] != pid) return false;

          final incDel =
              q['includeDeleted'] == true || q['includeDeleted'] == 'true';
          if (!incDel && b['deletedAt'] != null) return false;

          return true;
        },
      );
    }

    if (path.startsWith('/books/') && method == 'GET') {
      final idStr = path.substring(7);
      final id = int.tryParse(idStr);
      final b = _books.where((x) => x['id'] == id).firstOrNull;
      if (b == null) {
        throw DioException(
          requestOptions: options,
          type: DioExceptionType.badResponse,
          response: Response(
            requestOptions: options,
            statusCode: 404,
            data: {'message': 'Книга не найдена'},
          ),
        );
      }
      return Response(
        requestOptions: options,
        statusCode: 200,
        data: _expandBook(b),
      );
    }

    if (path == '/books' && method == 'POST') {
      final newId = _nextId(_books);
      final newBook = {
        'id': newId,
        'title': data?['title'] ?? '',
        'isbn': data?['isbn'] ?? '',
        'year': (data?['year'] as num?)?.toInt() ?? 2026,
        'pages': (data?['pages'] as num?)?.toInt() ?? 100,
        'publisherId': (data?['publisherId'] as num?)?.toInt() ?? 1,
        'authorIds': (data?['authorIds'] as List?)?.cast<int>() ?? const [1],
        'genreIds': (data?['genreIds'] as List?)?.cast<int>() ?? const [1],
        'copiesTotal': (data?['copiesTotal'] as num?)?.toInt() ?? 1,
        'copiesAvailable': (data?['copiesTotal'] as num?)?.toInt() ?? 1,
        'deletedAt': null,
      };
      _books.add(newBook);
      _saveToPrefs('mock_books', _books);
      return Response(
        requestOptions: options,
        statusCode: 201,
        data: _expandBook(newBook),
      );
    }

    if (path.startsWith('/books/') && method == 'PUT') {
      final idStr = path.substring(7);
      final id = int.tryParse(idStr);
      final idx = _books.indexWhere((x) => x['id'] == id);
      if (idx == -1) {
        throw DioException(
          requestOptions: options,
          type: DioExceptionType.badResponse,
          response: Response(
            requestOptions: options,
            statusCode: 404,
            data: {'message': 'Книга не найдена'},
          ),
        );
      }
      final updated = Map<String, dynamic>.from(_books[idx]);
      if (data != null) {
        for (final entry in data.entries) {
          updated[entry.key] = entry.value;
        }
      }
      _books[idx] = updated;
      _saveToPrefs('mock_books', _books);
      return Response(
        requestOptions: options,
        statusCode: 200,
        data: _expandBook(updated),
      );
    }

    if (path.startsWith('/books/') &&
        path.endsWith('/restore') &&
        method == 'POST') {
      final idStr = path.substring(7, path.length - 8);
      final id = int.tryParse(idStr);
      final idx = _books.indexWhere((x) => x['id'] == id);
      if (idx != -1) {
        _books[idx]['deletedAt'] = null;
        _saveToPrefs('mock_books', _books);
      }
      return Response(
        requestOptions: options,
        statusCode: 200,
        data: {'success': true},
      );
    }

    if (path.startsWith('/books/') && method == 'DELETE') {
      final idStr = path.substring(7);
      final id = int.tryParse(idStr);
      final idx = _books.indexWhere((x) => x['id'] == id);
      if (idx != -1) {
        if (query['hard'] == 'true' || query['hard'] == true) {
          _books.removeAt(idx);
        } else {
          _books[idx]['deletedAt'] = DateTime.now().toIso8601String();
        }
        _saveToPrefs('mock_books', _books);
      }
      return Response(
        requestOptions: options,
        statusCode: 200,
        data: {'success': true},
      );
    }

    if (path == '/books/bulk-delete' && method == 'POST') {
      final ids = (data?['ids'] as List?)?.cast<int>() ?? const [];
      for (final id in ids) {
        final idx = _books.indexWhere((x) => x['id'] == id);
        if (idx != -1) {
          _books[idx]['deletedAt'] = DateTime.now().toIso8601String();
        }
      }
      _saveToPrefs('mock_books', _books);
      return Response(
        requestOptions: options,
        statusCode: 200,
        data: {'deleted': ids.length, 'failed': 0},
      );
    }

    if (path == '/authors' && method == 'GET') {
      return _paginate(
        options,
        _authors,
        query,
        filter: (a, q) {
          final s = (q['search'] as String?)?.toLowerCase();
          if (s != null && s.isNotEmpty) {
            final fn = (a['fullName'] as String?)?.toLowerCase() ?? '';
            if (!fn.contains(s)) return false;
          }
          final incDel =
              q['includeDeleted'] == true || q['includeDeleted'] == 'true';
          if (!incDel && a['deletedAt'] != null) return false;
          return true;
        },
      );
    }

    if (path.startsWith('/authors/') && method == 'GET') {
      final id = int.tryParse(path.substring(9));
      final a = _authors.where((x) => x['id'] == id).firstOrNull;
      if (a == null) {
        throw DioException(
          requestOptions: options,
          type: DioExceptionType.badResponse,
          response: Response(
            requestOptions: options,
            statusCode: 404,
            data: {'message': 'Автор не найден'},
          ),
        );
      }
      return Response(requestOptions: options, statusCode: 200, data: a);
    }

    if (path == '/authors' && method == 'POST') {
      final newId = _nextId(_authors);
      final newAuthor = {
        'id': newId,
        'fullName': data?['fullName'] ?? '',
        'birthYear': (data?['birthYear'] as num?)?.toInt() ?? 1900,
        'country': data?['country'] ?? '',
        'deletedAt': null,
      };
      _authors.add(newAuthor);
      _saveToPrefs('mock_authors', _authors);
      return Response(
        requestOptions: options,
        statusCode: 201,
        data: newAuthor,
      );
    }

    if (path.startsWith('/authors/') && method == 'PUT') {
      final id = int.tryParse(path.substring(9));
      final idx = _authors.indexWhere((x) => x['id'] == id);
      if (idx != -1 && data != null) {
        for (final entry in data.entries) {
          _authors[idx][entry.key] = entry.value;
        }
        _saveToPrefs('mock_authors', _authors);
        return Response(
          requestOptions: options,
          statusCode: 200,
          data: _authors[idx],
        );
      }
    }

    if (path.startsWith('/authors/') && method == 'DELETE') {
      final id = int.tryParse(path.substring(9));
      final idx = _authors.indexWhere((x) => x['id'] == id);
      if (idx != -1) {
        if (query['hard'] == 'true' || query['hard'] == true) {
          _authors.removeAt(idx);
        } else {
          _authors[idx]['deletedAt'] = DateTime.now().toIso8601String();
        }
        _saveToPrefs('mock_authors', _authors);
      }
      return Response(
        requestOptions: options,
        statusCode: 200,
        data: {'success': true},
      );
    }

    if (path == '/genres' && method == 'GET') {
      return _paginate(
        options,
        _genres,
        query,
        filter: (g, q) {
          final s = (q['search'] as String?)?.toLowerCase();
          if (s != null && s.isNotEmpty) {
            final n = (g['name'] as String?)?.toLowerCase() ?? '';
            if (!n.contains(s)) return false;
          }
          final incDel =
              q['includeDeleted'] == true || q['includeDeleted'] == 'true';
          if (!incDel && g['deletedAt'] != null) return false;
          return true;
        },
      );
    }

    if (path.startsWith('/genres/') && method == 'GET') {
      final id = int.tryParse(path.substring(8));
      final g = _genres.where((x) => x['id'] == id).firstOrNull;
      if (g == null) {
        throw DioException(
          requestOptions: options,
          type: DioExceptionType.badResponse,
          response: Response(
            requestOptions: options,
            statusCode: 404,
            data: {'message': 'Жанр не найден'},
          ),
        );
      }
      return Response(requestOptions: options, statusCode: 200, data: g);
    }

    if (path == '/genres' && method == 'POST') {
      final newId = _nextId(_genres);
      final newGenre = {
        'id': newId,
        'name': data?['name'] ?? '',
        'description': data?['description'] ?? '',
        'deletedAt': null,
      };
      _genres.add(newGenre);
      _saveToPrefs('mock_genres', _genres);
      return Response(requestOptions: options, statusCode: 201, data: newGenre);
    }

    if (path.startsWith('/genres/') && method == 'PUT') {
      final id = int.tryParse(path.substring(8));
      final idx = _genres.indexWhere((x) => x['id'] == id);
      if (idx != -1 && data != null) {
        for (final entry in data.entries) {
          _genres[idx][entry.key] = entry.value;
        }
        _saveToPrefs('mock_genres', _genres);
        return Response(
          requestOptions: options,
          statusCode: 200,
          data: _genres[idx],
        );
      }
    }

    if (path.startsWith('/genres/') && method == 'DELETE') {
      final id = int.tryParse(path.substring(8));
      final idx = _genres.indexWhere((x) => x['id'] == id);
      if (idx != -1) {
        if (query['hard'] == 'true' || query['hard'] == true) {
          _genres.removeAt(idx);
        } else {
          _genres[idx]['deletedAt'] = DateTime.now().toIso8601String();
        }
        _saveToPrefs('mock_genres', _genres);
      }
      return Response(
        requestOptions: options,
        statusCode: 200,
        data: {'success': true},
      );
    }

    if (path == '/publishers' && method == 'GET') {
      return _paginate(
        options,
        _publishers,
        query,
        filter: (p, q) {
          final s = (q['search'] as String?)?.toLowerCase();
          if (s != null && s.isNotEmpty) {
            final n = (p['name'] as String?)?.toLowerCase() ?? '';
            if (!n.contains(s)) return false;
          }
          final incDel =
              q['includeDeleted'] == true || q['includeDeleted'] == 'true';
          if (!incDel && p['deletedAt'] != null) return false;
          return true;
        },
      );
    }

    if (path.startsWith('/publishers/') && method == 'GET') {
      final id = int.tryParse(path.substring(12));
      final p = _publishers.where((x) => x['id'] == id).firstOrNull;
      if (p == null) {
        throw DioException(
          requestOptions: options,
          type: DioExceptionType.badResponse,
          response: Response(
            requestOptions: options,
            statusCode: 404,
            data: {'message': 'Издательство не найдено'},
          ),
        );
      }
      return Response(requestOptions: options, statusCode: 200, data: p);
    }

    if (path == '/publishers' && method == 'POST') {
      final newId = _nextId(_publishers);
      final newPub = {
        'id': newId,
        'name': data?['name'] ?? '',
        'city': data?['city'] ?? '',
        'foundedYear': (data?['foundedYear'] as num?)?.toInt() ?? 2000,
        'deletedAt': null,
      };
      _publishers.add(newPub);
      _saveToPrefs('mock_publishers', _publishers);
      return Response(requestOptions: options, statusCode: 201, data: newPub);
    }

    if (path.startsWith('/publishers/') && method == 'PUT') {
      final id = int.tryParse(path.substring(12));
      final idx = _publishers.indexWhere((x) => x['id'] == id);
      if (idx != -1 && data != null) {
        for (final entry in data.entries) {
          _publishers[idx][entry.key] = entry.value;
        }
        _saveToPrefs('mock_publishers', _publishers);
        return Response(
          requestOptions: options,
          statusCode: 200,
          data: _publishers[idx],
        );
      }
    }

    if (path.startsWith('/publishers/') && method == 'DELETE') {
      final id = int.tryParse(path.substring(12));
      final idx = _publishers.indexWhere((x) => x['id'] == id);
      if (idx != -1) {
        if (query['hard'] == 'true' || query['hard'] == true) {
          _publishers.removeAt(idx);
        } else {
          _publishers[idx]['deletedAt'] = DateTime.now().toIso8601String();
        }
        _saveToPrefs('mock_publishers', _publishers);
      }
      return Response(
        requestOptions: options,
        statusCode: 200,
        data: {'success': true},
      );
    }

    if (path == '/readers' && method == 'GET') {
      return _paginate(
        options,
        _readers,
        query,
        filter: (r, q) {
          final s = (q['search'] as String?)?.toLowerCase();
          if (s != null && s.isNotEmpty) {
            final fn = (r['fullName'] as String?)?.toLowerCase() ?? '';
            final em = (r['email'] as String?)?.toLowerCase() ?? '';
            final ph = (r['phone'] as String?)?.toLowerCase() ?? '';
            if (!fn.contains(s) && !em.contains(s) && !ph.contains(s)) {
              return false;
            }
          }
          final incDel =
              q['includeDeleted'] == true || q['includeDeleted'] == 'true';
          if (!incDel && r['deletedAt'] != null) return false;
          return true;
        },
      );
    }

    if (path.startsWith('/readers/') && method == 'GET') {
      final id = int.tryParse(path.substring(9));
      final r = _readers.where((x) => x['id'] == id).firstOrNull;
      if (r == null) {
        throw DioException(
          requestOptions: options,
          type: DioExceptionType.badResponse,
          response: Response(
            requestOptions: options,
            statusCode: 404,
            data: {'message': 'Читатель не найден'},
          ),
        );
      }
      return Response(requestOptions: options, statusCode: 200, data: r);
    }

    if (path == '/readers' && method == 'POST') {
      final newId = _nextId(_readers);
      final newReader = {
        'id': newId,
        'fullName': data?['fullName'] ?? '',
        'email': data?['email'] ?? '',
        'phone': data?['phone'] ?? '',
        'card':
            data?['card'] ??
            {
              'number': 'RC-${newId.toString().padLeft(6, '0')}',
              'issuedAt': DateTime.now().toIso8601String(),
              'expiresAt': DateTime.now()
                  .add(const Duration(days: 365))
                  .toIso8601String(),
            },
        'deletedAt': null,
      };
      _readers.add(newReader);
      _saveToPrefs('mock_readers', _readers);
      return Response(
        requestOptions: options,
        statusCode: 201,
        data: newReader,
      );
    }

    if (path.startsWith('/readers/') && method == 'PUT') {
      final id = int.tryParse(path.substring(9));
      final idx = _readers.indexWhere((x) => x['id'] == id);
      if (idx != -1 && data != null) {
        for (final entry in data.entries) {
          _readers[idx][entry.key] = entry.value;
        }
        _saveToPrefs('mock_readers', _readers);
        return Response(
          requestOptions: options,
          statusCode: 200,
          data: _readers[idx],
        );
      }
    }

    if (path.startsWith('/readers/') && method == 'DELETE') {
      final id = int.tryParse(path.substring(9));
      final idx = _readers.indexWhere((x) => x['id'] == id);
      if (idx != -1) {
        if (query['hard'] == 'true' || query['hard'] == true) {
          _readers.removeAt(idx);
        } else {
          _readers[idx]['deletedAt'] = DateTime.now().toIso8601String();
        }
        _saveToPrefs('mock_readers', _readers);
      }
      return Response(
        requestOptions: options,
        statusCode: 200,
        data: {'success': true},
      );
    }

    return null;
  }

  Response _paginate(
    RequestOptions options,
    List<Map<String, dynamic>> source,
    Map<String, dynamic> query, {
    Map<String, dynamic> Function(Map<String, dynamic>)? mapper,
    bool Function(Map<String, dynamic>, Map<String, dynamic>)? filter,
  }) {
    List<Map<String, dynamic>> items = List.from(source);
    if (filter != null) {
      items = items.where((item) => filter(item, query)).toList();
    }

    final sort = query['sort'] as String?;
    if (sort != null && sort.contains(',')) {
      final parts = sort.split(',');
      final field = parts[0];
      final asc = parts[1].toLowerCase() == 'asc';
      items.sort((a, b) {
        final va = a[field];
        final vb = b[field];
        if (va == null && vb == null) return 0;
        if (va == null) return asc ? -1 : 1;
        if (vb == null) return asc ? 1 : -1;
        if (va is Comparable && vb is Comparable) {
          final res = va.compareTo(vb);
          return asc ? res : -res;
        }
        return 0;
      });
    }

    final page = (query['page'] as num?)?.toInt() ?? 1;
    final size = (query['size'] as num?)?.toInt() ?? 10;
    final start = (page - 1) * size;
    final paged = start >= items.length
        ? <Map<String, dynamic>>[]
        : items.skip(start).take(size).toList();

    final resultItems = [
      for (final it in paged) mapper != null ? mapper(it) : it,
    ];

    final total = items.length;
    final totalPages = (total / size).ceil();

    return Response(
      requestOptions: options,
      statusCode: 200,
      data: {
        'items': resultItems,
        'page': page,
        'size': size,
        'total': total,
        'totalPages': totalPages < 1 ? 1 : totalPages,
      },
    );
  }
}
