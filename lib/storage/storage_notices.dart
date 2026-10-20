class StorageNotices {
  final List<String> _messages = [];

  List<String> get messages => List.unmodifiable(_messages);

  void add(String message) => _messages.add(message);

  List<String> take() {
    final copy = List<String>.of(_messages);
    _messages.clear();
    return copy;
  }
}
