import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/api_exceptions.dart';
import '../state/auth_notifier.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  String _currentPassword = '';
  bool get _hasMinLength => _currentPassword.length >= 8;
  bool get _hasDigit => RegExp(r'\d').hasMatch(_currentPassword);
  bool get _hasSpecialChar =>
      RegExp(r'[!@#$%^&*(),.?":{}|<>\-_]').hasMatch(_currentPassword);
  bool get _isPasswordValid => _hasMinLength && _hasDigit && _hasSpecialChar;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(() {
      setState(() {
        _currentPassword = _passwordController.text;
      });
    });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_isPasswordValid) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final auth = context.read<AuthNotifier>();
      await auth.register(
        _usernameController.text.trim(),
        _passwordController.text,
        email: _emailController.text.trim(),
        fullName: _fullNameController.text.trim(),
      );

      if (!mounted) return;
      context.go('/books');
    } catch (e) {
      setState(() {
        if (e is ValidationException) {
          _errorMessage = e.errors.values.join('\n');
        } else if (e is ApiException) {
          _errorMessage = e.message;
        } else {
          _errorMessage = 'Ошибка регистрации: $e';
        }
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildRequirement(String text, bool met) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            met ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 16,
            color: met ? Colors.green : Colors.grey,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: met ? Colors.green.shade800 : Colors.grey.shade700,
              fontWeight: met ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Icon(
                        Icons.person_add_rounded,
                        size: 52,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Регистрация читателя',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Создание нового аккаунта в библиотечной системе',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (_errorMessage != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.errorContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(
                              color: theme.colorScheme.onErrorContainer,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      TextFormField(
                        key: const Key('reg-username-field'),
                        controller: _usernameController,
                        decoration: const InputDecoration(
                          labelText: 'Логин *',
                          prefixIcon: Icon(Icons.account_circle_outlined),
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Введите логин';
                          }
                          if (v.trim().length < 3) {
                            return 'Не менее 3 символов';
                          }
                          return null;
                        },
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        key: const Key('reg-fullname-field'),
                        controller: _fullNameController,
                        decoration: const InputDecoration(
                          labelText: 'ФИО',
                          prefixIcon: Icon(Icons.badge_outlined),
                          border: OutlineInputBorder(),
                        ),
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        key: const Key('reg-email-field'),
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'Адрес электронной почты',
                          prefixIcon: Icon(Icons.email_outlined),
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) {
                          if (v != null && v.trim().isNotEmpty) {
                            if (!RegExp(
                              r'^[\w.+-]+@[\w-]+\.[\w.-]+$',
                            ).hasMatch(v.trim())) {
                              return 'Некорректный формат email';
                            }
                          }
                          return null;
                        },
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        key: const Key('reg-password-field'),
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Пароль *',
                          prefixIcon: const Icon(Icons.lock_outline),
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                            onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'Введите пароль';
                          }
                          if (!_isPasswordValid) {
                            return 'Пароль не отвечает требованиям безопасности';
                          }
                          return null;
                        },
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest
                              .withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _isPasswordValid
                                ? Colors.green.shade400
                                : theme.dividerColor,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Требования к паролю:',
                              style: theme.textTheme.labelMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            _buildRequirement(
                              'Не менее 8 символов',
                              _hasMinLength,
                            ),
                            _buildRequirement('Хотя бы одна цифра', _hasDigit),
                            _buildRequirement(
                              'Хотя бы один спецсимвол (!@#\$%^&*...)',
                              _hasSpecialChar,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        key: const Key('reg-confirm-password-field'),
                        controller: _confirmPasswordController,
                        obscureText: _obscurePassword,
                        decoration: const InputDecoration(
                          labelText: 'Подтверждение пароля *',
                          prefixIcon: Icon(Icons.lock_reset_outlined),
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) {
                          if (v != _passwordController.text) {
                            return 'Пароли не совпадают';
                          }
                          return null;
                        },
                        onFieldSubmitted: (_) => _submit(),
                      ),
                      const SizedBox(height: 22),
                      FilledButton(
                        key: const Key('reg-submit-btn'),
                        onPressed: _isLoading ? null : _submit,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Зарегистрироваться',
                                style: TextStyle(fontSize: 16),
                              ),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          const Text('Уже есть аккаунт?'),
                          TextButton(
                            key: const Key('reg-to-login-btn'),
                            onPressed: () => context.go('/login'),
                            child: const Text('Войти'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
