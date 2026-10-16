import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/author.dart';
import '../models/author_query.dart';
import '../state/list_notifiers.dart';
import '../state/reference_notifier.dart';
import '../widgets/entity_list_view.dart';
import '../widgets/entity_table.dart';
import '../widgets/filter_widgets.dart';
import 'books_screen.dart';

/// Список авторов: та же универсальная таблица, другой набор колонок.
class AuthorsScreen extends StatelessWidget {
  final AuthorQuery query;

  const AuthorsScreen({super.key, required this.query});

  @override
  Widget build(BuildContext context) {
    final ref = context.watch<ReferenceNotifier>();

    return EntityListView<Author, AuthorQuery>(
      title: 'Авторы',
      basePath: '/authors',
      notifier: context.read<AuthorsNotifier>(),
      query: query,
      searchHint: 'Поиск по фамилии или стране',
      emptyMessage: 'По заданным условиям авторов не найдено.',
      idOf: (a) => a.id,
      itemPath: (a) => '/authors/${a.id}',
      itemTitle: (a) => 'Автор «${a.fullName}»',
      isDeleted: (a) => a.isDeleted,
      columns: [
        TableColumnSpec<Author>(
          label: 'Автор',
          sortField: 'fullName',
          build: (a) => TitleCell(title: a.fullName, deleted: a.isDeleted),
        ),
        TableColumnSpec<Author>(
          label: 'Страна',
          sortField: 'country',
          build: (a) => Text(a.country),
        ),
        TableColumnSpec<Author>(
          label: 'Год рождения',
          sortField: 'birthYear',
          numeric: true,
          build: (a) => Text('${a.birthYear}'),
        ),
      ],
      filters: (s) => [
        DropdownFilter<String>(
          label: 'Страна',
          value: s.query.country,
          options: [for (final c in ref.countries) (c, c)],
          onChanged: (v) => s.apply((q) => q.copyWith(country: v)),
        ),
      ],
    );
  }
}
