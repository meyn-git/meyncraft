import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:meyncraft/meyncraft/generate/generator.service.dart';
import 'package:meyncraft/meyncraft/generate/generator_parameter_tab.presentation.dart';
import 'package:meyncraft/meyncraft/generate/generator_result_tab.presentation.dart';
import 'package:meyncraft/meyncraft/presentation/selected_templates.service.dart';
import 'package:meyncraft/meyncraft/presentation/tab.service.dart';
import 'package:meyncraft/meyncraft/template/template.domain.dart';
import 'package:meyncraft/meyncraft/template/template.service.dart';
import 'package:meyncraft/meyncraft/template/template_tile.presentation.dart';

class SelectedTemplatesPanel extends StatelessWidget {
  SelectedTemplatesPanel({super.key});

  final SelectedTemplateService selectedTemplateService =
      GetIt.I<SelectedTemplateService>();

  final _tabService = GetIt.I.get<TabService>();

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        height: 40,
        width: double.infinity,
        alignment: Alignment.centerLeft,
        color: Theme.of(context).colorScheme.surfaceDim,
        padding: const EdgeInsets.only(left: 8),
        child: Text(
          'Selected templates',
          //style: TextStyle(color: Theme.of(context).colorScheme.b),
        ),
      ),

      ListenableBuilder(
        listenable: selectedTemplateService,
        builder: (BuildContext context, _) => Expanded(
          child: selectedTemplateService.selectedTemplates.isEmpty
              ? Center(
                  child: Text(
                    textAlign: TextAlign.center,
                    'Select templates to generate\nfrom "All Templates"',
                    // style: TextStyle(
                    //   color: Theme.of(context).colorScheme.onSurfaceVariant,
                    // ),
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      child: ListView(
                        children: selectedTemplateService.selectedTemplates
                            .map((t) => TemplateTile(t))
                            .toList(),
                      ),
                    ),
                    // Bottom button
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: SizedBox(
                        width: 200,
                        child: ElevatedButton(
                          onPressed: getParameterValues,
                          child: const Text('Generate'),
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    ],
  );

  Future<void> getParameterValues() async {
    var selectedTemplates = selectedTemplateService.selectedTemplates;
    if (selectedTemplates.isEmpty) {
      return;
    }
    var parameters = selectedTemplates.expand((t) => t.parameters).toSet();
    if (parameters.isEmpty) {
      return;
    }
    if (parameters.length == 1 &&
        parameters.first.name == sysmacProjectFileParameter.name) {
      await selectSysmacFileAndGenerate(selectedTemplates);
    } else {
      _tabService.addTab(
        GeneratorParametersTab(templatesToGenerate: selectedTemplates),
      );
    }
  }
}

Future<void> selectSysmacFileAndGenerate(
  List<Template> selectedTemplates,
) async {
  var sysmacProjectFilePath = await _openFilePicker();
  if (sysmacProjectFilePath == null) {
    return;
  }
  var parameters = {sysmacProjectFileParameter.name: sysmacProjectFilePath};
  var outputReport = MarkdownReport();
  var tabService = GetIt.I.get<TabService>();
  tabService.addTab(GeneratorResultTab(outputReport));
  await generate(selectedTemplates, parameters, outputReport);
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
    return null;
  }

  final file = result.files.single;
  return file.path!;
}
