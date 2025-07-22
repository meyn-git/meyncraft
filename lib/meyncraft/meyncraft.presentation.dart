import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:meyncraft/meyncraft/generate/generate.service.dart';
import 'package:meyncraft/meyncraft/logger/logger.infrastructure.dart';
import 'package:meyncraft/meyncraft/logger/logger.presentation.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) => _startProcessing());
  }

  Future<void> _startProcessing() async {
    var sysmacProjectFilePath = await _getSysmacProjectFilePath();
    if (sysmacProjectFilePath == null) {
      return;
    }
    generate(sysmacProjectFilePath);
  }

  Future<String?> _getSysmacProjectFilePath() async {
    var sysmacProjectFilePath = widget.args.join(' ');
    if (sysmacProjectFilePath.isEmpty) {
      return await _openFilePicker();
    } else {
      return sysmacProjectFilePath;
    }
  }

  Future<String?> _openFilePicker() async {
    final result = await FilePicker.platform.pickFiles(
      dialogTitle: 'Select a Omron Sysmac Project file to generate from',
      type: FileType.custom,
      allowedExtensions: ['smc2'],
      allowMultiple: false,
    );
    if (result == null || result.files.isEmpty) {
      logger.info('Aborted: No file selected.');
      return null;
    }

    final file = result.files.single;
    logger.info('Selected file: ${file.path}');
    return file.path!;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MeynCraft',
      themeMode: ThemeMode.system,
      theme: meynTheme(Brightness.light),
      darkTheme: meynTheme(Brightness.dark),
      home: LogView(),
    );
  }
}
