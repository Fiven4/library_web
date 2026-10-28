enum Role {
  reader('reader', 1, 'Читатель'),
  librarian('librarian', 2, 'Библиотекарь'),
  admin('admin', 3, 'Администратор');

  final String value;
  final int level;
  final String label;

  const Role(this.value, this.level, this.label);

  static Role fromString(String? val) {
    if (val == null) return Role.reader;
    for (final role in Role.values) {
      if (role.value == val.toLowerCase()) return role;
    }
    return Role.reader;
  }

  bool canAccess(Role minRole) => level >= minRole.level;
}
