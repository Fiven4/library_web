import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/breakpoints.dart';
import '../../state/entity_form_notifier.dart';
import '../../state/load_status.dart';
import '../state_views.dart';
import 'field_specs.dart';

/// Универсальная форма создания и изменения записи.
///
/// Описание полей задаётся списком [FieldSpec], а сам виджет общий для всех
/// сущностей: он выводит поля, показывает ошибки под каждым полем, проверяет
/// форму, отправляет данные через [EntityFormNotifier], показывает ошибки
/// сервера (например, «ISBN уже существует») в соответствующих полях и
/// предупреждает о несохранённых изменениях при попытке уйти с экрана.
class EntityFormView<T> extends StatefulWidget {
  final EntityFormNotifier<T> notifier;
  final String createTitle;
  final String Function(T item) editTitle;
  final String listPath;
  final List<FieldSpec> Function(bool isEditing) specs;
  final FormValues Function(T? item) initialValues;
  final T Function(FormValues values, T? existing) build;

  const EntityFormView({
    super.key,
    required this.notifier,
    required this.createTitle,
    required this.editTitle,
    required this.listPath,
    required this.specs,
    required this.initialValues,
    required this.build,
  });

  @override
  State<EntityFormView<T>> createState() => _EntityFormViewState<T>();
}

class _EntityFormViewState<T> extends State<EntityFormView<T>> {
  final _formKey = GlobalKey<FormState>();
  FormValues _values = {};
  FormValues _initial = {};
  bool _inited = false;
  bool _leaving = false;

  /// Значение поля в момент, когда сервер вернул для него ошибку. Ошибка
  /// показывается, только пока значение не изменилось.
  final Map<String, String> _errorValues = {};

  EntityFormNotifier<T> get _notifier => widget.notifier;

  static FormValues _copy(FormValues v) => {
    for (final e in v.entries)
      e.key: e.value is List ? List<Object?>.of(e.value as List) : e.value,
  };

  static bool _same(Object? a, Object? b) {
    if (a is List && b is List) {
      return a.length == b.length &&
          [
            for (var i = 0; i < a.length; i++) _same(a[i], b[i]),
          ].every((x) => x);
    }
    return a == b;
  }

  bool get _dirty {
    if (!_inited) return false;
    final keys = {..._values.keys, ..._initial.keys};
    return keys.any((k) => !_same(_values[k], _initial[k]));
  }

  void _set(String key, Object? value) {
    setState(() => _values[key] = value);
  }

  String _snapshot(Object? v) => '$v';

  String? _serverError(String key, Object? value) {
    final error = _notifier.fieldErrors[key];
    if (error != null && _errorValues[key] == _snapshot(value)) return error;
    return null;
  }

