import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/publisher.dart';
import '../models/publisher_query.dart';
import '../state/list_notifiers.dart';
import '../state/reference_notifier.dart';
import '../widgets/entity_list_view.dart';
import '../widgets/entity_table.dart';
import '../widgets/filter_widgets.dart';
import 'books_screen.dart';

class PublishersScreen extends StatelessWidget {
  final PublisherQuery query;

  const PublishersScreen({super.key, required this.query});

  @override
  Widget build(BuildContext context) {
    final ref = context.watch<ReferenceNotifier>();

    return EntityListView<Publisher, PublisherQuery>(
      title: 'Издательства',
      basePath: '/publishers',
      notifier: context.read<PublishersNotifier>(),
      query: query,
      searchHint: 'Поиск по названию или городу',
      emptyMessage: 'По заданным условиям издательств не найдено.',
      idOf: (p) => p.id,
      itemPath: (p) => '/publishers/${p.id}',
      createPath: '/publishers/new',
      editPath: (p) => '/publishers/${p.id}/edit',
      itemTitle: (p) => 'Издательство «${p.name}»',
      isDeleted: (p) => p.isDeleted,
      columns: [
        TableColumnSpec<Publisher>(
          label: 'Название',
          sortField: 'name',
          build: (p) => TitleCell(title: p.name, deleted: p.isDeleted),
        ),
        TableColumnSpec<Publisher>(
          label: 'Город',
          sortField: 'city',
          build: (p) => Text(p.city),
        ),
        TableColumnSpec<Publisher>(
          label: 'Основано',
          sortField: 'foundedYear',
          numeric: true,
          build: (p) => Text('${p.foundedYear}'),
        ),
      ],
      filters: (s) => [
        DropdownFilter<String>(
          label: 'Город',
          value: s.query.city,
          options: [for (final c in ref.cities) (c, c)],
          onChanged: (v) => s.apply((q) => q.copyWith(city: v)),
        ),
      ],
    );
  }
}
