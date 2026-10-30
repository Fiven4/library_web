import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/api_exceptions.dart';
import '../models/app_user.dart';
import '../models/role.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  bool _isLoading = false;
  String? _errorMessage;
  List<AppUser> _users = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final dio = context.read<Dio>();
      final response = await dio.get('/users');
      final data = response.data as Map<String, dynamic>;
      final items = (data['items'] as List<dynamic>?) ?? [];
      setState(() {
        _users = items
            .map((item) => AppUser.fromJson(item as Map<String, dynamic>))
            .toList();
      });
    } catch (e) {
      setState(() {
        if (e is ForbiddenException) {
          _errorMessage =
              'Доступ к разделу пользователей запрещён сервером (403 Forbidden).';
        } else if (e is ApiException) {
          _errorMessage = e.message;
        } else {
          _errorMessage = 'Ошибка загрузки пользователей: $e';
        }
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Color _roleColor(Role role, ThemeData theme) {
    switch (role) {
      case Role.admin:
        return Colors.red.shade700;
      case Role.librarian:
        return Colors.blue.shade700;
      case Role.reader:
        return Colors.green.shade700;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final filteredUsers = _users.where((u) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return u.username.toLowerCase().contains(q) ||
          u.fullName.toLowerCase().contains(q) ||
          u.email.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.admin_panel_settings_outlined),
            SizedBox(width: 8),
            Text('Управление пользователями (Администратор)'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Обновить список',
            onPressed: _fetchUsers,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Всего пользователей',
                            style: theme.textTheme.labelMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_users.length}',
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Читатели', style: theme.textTheme.labelMedium),
                          const SizedBox(height: 4),
                          Text(
                            '${_users.where((u) => u.role == Role.reader).length}',
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Библиотекари',
                            style: theme.textTheme.labelMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_users.where((u) => u.role == Role.librarian).length}',
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Администраторы',
                            style: theme.textTheme.labelMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_users.where((u) => u.role == Role.admin).length}',
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.red.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                hintText: 'Поиск пользователей по логину, имени или email...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (val) => setState(() => _searchQuery = val.trim()),
            ),
            const SizedBox(height: 16),
            if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: theme.colorScheme.error),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(
                          color: theme.colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if (_isLoading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else if (_errorMessage == null)
              Expanded(
                child: Card(
                  clipBehavior: Clip.antiAlias,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minWidth: 800),
                        child: DataTable(
                          columns: const [
                            DataColumn(label: Text('ID')),
                            DataColumn(label: Text('Логин')),
                            DataColumn(label: Text('ФИО')),
                            DataColumn(label: Text('Email')),
                            DataColumn(label: Text('Роль')),
                            DataColumn(label: Text('Читательский билет')),
                          ],
                          rows: filteredUsers.map((user) {
                            final roleColor = _roleColor(user.role, theme);
                            return DataRow(
                              cells: [
                                DataCell(Text('#${user.id}')),
                                DataCell(
                                  Text(
                                    user.username,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                DataCell(Text(user.fullName)),
                                DataCell(
                                  Text(user.email.isEmpty ? '—' : user.email),
                                ),
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: roleColor.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: roleColor),
                                    ),
                                    child: Text(
                                      user.role.label,
                                      style: TextStyle(
                                        color: roleColor,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    user.readerId != null
                                        ? '№${user.readerId}'
                                        : '—',
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
