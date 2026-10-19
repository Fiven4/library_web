/// Сообщения о событиях хранилища, которые нужно показать пользователю:
/// перенос данных в новый формат или сброс испорченных данных.
///
/// Репозитории создаются во время построения дерева виджетов, поэтому класс
/// только накапливает сообщения: оповещать подписчиков в этот момент нельзя.
/// Каркас приложения забирает их после первого кадра.
class StorageNotices {
  final List<String> _messages = [];

  List<String> get messages => List.unmodifiable(_messages);

  void add(String message) => _messages.add(message);

  /// Забирает накопленные сообщения (показанные больше не повторяются).
  List<String> take() {
    final copy = List<String>.of(_messages);
    _messages.clear();
    return copy;
  }
}
