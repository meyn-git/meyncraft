import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:meyncraft/meyncraft/tab/tab.presentation.dart';

/// Service to manage the state of open tabs in the application.
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

  void closeTab(ClosableTab tab) {
    final index = _tabs.indexOf(tab);
    if (index != -1) {
      closeTabIndex(index);
    }
  }

  void closeTabIndex(int index) {
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

  void addOrSelectTab(ClosableTab tab) {
    final existingTab = _tabs.firstWhereOrNull(
      (otherTab) =>
          tab.runtimeType == otherTab.runtimeType &&
          tab.tabTitle == otherTab.tabTitle,
    );

    if (existingTab == null) {
      addTab(tab);
    } else {
      selectTab(_tabs.indexOf(existingTab));
    }
  }
}
