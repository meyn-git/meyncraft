import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:meyncraft/meyncraft/generate/generate.service.dart';
import 'package:meyncraft/meyncraft/logger/logger.service.dart';
import 'package:meyncraft/meyncraft/logger/logger.presentation.dart';
import 'package:meyncraft/meyncraft/presentation/all_templates.presentation.dart';
import 'package:meyncraft/meyncraft/presentation/meyncraft_info.presentation.dart';
import 'package:meyncraft/meyncraft/presentation/selected_templates.presentation.dart';
import 'package:meyncraft/meyncraft/presentation/tab.presentation.dart';
import 'package:meyncraft/meyncraft/presentation/tab.service.dart';
import 'package:meyncraft/meyncraft/theme.presentation.dart';

class MeynCraft extends StatefulWidget {
  final List<String> args;
  const MeynCraft(this.args, {super.key});

  @override
  State<MeynCraft> createState() => _MeynCraftState();
}

class _MeynCraftState extends State<MeynCraft> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => selectSysmacFileAndGenerate(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MeynCraft',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: meynTheme(Brightness.light),
      darkTheme: meynTheme(Brightness.dark),
      //home: LogView(),
      home: DraggableSplitView(
        left: const SelectedTemplatesPanel(),
        right: ClosableTabsView(),
      ),
    );
  }
}

Future<void> selectSysmacFileAndGenerate() async {
  logger.clear();
  var sysmacProjectFilePath = await _openFilePicker();
  if (sysmacProjectFilePath == null) {
    logger.completed = true;
    return;
  }
  await generate(sysmacProjectFilePath);
}

Future<String?> _openFilePicker() async {
  final result = await FilePicker.platform.pickFiles(
    lockParentWindow: true,
    dialogTitle:
        'MeynCraft - Select a Omron Sysmac Project file to generate from',
    type: FileType.custom,
    allowedExtensions: ['smc2'],
    allowMultiple: false,
  );
  if (result == null || result.files.isEmpty) {
    logger.info('Aborted: No file selected.');
    return null;
  }

  final file = result.files.single;
  return file.path!;
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
