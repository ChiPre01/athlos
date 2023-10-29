import 'package:flutter/material.dart';
class UnreadMessageProvider with ChangeNotifier {
  int _unreadMessageCount = 0;

  int get unreadMessageCount => _unreadMessageCount;

  void incrementUnreadMessageCount() {
    _unreadMessageCount++;
    notifyListeners();
  }
}
