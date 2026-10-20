import 'package:flutter/foundation.dart';

class DevSettings extends ChangeNotifier {
  bool _failing = false;
  bool _slow = false;

  bool get failing => _failing;
  bool get slow => _slow;

  set failing(bool value) {
    _failing = value;
    notifyListeners();
  }

  set slow(bool value) {
    _slow = value;
    notifyListeners();
  }

  Duration get delay =>
      _slow ? const Duration(seconds: 4) : const Duration(milliseconds: 250);
}