  void _pop() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(widget.listPath);
    }
  }

  Future<void> _askLeave() async {
    if (!_dirty) {
      _pop();
      return;
    }
    final leave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Несохранённые изменения'),
        content: const Text(
          'Введённые данные будут потеряны. Уйти без сохранения?',
        ),
        actions: [
          TextButton(
            key: const ValueKey('stay'),
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Остаться'),
          ),
          FilledButton(
            key: const ValueKey('leave'),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Уйти'),
          ),
        ],
      ),
    );
    if (leave == true && mounted) {
      setState(() => _leaving = true);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _pop();
      });
    }
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _submit() async {
    final form = _formKey.currentState!;
    if (!form.validate()) {
      _toast('Исправьте ошибки в форме');
      return;
    }
    final saved = await _notifier.submit(widget.build(_values, _notifier.item));
    if (!mounted) return;
    if (saved == null) {
      // Ошибки сервера записываем рядом со значениями и показываем в полях.
      for (final key in _notifier.fieldErrors.keys) {
        _errorValues[key] = _snapshot(_values[key]);
      }
      form.validate();
      return;
    }
    _toast(_notifier.isEditing ? 'Изменения сохранены' : 'Запись создана');
    setState(() => _leaving = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    final compact = screenSizeOf(context) == ScreenSize.compact;
    return PopScope(
      canPop: _leaving || !_dirty,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _askLeave();
      },
      child: Padding(
        padding: EdgeInsets.all(compact ? 12 : 24),
        child: ListenableBuilder(
          listenable: _notifier,
          builder: (context, _) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  key: const ValueKey('back-button'),
                  onPressed: _askLeave,
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('К списку'),
                ),
              ),
              Expanded(child: _body(context)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body(BuildContext context) {
    if (_notifier.status == LoadStatus.error) {
      return ErrorView(
        message: _notifier.error ?? 'Ошибка',
        onRetry: _notifier.load,
      );
    }
    if (_notifier.status != LoadStatus.success) return const LoadingView();
    if (_notifier.notFound) {
      return const EmptyView(
        message: 'Запись не найдена или удалена навсегда.',
      );
    }

    // Поля заполняются один раз, когда запись уже загружена: так форма
    // редактирования не открывается пустой.
    if (!_inited) {
      _values = _copy(widget.initialValues(_notifier.item));
      _initial = _copy(_values);
      _inited = true;
    }

    final theme = Theme.of(context);
    final editing = _notifier.isEditing;
    final specs = widget.specs(editing);
    return SingleChildScrollView(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Form(
            key: _formKey,
            // Поля проверяются по отдельности после первого взаимодействия,
            // а вся форма целиком только при отправке.
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  editing
                      ? widget.editTitle(_notifier.item as T)
                      : widget.createTitle,
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                if (_notifier.error != null)
                  Container(
                    key: const ValueKey('form-error'),
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _notifier.error!,
                      style: TextStyle(
                        color: theme.colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
                for (final spec in specs) ..._field(spec),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    FilledButton.icon(
                      key: const ValueKey('submit-button'),
                      onPressed: _notifier.saving ? null : _submit,
                      icon: _notifier.saving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save_outlined),
                      label: Text(editing ? 'Сохранить' : 'Создать'),
                    ),
                    OutlinedButton(
                      key: const ValueKey('cancel-button'),
                      onPressed: _askLeave,
                      child: const Text('Отмена'),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _field(FieldSpec spec) {
    const gap = SizedBox(height: 16);
    return switch (spec) {
      TextSpec() => [_TextInput(spec: spec, state: this), gap],
      DateSpec() => [_DateInput(spec: spec, state: this), gap],
      DropdownSpec() => [_buildDropdown(spec), gap],
      MultiSpec() => [_buildMulti(spec), gap],
      SwitchSpec() => [
        SwitchListTile(
          key: ValueKey('switch-${spec.key}'),
          contentPadding: EdgeInsets.zero,
          dense: true,
          title: Text(spec.label),
          value: _values[spec.key] as bool? ?? false,
          onChanged: (v) => _set(spec.key, v),
        ),
      ],
      GroupSpec() => [_group(spec), gap],
    };
  }

  Widget _group(GroupSpec spec) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(spec.title, style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          for (final f in spec.fields) ..._field(f),
        ],
      ),
    );
  }

  Widget _buildDropdown(DropdownSpec spec) {
    final options = spec.options(_values);
    var value = _values[spec.key] as int?;
    // Значение должно присутствовать в списке, иначе DropdownButton
    // выбросит исключение.
    if (value != null && !options.any((o) => o.$1 == value)) {
      value = null;
      _values[spec.key] = null;
    }
    return DropdownButtonFormField<int>(
      // Ключ пересоздаёт поле при смене значения или списка (каскад).
      key: ValueKey(
        'dd-${spec.key}-$value-${options.map((o) => o.$1).join(',')}',
      ),
      initialValue: value,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: spec.required ? '${spec.label} *' : spec.label,
        border: const OutlineInputBorder(),
      ),
      items: [
        for (final o in options)
          DropdownMenuItem(
            value: o.$1,
            child: Text(o.$2, overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: (v) {
        _notifier.clearFieldError(spec.key);
        _set(spec.key, v);
      },
      validator: (v) {
        if (spec.required && v == null) {
          return spec.requiredMessage ?? 'Выберите значение';
        }
        return _serverError(spec.key, v);
      },
    );
  }

  Widget _buildMulti(MultiSpec spec) {
    final options = spec.options(_values);
    final current = List<int>.of(
      (_values[spec.key] as List?)?.cast<int>() ?? const [],
    );
    return FormField<List<int>>(
      key: ValueKey('multi-${spec.key}-${options.map((o) => o.$1).join(',')}'),
      initialValue: current,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      validator: (value) {
        if (spec.required && (value == null || value.isEmpty)) {
          return spec.requiredMessage ?? 'Выберите хотя бы одно значение';
        }
        return _serverError(spec.key, value);
      },
      builder: (field) {
        return InputDecorator(
          decoration: InputDecoration(
            labelText: spec.required ? '${spec.label} *' : spec.label,
            border: const OutlineInputBorder(),
            helperText: spec.helper,
            helperMaxLines: 2,
            // Ошибка показывается так же, как у обычного поля.
            errorText: field.errorText,
          ),
          child: options.isEmpty
              ? const Text('Нет доступных значений')
              : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final o in options)
                      FilterChip(
                        key: ValueKey('chip-${spec.key}-${o.$1}'),
                        label: Text(o.$2),
                        selected: field.value!.contains(o.$1),
                        onSelected: (_) {
                          final next = [...field.value!];
                          next.contains(o.$1)
                              ? next.remove(o.$1)
                              : next.add(o.$1);
                          // Без didChange форма не узнает о новом значении.
                          field.didChange(next);
                          _notifier.clearFieldError(spec.key);
                          _set(spec.key, next);
                        },
                      ),
                  ],
                ),
        );
      },
    );
  }
}

class _TextInput extends StatefulWidget {
  final TextSpec spec;
  final _EntityFormViewState state;

  const _TextInput({required this.spec, required this.state});

  @override
  State<_TextInput> createState() => _TextInputState();
}

class _TextInputState extends State<_TextInput> {
  // Начальное значение задаётся при создании контроллера, а не через
  // initialValue: одновременно использовать оба нельзя.
  late final TextEditingController _controller = TextEditingController(
    text: widget.state._values[widget.spec.key] as String? ?? '',
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final spec = widget.spec;
    final form = widget.state;
    return TextFormField(
      key: ValueKey('field-${spec.key}'),
      autovalidateMode: AutovalidateMode.onUserInteraction,
      controller: _controller,
      keyboardType: spec.keyboard,
      inputFormatters: spec.formatters,
      maxLines: spec.maxLines,
      decoration: InputDecoration(
        labelText: spec.required ? '${spec.label} *' : spec.label,
        hintText: spec.hint,
        border: const OutlineInputBorder(),
        alignLabelWithHint: spec.maxLines > 1,
      ),
      validator: (value) {
        final text = value ?? '';
        final local = spec.validator?.call(text, form._values);
        return local ?? form._serverError(spec.key, text);
      },
      onChanged: (value) {
        form._notifier.clearFieldError(spec.key);
        form._set(spec.key, value);
      },
    );
  }
}

class _DateInput extends StatefulWidget {
  final DateSpec spec;
  final _EntityFormViewState state;

  const _DateInput({required this.spec, required this.state});

  @override
  State<_DateInput> createState() => _DateInputState();
}

class _DateInputState extends State<_DateInput> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.state._values[widget.spec.key] as String? ?? '',
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    final current = DateTime.tryParse(_controller.text) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      final text =
          '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      _controller.text = text;
      widget.state._set(widget.spec.key, text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final spec = widget.spec;
    final form = widget.state;
    return TextFormField(
      key: ValueKey('field-${spec.key}'),
      autovalidateMode: AutovalidateMode.onUserInteraction,
      controller: _controller,
      keyboardType: TextInputType.datetime,
      decoration: InputDecoration(
        labelText: spec.required ? '${spec.label} *' : spec.label,
        hintText: 'ГГГГ-ММ-ДД',
        border: const OutlineInputBorder(),
        suffixIcon: IconButton(
          tooltip: 'Выбрать дату',
          icon: const Icon(Icons.calendar_today_outlined),
          onPressed: _pick,
        ),
      ),
      validator: (value) {
        final text = value ?? '';
        final local = spec.validator?.call(text, form._values);
        return local ?? form._serverError(spec.key, text);
      },
      onChanged: (value) {
        form._notifier.clearFieldError(spec.key);
        form._set(spec.key, value);
      },
    );
  }
}
