/// Справочники, на которые ссылаются книги.
class Genre {
  final int id;
  final String name;
  final String description;

  const Genre({
    required this.id,
    required this.name,
    required this.description,
  });
}

class Publisher {
  final int id;
  final String name;
  final String city;
  final int foundedYear;

  const Publisher({
    required this.id,
    required this.name,
    required this.city,
    required this.foundedYear,
  });
}
