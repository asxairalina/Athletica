import 'package:flutter/material.dart';

class NavigationService {
  static final ValueNotifier<int> currentIndexNotifier = ValueNotifier<int>(0);
  static final List<VoidCallback> _listeners = [];

  static void addListener(VoidCallback listener) {
    _listeners.add(listener);
  }

  static void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
  }

  static void switchToTab(int index) {
    currentIndexNotifier.value = index;
    // Уведомляем всех слушателей
    for (final listener in _listeners) {
      listener();
    }
  }
}
