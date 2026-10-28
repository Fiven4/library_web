import 'json_utils.dart';
import 'role.dart';

class AppUser {
  final int id;
  final String username;
  final String fullName;
  final String email;
  final Role role;
  final int? readerId;
  final String? createdAt;

  const AppUser({
    required this.id,
    required this.username,
    required this.fullName,
    required this.email,
    required this.role,
    this.readerId,
    this.createdAt,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: intOf(json['id']),
      username: stringOf(json['username']),
      fullName: stringOf(json['fullName'], stringOf(json['username'])),
      email: stringOf(json['email']),
      role: Role.fromString(json['role'] as String?),
      readerId: json['readerId'] != null ? intOf(json['readerId']) : null,
      createdAt: json['createdAt'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'username': username,
    'fullName': fullName,
    'email': email,
    'role': role.value,
    if (readerId != null) 'readerId': readerId,
    if (createdAt != null) 'createdAt': createdAt,
  };

  AppUser copyWith({
    int? id,
    String? username,
    String? fullName,
    String? email,
    Role? role,
    int? readerId,
    String? createdAt,
  }) {
    return AppUser(
      id: id ?? this.id,
      username: username ?? this.username,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      role: role ?? this.role,
      readerId: readerId ?? this.readerId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppUser &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          username == other.username &&
          role == other.role;

  @override
  int get hashCode => id.hashCode ^ username.hashCode ^ role.hashCode;
}
