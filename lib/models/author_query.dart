import 'list_query.dart';

class AuthorQuery extends ListQuery<AuthorQuery> {
  static const sortFields = {'fullName', 'birthYear', 'country'};

  @override
  final String search;
  final String? country;
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

  const AuthorQuery({
    this.search = '',
    this.country,
    this.sortField = 'fullName',
    this.sortAscending = true,
    this.page = 1,
    this.size = 10,
    this.includeDeleted = false,
  });

  factory AuthorQuery.fromParams(Map<String, String> p) {
    final sort = parseSort(p['sort'], sortFields, 'fullName');
    final country = p['country']?.trim();
    return AuthorQuery(
      search: p['search']?.trim() ?? '',
      country: (country == null || country.isEmpty) ? null : country,
      sortField: sort.field,
      sortAscending: sort.ascending,
      page: parsePage(p['page']),
      size: parseSize(p['size']),
      includeDeleted: p['includeDeleted'] == 'true',
    );
  }

  AuthorQuery copyWith({
    String? search,
    Object? country = _unset,
    String? sortField,
    bool? sortAscending,
    int? page,
    int? size,
    bool? includeDeleted,
  }) {
    return AuthorQuery(
      search: search ?? this.search,
      country: country == _unset ? this.country : country as String?,
      sortField: sortField ?? this.sortField,
      sortAscending: sortAscending ?? this.sortAscending,
      page: page ?? 1,
      size: size ?? this.size,
      includeDeleted: includeDeleted ?? this.includeDeleted,
    );
  }

  static const _unset = Object();

  @override
  AuthorQuery withSearch(String value) => copyWith(search: value);
  @override
  AuthorQuery withPage(int value) => copyWith(page: value);
  @override
  AuthorQuery withSize(int value) => copyWith(size: value);
  @override
  AuthorQuery withSort(String field, bool ascending) =>
      copyWith(sortField: field, sortAscending: ascending);
  @override
  AuthorQuery withIncludeDeleted(bool value) => copyWith(includeDeleted: value);

  @override
  Map<String, String> toParams() => {
    if (search.trim().isNotEmpty) 'search': search.trim(),
    'country': ?country,
    if (sortField != 'fullName' || !sortAscending)
      'sort': '$sortField,${sortAscending ? 'asc' : 'desc'}',
    if (page > 1) 'page': '$page',
    if (size != pageSizes.first) 'size': '$size',
    if (includeDeleted) 'includeDeleted': 'true',
  };
}
