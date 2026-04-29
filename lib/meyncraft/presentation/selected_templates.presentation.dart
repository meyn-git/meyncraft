import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:meyncraft/meyncraft/presentation/all_templates.presentation.dart';
import 'package:meyncraft/meyncraft/presentation/selected_templates.service.dart';

class SelectedTemplatesPanel extends StatelessWidget {
  const SelectedTemplatesPanel({super.key});

  SelectedTemplateService get selectedTemplateService =>
      GetIt.I<SelectedTemplateService>();

  @override
  Widget build(BuildContext context) {
    var selectedTemplates = selectedTemplateService.selectedTemplates;
    return Column(
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

        Expanded(
          child: selectedTemplates.isEmpty
              ? Center(
                  child: Text(
                    textAlign: TextAlign.center,
                    'Select templates to generate\nfrom "All Templates"',
                    // style: TextStyle(
                    //   color: Theme.of(context).colorScheme.onSurfaceVariant,
                    // ),
                  ),
                )
              : ListView(
                  children: selectedTemplates
                      .map((t) => TemplateManifestTile(t))
                      .toList(),
                ),
        ),
      ],
    );
  }
}
