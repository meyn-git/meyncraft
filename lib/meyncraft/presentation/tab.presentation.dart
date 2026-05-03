import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:meyncraft/meyncraft/presentation/tab.service.dart';

abstract class ClosableTab {
  final String tabName;
  final bool closable;

  const ClosableTab({required this.tabName, this.closable = true});

  /// Content displayed when the tab is active
  Widget buildContent(BuildContext context);
}

class ClosableTabsView extends StatefulWidget {
  const ClosableTabsView({super.key});

  @override
  State<ClosableTabsView> createState() => _ClosableTabsViewState();
}

class _ClosableTabsViewState extends State<ClosableTabsView> {
  final TabService _tabService = GetIt.I.get<TabService>();

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _tabService,
    builder: (context, _) {
      if (_tabService.tabs.isEmpty) {
        return const Center(child: Text('No tabs open'));
      }

      return Column(
        children: [
          // Tabs header
          Container(
            height: 40,
            color: Theme.of(context).colorScheme.surfaceDim,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _tabService.tabs.length,
              itemBuilder: (context, index) {
                final tab = _tabService.tabs[index];
                final selected = index == _tabService.selectedIndex;

                return InkWell(
                  onTap: () => setState(() => _tabService.selectTab(index)),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          width: 2,
                          color: selected
                              ? Theme.of(context).colorScheme.primary
                              : Colors.transparent,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(tab.tabName),
                        if (tab.closable) ...[
                          const SizedBox(width: 6),
                          GestureDetector(
                            onTap: () => _tabService.closeTabIndex(index),
                            child: const Icon(Icons.close, size: 16),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Active tab content
          Expanded(
            child: Align(
              alignment: Alignment.topLeft,
              child: _tabService.tabs[_tabService.selectedIndex].buildContent(
                context,
              ),
            ),
          ),
        ],
      );
    },
  );
}
