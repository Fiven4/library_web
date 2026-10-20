import 'json_utils.dart';

class LibraryCard {
  final int id;
  final String number;
  final DateTime issuedAt;
  final DateTime expiresAt;

  const LibraryCard({
    required this.id,
    required this.number,
    required this.issuedAt,
    required this.expiresAt,
  });

  bool isExpired([DateTime? now]) => expiresAt.isBefore(now ?? DateTime.now());

  LibraryCard copyWith({
    String? number,
    DateTime? issuedAt,
    DateTime? expiresAt,
  }) {
    return LibraryCard(
      id: id,
      number: number ?? this.number,
      issuedAt: issuedAt ?? this.issuedAt,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'number': number,
    'issuedAt': issuedAt.toIso8601String(),
    'expiresAt': expiresAt.toIso8601String(),
  };

  factory LibraryCard.fromJson(Map<String, dynamic> json) => LibraryCard(
    id: intOf(json['id']),
    number: stringOf(json['number']),
    issuedAt: dateOf(json['issuedAt']) ?? DateTime.utc(1970),
    expiresAt: dateOf(json['expiresAt']) ?? DateTime.utc(1970),
  );
}
