import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/book.dart';
import '../models/book_query.dart';
import '../state/list_notifiers.dart';
import '../state/reference_notifier.dart';
import '../widgets/entity_list_view.dart';
import '../widgets/entity_table.dart';
import '../widgets/filter_widgets.dart';

/// Список книг. Экран описывает только колонки и фильтры, всё остальное
/// делает универсальный [EntityListView].
class BooksScreen extends StatelessWidget {
  final BookQuery query;

  const BooksScreen({super.key, required this.query});

  @override
  Widget build(BuildContext context) {
    final ref = context.watch<ReferenceNotifier>();

    return EntityListView<Book, BookQuery>(
      title: 'Книги',
      basePath: '/books',
      notifier: context.read<BooksNotifier>(),
      query: query,
      searchHint: 'Поиск по названию или ISBN',
      emptyMessage: 'По заданным условиям книг не найдено.',
      idOf: (b) => b.id,
      itemPath: (b) => '/books/${b.id}',
      itemTitle: (b) => 'Книга «${b.title}»',
      isDeleted: (b) => b.isDeleted,
      columns: [
        TableColumnSpec<Book>(
          label: 'Название',
          sortField: 'title',
          build: (b) => TitleCell(title: b.title, deleted: b.isDeleted),
        ),
        TableColumnSpec<Book>(
          label: 'Авторы',
          build: (b) => CellText(ref.authorNames(b.authorIds)),
        ),
        TableColumnSpec<Book>(
          label: 'Жанры',
          build: (b) => CellText(ref.genreNames(b.genreIds)),
        ),
        TableColumnSpec<Book>(
          label: 'Издательство',
          build: (b) => CellText(ref.publisherName(b.publisherId)),
        ),
        TableColumnSpec<Book>(
          label: 'Год',
          sortField: 'year',
          numeric: true,
          build: (b) => Text('${b.year}'),
        ),
        TableColumnSpec<Book>(
          label: 'Страниц',
          sortField: 'pages',
          numeric: true,
          build: (b) => Text('${b.pages}'),
        ),
        TableColumnSpec<Book>(
          label: 'Доступно',
          numeric: true,
          build: (b) => Text('${b.copiesAvailable}/${b.copiesTotal}'),
        ),
      ],
      filters: (s) => [
        DropdownFilter<int>(
          label: 'Жанр',
          value: s.query.genreId,
          options: [for (final g in ref.genres) (g.id, g.name)],
          onChanged: (v) => s.apply((q) => q.copyWith(genreId: v)),
        ),
        DropdownFilter<int>(
          label: 'Издательство',
          value: s.query.publisherId,
          options: [for (final p in ref.publishers) (p.id, p.name)],
          onChanged: (v) => s.apply((q) => q.copyWith(publisherId: v)),
        ),
        NumberFilterField(
          key: const ValueKey('year-from'),
          label: 'Год от',
          value: s.query.yearFrom,
          onChanged: (v) => s.applyDebounced((q) => q.copyWith(yearFrom: v)),
        ),
        NumberFilterField(
          key: const ValueKey('year-to'),
          label: 'Год до',
          value: s.query.yearTo,
          onChanged: (v) => s.applyDebounced((q) => q.copyWith(yearTo: v)),
        ),
      ],
    );
  }
}

/// Текст ячейки не шире 260 пикселей, длинное значение переносится.
class CellText extends StatelessWidget {
  final String text;

  const CellText(this.text, {super.key});

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 170),
    child: Text(text, maxLines: 2, overflow: TextOverflow.ellipsis),
  );
}

/// Название с пометкой для логически удалённой записи.
class TitleCell extends StatelessWidget {
  final String title;
  final bool deleted;

  const TitleCell({super.key, required this.title, required this.deleted});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 230),
      child: Wrap(
        spacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(title),
          if (deleted)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: scheme.errorContainer,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'удалена',
                style: TextStyle(fontSize: 12, color: scheme.onErrorContainer),
              ),
            ),
        ],
      ),
    );
  }
}
