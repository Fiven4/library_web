import 'list_query.dart';

class GenreQuery extends ListQuery<GenreQuery> {
  static const sortFields = {'name', 'description', 'id'};

  @override
  final String search;
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

  const GenreQuery({
    this.search = '',
    this.sortField = 'name',
    this.sortAscending = true,
    this.page = 1,
    this.size = 10,
    this.includeDeleted = false,
  });

  factory GenreQuery.fromParams(Map<String, String> p) {
    final sort = parseSort(p['sort'], sortFields, 'name');
    return GenreQuery(
      search: p['search']?.trim() ?? '',
      sortField: sort.field,
      sortAscending: sort.ascending,
      page: parsePage(p['page']),
      size: parseSize(p['size']),
      includeDeleted: p['includeDeleted'] == 'true',
    );
  }

  GenreQuery copyWith({
    String? search,
    String? sortField,
    bool? sortAscending,
    int? page,
    int? size,
    bool? includeDeleted,
  }) {
    return GenreQuery(
      search: search ?? this.search,
      sortField: sortField ?? this.sortField,
      sortAscending: sortAscending ?? this.sortAscending,
      page: page ?? 1,
      size: size ?? this.size,
      includeDeleted: includeDeleted ?? this.includeDeleted,
    );
  }

  @override
  GenreQuery withSearch(String value) => copyWith(search: value);
  @override
  GenreQuery withPage(int value) => copyWith(page: value);
  @override
  GenreQuery withSize(int value) => copyWith(size: value);
  @override
  GenreQuery withSort(String field, bool ascending) =>
      copyWith(sortField: field, sortAscending: ascending);
  @override
  GenreQuery withIncludeDeleted(bool value) => copyWith(includeDeleted: value);

  @override
  Map<String, String> toParams() => {
    if (search.trim().isNotEmpty) 'search': search.trim(),
    if (sortField != 'name' || !sortAscending)
      'sort': '$sortField,${sortAscending ? 'asc' : 'desc'}',
    if (page > 1) 'page': '$page',
    if (size != pageSizes.first) 'size': '$size',
    if (includeDeleted) 'includeDeleted': 'true',
  };
}
