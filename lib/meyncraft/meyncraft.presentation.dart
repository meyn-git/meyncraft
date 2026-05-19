import 'package:flutter/material.dart';
import 'package:meyncraft/meyncraft/command.domain.dart';
import 'package:meyncraft/template/selected_templates.presentation.dart';
import 'package:meyncraft/meyncraft/tab/tab.presentation.dart';
import 'package:meyncraft/meyncraft/style/theme.presentation.dart';

class MeynCraft extends StatefulWidget {
  final List<String> args;
  const MeynCraft(this.args, {super.key});

  @override
  State<MeynCraft> createState() => _MeynCraftState();
}

class _MeynCraftState extends State<MeynCraft> {
  final commands = const <Command>[
    SelectNextTab(),
    SelectPreviousTab(),
    CloseCurrentTab(),
    CloseAllTabs(),
    Generate(),
    ReGenerate(),
    OpenMeynAboutCraftTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: {
        for (Command command in commands.where((a) => a.hotKey != null))
          command.hotKey!: command,
      },
      child: Actions(
        actions: {
          for (Command command in commands.where((a) => a.hotKey != null))
            command.runtimeType: CallbackAction<Command>(
              onInvoke: (intent) => command.action(),
            ),
        },
        child: MaterialApp(
          title: 'MeynCraft',
          debugShowCheckedModeBanner: false,
          themeMode: ThemeMode.dark, // for now, we only support dark theme
          theme: meynTheme(Brightness.light),
          darkTheme: meynTheme(Brightness.dark),
          //home: LogView(),
          home: DraggableSplitView(
            left: SelectedTemplatesPanel(),
            right: ClosableTabsView(),
          ),
        ),
      ),
    );
  }
}

class DraggableSplitView extends StatefulWidget {
  final Widget left;
  final Widget right;

  const DraggableSplitView({
    super.key,
    required this.left,
    required this.right,
  });

  @override
  State<DraggableSplitView> createState() => _DraggableSplitViewState();
}

class _DraggableSplitViewState extends State<DraggableSplitView> {
  // Initial left panel width fraction (30%)
  double _leftFraction = 0.30;

  // Limits: 30% ± 20%
  static const double _minFraction = 0.10;
  static const double _maxFraction = 0.50;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final totalWidth = constraints.maxWidth;
          final leftWidth = totalWidth * _leftFraction;

          return Row(
            children: [
              SizedBox(width: leftWidth, child: widget.left),

              // Divider
              MouseRegion(
                cursor: SystemMouseCursors.resizeColumn,
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onHorizontalDragUpdate: (details) {
                    setState(() {
                      _leftFraction += details.delta.dx / totalWidth;
                      _leftFraction = _leftFraction.clamp(
                        _minFraction,
                        _maxFraction,
                      );
                    });
                  },
                  child: Container(
                    width: 6,
                    color: Theme.of(context).colorScheme.surfaceDim,
                    child: Center(
                      child: VerticalDivider(
                        width: 1,
                        thickness: 1,
                        color: Theme.of(context).colorScheme.surfaceDim,
                      ),
                    ),
                  ),
                ),
              ),

              // Right panel
              Expanded(child: widget.right),
            ],
          );
        },
      ),
    );
  }
}
