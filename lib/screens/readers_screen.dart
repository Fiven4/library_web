import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/format.dart';
import '../models/reader.dart';
import '../models/reader_query.dart';
import '../state/list_notifiers.dart';
import '../widgets/entity_list_view.dart';
import '../widgets/entity_table.dart';
import '../widgets/filter_widgets.dart';
import 'books_screen.dart';

class ReadersScreen extends StatelessWidget {
  final ReaderQuery query;

  const ReadersScreen({super.key, required this.query});

  @override
  Widget build(BuildContext context) {
    return EntityListView<Reader, ReaderQuery>(
      title: 'Читатели',
      basePath: '/readers',
      notifier: context.read<ReadersNotifier>(),
      query: query,
      searchHint: 'Поиск по ФИО, почте, телефону или номеру билета',
      emptyMessage: 'По заданным условиям читателей не найдено.',
      idOf: (r) => r.id,
      itemPath: (r) => '/readers/${r.id}',
      createPath: '/readers/new',
      editPath: (r) => '/readers/${r.id}/edit',
      itemTitle: (r) => 'Читатель «${r.fullName}»',
      isDeleted: (r) => r.isDeleted,
      columns: [
        TableColumnSpec<Reader>(
          label: 'ФИО',
          sortField: 'fullName',
          build: (r) => TitleCell(title: r.fullName, deleted: r.isDeleted),
        ),
        TableColumnSpec<Reader>(
          label: 'Почта',
          sortField: 'email',
          build: (r) => Text(r.email),
        ),
        TableColumnSpec<Reader>(
          label: 'Телефон',
          build: (r) => Text(r.phone.isEmpty ? '—' : r.phone),
        ),
        TableColumnSpec<Reader>(
          label: 'Билет',
          build: (r) => Text(r.card.number),
        ),
        TableColumnSpec<Reader>(
          label: 'Действует до',
          sortField: 'expiresAt',
          build: (r) => _Expiry(r),
        ),
      ],
      filters: (s) => [
        DropdownFilter<CardStatus>(
          label: 'Билет',
          value: s.query.cardStatus,
          options: const [
            (CardStatus.active, 'Действующий'),
            (CardStatus.expired, 'Истёк'),
          ],
          onChanged: (v) => s.apply((q) => q.copyWith(cardStatus: v)),
        ),
      ],
    );
  }
}

class _Expiry extends StatelessWidget {
  final Reader reader;

  const _Expiry(this.reader);

  @override
  Widget build(BuildContext context) {
    final expired = reader.card.isExpired();
    return Wrap(
      spacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(formatDate(reader.card.expiresAt)),
        if (expired)
          Text(
            'истёк',
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.error,
            ),
          ),
      ],
    );
  }
}
