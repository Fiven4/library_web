import 'dart:async';
import 'dart:ui';

/// Откладывает действие до паузы в потоке событий: каждый новый вызов
/// сбрасывает таймер. Нужен, чтобы поиск не запускал выборку на каждую
/// нажатую клавишу.
class Debouncer {
  Debouncer({this.delay = const Duration(milliseconds: 400)});

  final Duration delay;
  Timer? _timer;

  bool get isPending => _timer?.isActive ?? false;

  void run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }

  void cancel() => _timer?.cancel();
}
