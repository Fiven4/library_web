import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/genre.dart';
import '../models/genre_query.dart';
import '../state/list_notifiers.dart';
import '../widgets/entity_list_view.dart';
import '../widgets/entity_table.dart';
import 'books_screen.dart';

class GenresScreen extends StatelessWidget {
  final GenreQuery query;

  const GenresScreen({super.key, required this.query});

  @override
  Widget build(BuildContext context) {
    return EntityListView<Genre, GenreQuery>(
      title: 'Жанры',
      basePath: '/genres',
      notifier: context.read<GenresNotifier>(),
      query: query,
      searchHint: 'Поиск по названию или описанию',
      emptyMessage: 'По заданным условиям жанров не найдено.',
      idOf: (g) => g.id,
      itemPath: (g) => '/genres/${g.id}',
      createPath: '/genres/new',
      editPath: (g) => '/genres/${g.id}/edit',
      itemTitle: (g) => 'Жанр «${g.name}»',
      isDeleted: (g) => g.isDeleted,
      columns: [
        TableColumnSpec<Genre>(
          label: 'Название',
          sortField: 'name',
          build: (g) => TitleCell(title: g.name, deleted: g.isDeleted),
        ),
        TableColumnSpec<Genre>(
          label: 'Описание',
          sortField: 'description',
          build: (g) => CellText(g.description.isEmpty ? '—' : g.description),
        ),
        TableColumnSpec<Genre>(
          label: 'Код',
          sortField: 'id',
          numeric: true,
          build: (g) => Text('${g.id}'),
        ),
      ],
    );
  }
}
