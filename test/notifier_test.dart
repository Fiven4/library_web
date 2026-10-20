import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:library_web/core/dev_settings.dart';
import 'package:library_web/models/book.dart';
import 'package:library_web/models/book_query.dart';
import 'package:library_web/models/page_result.dart';
import 'package:library_web/repositories/entity_repository.dart';
import 'package:library_web/repositories/local_book_repository.dart';
import 'package:library_web/state/list_notifiers.dart';
import 'package:library_web/state/load_status.dart';

class _ManualRepository extends LocalBookRepository {
  final pending = <Completer<PageResult<Book>>>[];

  @override
  Future<PageResult<Book>> find(BookQuery q) {
    final c = Completer<PageResult<Book>>();
    pending.add(c);
    return c.future;
  }
}

void main() {
  test('успешная загрузка: loading, затем success', () async {
    final n = BooksNotifier(LocalBookRepository());
    final states = <LoadStatus>[];
    n.addListener(() => states.add(n.status));
    await n.load();
    expect(states, [LoadStatus.loading, LoadStatus.success]);
    expect(n.result.items, hasLength(10));
    expect(n.isEmptyResult, isFalse);
  });

  test('пустой результат — успех, а не ошибка и не загрузка', () async {
    final n = BooksNotifier(LocalBookRepository());
    await n.applyQuery(const BookQuery(search: 'такой книги нет'));
    expect(n.status, LoadStatus.success);
    expect(n.isEmptyResult, isTrue);
    expect(n.error, isNull);
  });

  test('сбой репозитория даёт состояние ошибки с сообщением', () async {
    final dev = DevSettings()..failing = true;
    final n = BooksNotifier(LocalBookRepository(dev: dev));
    await n.load();
    expect(n.status, LoadStatus.error);
    expect(n.error, contains('Не удалось загрузить список'));
    dev.failing = false;
    await n.load();
    expect(n.status, LoadStatus.success);
  });

  test('смена условий отбора сбрасывает выделение', () async {
    final n = BooksNotifier(LocalBookRepository());
    await n.load();
    n.toggleSelection(1);
    n.toggleSelection(2);
    expect(n.selected, {1, 2});
    await n.applyQuery(const BookQuery(search: 'война'));
    expect(n.selected, isEmpty);
  });

  test('выделение страницы целиком и снятие', () async {
    final n = BooksNotifier(LocalBookRepository());
    await n.load();
    n.setPageSelection(true);
    expect(n.selected, hasLength(10));
    n.setPageSelection(false);
    expect(n.hasSelection, isFalse);
  });

  test('удаление выбранных обновляет список и сбрасывает выделение', () async {
    final n = BooksNotifier(LocalBookRepository());
    await n.load();
    n.toggleSelection(1);
    n.toggleSelection(2);
    final deleted = await n.deleteSelected();
    expect(deleted, 2);
    expect(n.selected, isEmpty);
    expect(n.result.total, 34);
  });

  test('ответ на устаревший запрос отбрасывается', () async {
    final repo = _ManualRepository();
    final n = BooksNotifier(repo);
    final first = n.applyQuery(const BookQuery(search: 'a'), force: true);
    final second = n.applyQuery(const BookQuery(search: 'b'), force: true);
    repo.pending[1].complete(
      const PageResult(items: [], page: 1, size: 10, total: 0),
    );
    await second;
    repo.pending[0].complete(
      PageResult(items: const [], page: 1, size: 10, total: 777),
    );
    await first;
    expect(n.result.total, 0);
    expect(n.query.search, 'b');
  });

  test('повторное применение тех же условий не перезагружает список', () async {
    final n = BooksNotifier(LocalBookRepository());
    await n.applyQuery(const BookQuery(search: 'война'));
    var notified = 0;
    n.addListener(() => notified++);
    await n.applyQuery(const BookQuery(search: 'война'));
    expect(notified, 0);
  });

  test('ошибки репозитория при удалении пробрасываются', () async {
    final n = BooksNotifier(LocalBookRepository());
    expect(() => n.softDelete(9999), throwsA(isA<RepositoryException>()));
  });
}
