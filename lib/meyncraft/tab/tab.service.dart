import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:meyncraft/meyncraft/tab/markdown_tab.presentation.dart';
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
      (otherTab) => isMarkdownTabWithSameTitleAndContent(tab, otherTab),
    );

    if (existingTab == null) {
      addTab(tab);
    } else {
      selectTab(_tabs.indexOf(existingTab));
    }
  }

  void selectPreviousTab() {
    if (_tabs.length < 2) return;
    var index = _selectedIndex - 1;
    if (index < 0) {
      index = tabs.length - 1;
    }
    selectTab(index);
  }

  void selectNextTab() {
    if (_tabs.length < 2) return;
    var index = _selectedIndex + 1;
    if (index >= tabs.length) {
      index = 0;
    }
    selectTab(index);
  }

  void closeCurrentTab() {
    if (tabs.isEmpty) return;
    closeTabIndex(_selectedIndex);
  }

  void closeAllTabs() {
    for (var index = tabs.length; index >= 0; index--) {
      closeTabIndex(index);
    }
  }

  ClosableTab? currentTab() {
    if (_tabs.isEmpty) return null;
    return _tabs[_selectedIndex];
  }

  bool isMarkdownTabWithSameTitleAndContent(
    ClosableTab tab,
    ClosableTab otherTab,
  ) {
    if (tab is! MarkdownTab || otherTab is! MarkdownTab) {
      return false;
    }
    if (tab.tabTitle != otherTab.tabTitle) {
      return false;
    }
    return tab.content.markdown == otherTab.content.markdown;
  }
}
