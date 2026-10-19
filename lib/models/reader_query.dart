import 'list_query.dart';

/// Статус читательского билета для фильтра списка читателей.
enum CardStatus { active, expired }

class ReaderQuery extends ListQuery<ReaderQuery> {
  static const sortFields = {'fullName', 'email', 'expiresAt'};

  @override
  final String search;
  final CardStatus? cardStatus;
  @override
  final String sortField;
  @override
  final bool sortAscending;
  @override
  final int page;
  @override
  final int size;
  @override
  final bool includeDeleted;

  const ReaderQuery({
    this.search = '',
    this.cardStatus,
    this.sortField = 'fullName',
    this.sortAscending = true,
    this.page = 1,
    this.size = 10,
    this.includeDeleted = false,
  });

  factory ReaderQuery.fromParams(Map<String, String> p) {
    final sort = parseSort(p['sort'], sortFields, 'fullName');
    return ReaderQuery(
      search: p['search']?.trim() ?? '',
      cardStatus: switch (p['card']) {
        'active' => CardStatus.active,
        'expired' => CardStatus.expired,
        _ => null,
      },
      sortField: sort.field,
      sortAscending: sort.ascending,
      page: parsePage(p['page']),
      size: parseSize(p['size']),
      includeDeleted: p['includeDeleted'] == 'true',
    );
  }

  ReaderQuery copyWith({
    String? search,
    Object? cardStatus = _unset,
    String? sortField,
    bool? sortAscending,
    int? page,
    int? size,
    bool? includeDeleted,
  }) {
    return ReaderQuery(
      search: search ?? this.search,
      cardStatus: cardStatus == _unset
          ? this.cardStatus
          : cardStatus as CardStatus?,
      sortField: sortField ?? this.sortField,
      sortAscending: sortAscending ?? this.sortAscending,
      page: page ?? 1,
      size: size ?? this.size,
      includeDeleted: includeDeleted ?? this.includeDeleted,
    );
  }

  static const _unset = Object();

  @override
  ReaderQuery withSearch(String value) => copyWith(search: value);
  @override
  ReaderQuery withPage(int value) => copyWith(page: value);
  @override
  ReaderQuery withSize(int value) => copyWith(size: value);
  @override
  ReaderQuery withSort(String field, bool ascending) =>
      copyWith(sortField: field, sortAscending: ascending);
  @override
  ReaderQuery withIncludeDeleted(bool value) => copyWith(includeDeleted: value);

  @override
  Map<String, String> toParams() => {
    if (search.trim().isNotEmpty) 'search': search.trim(),
    if (cardStatus != null) 'card': cardStatus!.name,
    if (sortField != 'fullName' || !sortAscending)
      'sort': '$sortField,${sortAscending ? 'asc' : 'desc'}',
    if (page > 1) 'page': '$page',
    if (size != pageSizes.first) 'size': '$size',
    if (includeDeleted) 'includeDeleted': 'true',
  };
}
