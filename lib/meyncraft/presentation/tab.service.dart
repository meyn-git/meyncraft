import 'package:flutter/material.dart';
import 'package:meyncraft/meyncraft/presentation/tab.presentation.dart';

class TabService extends ChangeNotifier {
  final List<ClosableTab> _tabs = [];
  int _selectedIndex = 0;

  List<ClosableTab> get tabs => List.unmodifiable(_tabs);
  int get selectedIndex => _selectedIndex;

  void addTab(ClosableTab tab) {
    _tabs.add(tab);
    _selectedIndex = _tabs.length - 1;
    notifyListeners();
  }

  void closeTab(int index) {
    if (index < 0 || index >= _tabs.length) return;
    _tabs.removeAt(index);
    if (_selectedIndex >= _tabs.length) {
      _selectedIndex = _tabs.length - 1;
    }
    notifyListeners();
  }

  void selectTab(int index) {
    if (index < 0 || index >= _tabs.length) return;
    _selectedIndex = index;
    notifyListeners();
  }
}
