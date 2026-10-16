class Author {
  final int id;
  final String fullName;
  final int birthYear;
  final String country;
  final DateTime? deletedAt;

  const Author({
    required this.id,
    required this.fullName,
    required this.birthYear,
    required this.country,
    this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;

  Author copyWith({
    String? fullName,
    int? birthYear,
    String? country,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return Author(
      id: id,
      fullName: fullName ?? this.fullName,
      birthYear: birthYear ?? this.birthYear,
      country: country ?? this.country,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }
}
