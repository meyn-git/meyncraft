import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:meyncraft/meyncraft/command.domain.dart';
import 'package:meyncraft/meyncraft/command.presentation.dart';
import 'package:meyncraft/meyncraft/tab/markdown_tab.presentation.dart';
import 'package:meyncraft/template/generate/generator.service.dart';
import 'package:meyncraft/template/generate/generator_result_tab.presentation.dart';
import 'package:meyncraft/template/selected_templates.service.dart';
import 'package:meyncraft/meyncraft/tab/tab.service.dart';
import 'package:meyncraft/template/template.domain.dart';
import 'package:meyncraft/template/template.service.dart';
import 'package:meyncraft/template/template_tile.presentation.dart';

class SelectedTemplatesPanel extends StatelessWidget {
  SelectedTemplatesPanel({super.key});

  final selectedTemplateService = GetIt.I<SelectedTemplateService>();
  final ScrollController _scrollController = ScrollController();
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: selectedTemplateService,
    builder: (BuildContext context, _) => Column(
      children: [
        TopToolBar(),

        Expanded(
          // Adding a scrollbar with a visible thumb so that there is a visual
          // indication that the list can be scrolled when there are many templates
          child: Scrollbar(
            thumbVisibility: true,
            controller: _scrollController,
            child: ListView.builder(
              controller: _scrollController,
              itemCount: allTemplates.length,
              itemBuilder: (context, index) =>
                  TemplateTile(allTemplates[index]),
            ),
          ),
        ),

        // Bottom button
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedCommandButton(Generate()),
        ),
      ],
    ),
  );
}

class TopToolBar extends StatelessWidget {
  const TopToolBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      width: double.infinity,
      alignment: Alignment.centerLeft,
      color: Theme.of(context).colorScheme.surfaceDim,
      padding: const EdgeInsets.only(left: 8),
      child: Row(
        children: [
          Text(
            'Selected templates',
            //style: TextStyle(color: Theme.of(context).colorScheme.b),
          ),
          Spacer(),
          Tooltip(
            message: OpenMeynAboutCraftTab().descriptionWithHotkey,
            child: IconButton(
              icon: Icon(Icons.info_outline_rounded),
              iconSize: 30.0,
              onPressed: OpenMeynAboutCraftTab().action,
            ),
          ),
        ],
      ),
    );
  }
}

// TODO replace the class above with this one when there are to many templates in the future
// class SelectedTemplatesPanel extends StatelessWidget {
//   SelectedTemplatesPanel({super.key});

//   final SelectedTemplateService selectedTemplateService =
//       GetIt.I<SelectedTemplateService>();

//   final _tabService = GetIt.I.get<TabService>();

//   @override
//   Widget build(BuildContext context) => Column(
//     crossAxisAlignment: CrossAxisAlignment.start,
//     children: [
//       Container(
//         height: 40,
//         width: double.infinity,
//         alignment: Alignment.centerLeft,
//         color: Theme.of(context).colorScheme.surfaceDim,
//         padding: const EdgeInsets.only(left: 8),
//         child: Text(
//           'Selected templates',
//           //style: TextStyle(color: Theme.of(context).colorScheme.b),
//         ),
//       ),

//       ListenableBuilder(
//         listenable: selectedTemplateService,
//         builder: (BuildContext context, _) => Expanded(
//           child: selectedTemplateService.selectedTemplates.isEmpty
//               ? Center(
//                   child: Text(
//                     textAlign: TextAlign.center,
//                     'Select templates to generate\nfrom "All Templates"',
//                     // style: TextStyle(
//                     //   color: Theme.of(context).colorScheme.onSurfaceVariant,
//                     // ),
//                   ),
//                 )
//               : Column(
//                   children: [
//                     Expanded(
//                       child: ListView(
//                         children: selectedTemplateService.selectedTemplates
//                             .map((t) => TemplateTile(t))
//                             .toList(),
//                       ),
//                     ),
//                     // Bottom button
//                     Padding(
//                       padding: const EdgeInsets.all(16.0),
//                       child: SizedBox(
//                         width: 200,
//                         child: ElevatedButton(
//                           onPressed: getParameterValues,
//                           child: const Text('Generate'),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//         ),
//       ),
//     ],
//   );

//   Future<void> getParameterValues() async {
//     var selectedTemplates = selectedTemplateService.selectedTemplates;
//     if (selectedTemplates.isEmpty) {
//       return;
//     }
//     var parameters = selectedTemplates.expand((t) => t.parameters).toSet();
//     if (parameters.isEmpty) {
//       return;
//     }
//     if (parameters.length == 1 &&
//         parameters.first.name == sysmacProjectFileParameter.name) {
//       await selectSysmacFileAndGenerate(selectedTemplates);
//     } else {
//       _tabService.addTab(
//         GeneratorParametersTab(templatesToGenerate: selectedTemplates),
//       );
//     }
//   }
// }

Future<void> selectSysmacFileAndGenerate(
  List<Template> selectedTemplates,
) async {
  var sysmacProjectFilePath = await _openFilePicker();
  if (sysmacProjectFilePath == null) {
    return;
  }
  var parameterValues = {
    sysmacProjectFileParameter.name: sysmacProjectFilePath,
  };
  var tabService = GetIt.I.get<TabService>();
  var generatorResultTab = GeneratorResultTab(
    selectedTemplates,
    parameterValues,
  );
  tabService.addTab(generatorResultTab);

  await generate(
    selectedTemplates,
    parameterValues,
    generatorResultTab.content as DynamicMarkdownTabContent,
  );
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
