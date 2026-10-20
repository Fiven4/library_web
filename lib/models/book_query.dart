import 'list_query.dart';

class BookQuery extends ListQuery<BookQuery> {
  static const sortFields = {'title', 'year', 'pages'};

  @override
  final String search;
  final int? genreId;
  final int? publisherId;
  final int? authorId;
  final int? yearFrom;
  final int? yearTo;
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

  const BookQuery({
    this.search = '',
    this.genreId,
    this.publisherId,
    this.authorId,
    this.yearFrom,
    this.yearTo,
    this.sortField = 'title',
    this.sortAscending = true,
    this.page = 1,
    this.size = 10,
    this.includeDeleted = false,
  });

  factory BookQuery.fromParams(Map<String, String> p) {
    final sort = parseSort(p['sort'], sortFields, 'title');
    return BookQuery(
      search: p['search']?.trim() ?? '',
      genreId: int.tryParse(p['genreId'] ?? ''),
      publisherId: int.tryParse(p['publisherId'] ?? ''),
      authorId: int.tryParse(p['authorId'] ?? ''),
      yearFrom: int.tryParse(p['yearFrom'] ?? ''),
      yearTo: int.tryParse(p['yearTo'] ?? ''),
      sortField: sort.field,
      sortAscending: sort.ascending,
      page: parsePage(p['page']),
      size: parseSize(p['size']),
      includeDeleted: p['includeDeleted'] == 'true',
    );
  }

  BookQuery copyWith({
    String? search,
    Object? genreId = _unset,
    Object? publisherId = _unset,
    Object? authorId = _unset,
    Object? yearFrom = _unset,
    Object? yearTo = _unset,
    String? sortField,
    bool? sortAscending,
    int? page,
    int? size,
    bool? includeDeleted,
  }) {
    return BookQuery(
      search: search ?? this.search,
      genreId: genreId == _unset ? this.genreId : genreId as int?,
      publisherId: publisherId == _unset
          ? this.publisherId
          : publisherId as int?,
      authorId: authorId == _unset ? this.authorId : authorId as int?,
      yearFrom: yearFrom == _unset ? this.yearFrom : yearFrom as int?,
      yearTo: yearTo == _unset ? this.yearTo : yearTo as int?,
      sortField: sortField ?? this.sortField,
      sortAscending: sortAscending ?? this.sortAscending,
      page: page ?? 1,
      size: size ?? this.size,
      includeDeleted: includeDeleted ?? this.includeDeleted,
    );
  }

  static const _unset = Object();

  @override
  BookQuery withSearch(String value) => copyWith(search: value);
  @override
  BookQuery withPage(int value) => copyWith(page: value);
  @override
  BookQuery withSize(int value) => copyWith(size: value);
  @override
  BookQuery withSort(String field, bool ascending) =>
      copyWith(sortField: field, sortAscending: ascending);
  @override
  BookQuery withIncludeDeleted(bool value) => copyWith(includeDeleted: value);

  @override
  Map<String, String> toParams() => {
    if (search.trim().isNotEmpty) 'search': search.trim(),
    if (genreId != null) 'genreId': '$genreId',
    if (publisherId != null) 'publisherId': '$publisherId',
    if (authorId != null) 'authorId': '$authorId',
    if (yearFrom != null) 'yearFrom': '$yearFrom',
    if (yearTo != null) 'yearTo': '$yearTo',
    if (sortField != 'title' || !sortAscending)
      'sort': '$sortField,${sortAscending ? 'asc' : 'desc'}',
    if (page > 1) 'page': '$page',
    if (size != pageSizes.first) 'size': '$size',
    if (includeDeleted) 'includeDeleted': 'true',
  };
}
