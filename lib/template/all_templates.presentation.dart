import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:meyncraft/template/selected_templates.service.dart';
import 'package:meyncraft/meyncraft/tab/tab.presentation.dart';
import 'package:meyncraft/template/template.service.dart';
import 'package:meyncraft/template/template_tile.presentation.dart';

class AllTemplatesTab extends ClosableTab {
  const AllTemplatesTab({super.key})
    : super(tabTitle: 'All Templates', closable: false);

  @override
  State<StatefulWidget> createState() => _AllTemplatesTabState();
}

class _AllTemplatesTabState extends State<AllTemplatesTab> {
  final selectedTemplateService = GetIt.I<SelectedTemplateService>();

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: selectedTemplateService,
    builder: (context, _) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
        child: ListView(
          children: allTemplates
              .map((template) => TemplateTile(template))
              .toList(),
        ),
      );
    },
  );
}
