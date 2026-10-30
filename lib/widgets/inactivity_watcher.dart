import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class InactivityWatcher extends StatefulWidget {
  final Duration timeout;
  final Duration warningDuration;
  final VoidCallback onTimeout;
  final VoidCallback? onActivity;
  final Widget child;

  const InactivityWatcher({
    super.key,
    required this.timeout,
    this.warningDuration = const Duration(seconds: 30),
    required this.onTimeout,
    this.onActivity,
    required this.child,
  });

  @override
  State<InactivityWatcher> createState() => _InactivityWatcherState();
}

class _InactivityWatcherState extends State<InactivityWatcher> {
  Timer? _warningTimer;
  Timer? _logoutTimer;
  bool _showingWarning = false;

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_onKey);
    _restart();
  }

  bool _onKey(KeyEvent event) {
    _restart();
    return false;
  }

  void _restart() {
    _warningTimer?.cancel();
    _logoutTimer?.cancel();
    if (_showingWarning && mounted) {
      Navigator.of(context, rootNavigator: true).pop();
      _showingWarning = false;
    }

    widget.onActivity?.call();

    final warningTime = widget.timeout - widget.warningDuration;
    if (warningTime > Duration.zero) {
      _warningTimer = Timer(warningTime, _showWarningDialog);
    }

    _logoutTimer = Timer(widget.timeout, () {
      if (_showingWarning && mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        _showingWarning = false;
      }
      widget.onTimeout();
    });
  }

  void _showWarningDialog() {
    if (!mounted || _showingWarning) return;
    _showingWarning = true;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          icon: const Icon(
            Icons.timer_outlined,
            color: Colors.orange,
            size: 40,
          ),
          title: const Text('Предупреждение о неактивности'),
          content: Text(
            'Вы не совершали действий. Сессия будет завершена через '
            '${widget.warningDuration.inSeconds} секунд в целях безопасности.',
          ),
          actions: [
            FilledButton(
              onPressed: () {
                _restart();
              },
              child: const Text('Продлить сессию'),
            ),
          ],
        );
      },
    ).then((_) {
      _showingWarning = false;
    });
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onKey);
    _warningTimer?.cancel();
    _logoutTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _restart(),
      onPointerMove: (_) => _restart(),
      onPointerSignal: (_) => _restart(),
      child: widget.child,
    );
  }
}
