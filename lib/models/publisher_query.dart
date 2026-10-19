import 'list_query.dart';

class PublisherQuery extends ListQuery<PublisherQuery> {
  static const sortFields = {'name', 'city', 'foundedYear'};

  @override
  final String search;
  final String? city;
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

  const PublisherQuery({
    this.search = '',
    this.city,
    this.sortField = 'name',
    this.sortAscending = true,
    this.page = 1,
    this.size = 10,
    this.includeDeleted = false,
  });

  factory PublisherQuery.fromParams(Map<String, String> p) {
    final sort = parseSort(p['sort'], sortFields, 'name');
    final city = p['city']?.trim();
    return PublisherQuery(
      search: p['search']?.trim() ?? '',
      city: (city == null || city.isEmpty) ? null : city,
      sortField: sort.field,
      sortAscending: sort.ascending,
      page: parsePage(p['page']),
      size: parseSize(p['size']),
      includeDeleted: p['includeDeleted'] == 'true',
    );
  }

  PublisherQuery copyWith({
    String? search,
    Object? city = _unset,
    String? sortField,
    bool? sortAscending,
    int? page,
    int? size,
    bool? includeDeleted,
  }) {
    return PublisherQuery(
      search: search ?? this.search,
      city: city == _unset ? this.city : city as String?,
      sortField: sortField ?? this.sortField,
      sortAscending: sortAscending ?? this.sortAscending,
      page: page ?? 1,
      size: size ?? this.size,
      includeDeleted: includeDeleted ?? this.includeDeleted,
    );
  }

  static const _unset = Object();

  @override
  PublisherQuery withSearch(String value) => copyWith(search: value);
  @override
  PublisherQuery withPage(int value) => copyWith(page: value);
  @override
  PublisherQuery withSize(int value) => copyWith(size: value);
  @override
  PublisherQuery withSort(String field, bool ascending) =>
      copyWith(sortField: field, sortAscending: ascending);
  @override
  PublisherQuery withIncludeDeleted(bool value) =>
      copyWith(includeDeleted: value);

  @override
  Map<String, String> toParams() => {
    if (search.trim().isNotEmpty) 'search': search.trim(),
    'city': ?city,
    if (sortField != 'name' || !sortAscending)
      'sort': '$sortField,${sortAscending ? 'asc' : 'desc'}',
    if (page > 1) 'page': '$page',
    if (size != pageSizes.first) 'size': '$size',
    if (includeDeleted) 'includeDeleted': 'true',
  };
}
