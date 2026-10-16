import 'package:flutter/widgets.dart';

enum ScreenSize { compact, medium, expanded }

/// Класс ширины окна браузера: до 600 — узкое (список карточек и нижняя
/// навигация), до 1200 — среднее, дальше — широкое.
ScreenSize screenSizeOf(BuildContext context) {
  final width = MediaQuery.sizeOf(context).width;
  if (width < 600) return ScreenSize.compact;
  if (width < 1200) return ScreenSize.medium;
  return ScreenSize.expanded;
}

/// Возвращает значение, соответствующее текущей ширине окна.
T byScreen<T>(
  BuildContext context, {
  required T compact,
  T? medium,
  T? expanded,
}) {
  return switch (screenSizeOf(context)) {
    ScreenSize.compact => compact,
    ScreenSize.medium => medium ?? compact,
    ScreenSize.expanded => expanded ?? medium ?? compact,
  };
}
