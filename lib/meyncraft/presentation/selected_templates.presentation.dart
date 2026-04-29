import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:meyncraft/meyncraft/presentation/all_templates.presentation.dart';
import 'package:meyncraft/meyncraft/presentation/selected_templates.service.dart';

class SelectedTemplatesPanel extends StatelessWidget {
  SelectedTemplatesPanel({super.key});

  final SelectedTemplateService selectedTemplateService =
      GetIt.I<SelectedTemplateService>();

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
                            .map((t) => TemplateManifestTile(t))
                            .toList(),
                      ),
                    ),
                    // Bottom button
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: SizedBox(
                        width: 300,
                        child: ElevatedButton(
                          onPressed: () {
                            // Button action
                          },
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
}
