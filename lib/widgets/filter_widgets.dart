import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Выпадающий список фильтра с пунктом «Все». Значение приходит из адреса,
/// поэтому при его изменении извне поле пересоздаётся (через key).
class DropdownFilter<V> extends StatelessWidget {
  final String label;
  final V? value;
  final List<(V, String)> options;
  final ValueChanged<V?> onChanged;
  final double width;

  const DropdownFilter({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
    this.width = 200,
  });

  @override
  Widget build(BuildContext context) {
    // Если значение из адреса отсутствует в списке, показываем «Все»:
    // иначе DropdownButton выбросит исключение.
    final known = options.any((o) => o.$1 == value);
    return SizedBox(
      width: width,
      child: DropdownButtonFormField<V?>(
        key: ValueKey('$label-$value'),
        initialValue: known ? value : null,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          isDense: true,
        ),
        items: [
          DropdownMenuItem<V?>(value: null, child: const Text('Все')),
          for (final o in options)
            DropdownMenuItem<V?>(
              value: o.$1,
              child: Text(o.$2, overflow: TextOverflow.ellipsis),
            ),
        ],
        onChanged: onChanged,
      ),
    );
  }
}

/// Поле для целого числа (год). Пустое поле означает «без ограничения».
class NumberFilterField extends StatefulWidget {
  final String label;
  final int? value;
  final ValueChanged<int?> onChanged;
  final double width;

  const NumberFilterField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.width = 110,
  });

  @override
  State<NumberFilterField> createState() => _NumberFilterFieldState();
}

class _NumberFilterFieldState extends State<NumberFilterField> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.value?.toString() ?? '',
  );

  @override
  void didUpdateWidget(NumberFilterField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Значение изменилось не вводом (кнопка «назад», сброс) — обновляем поле.
    if (oldWidget.value != widget.value &&
        int.tryParse(_controller.text) != widget.value) {
      _controller.text = widget.value?.toString() ?? '';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      child: TextField(
        controller: _controller,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(
          labelText: widget.label,
          border: const OutlineInputBorder(),
          isDense: true,
        ),
        onChanged: (text) => widget.onChanged(int.tryParse(text)),
      ),
    );
  }
}
