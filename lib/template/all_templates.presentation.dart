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

  final _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: selectedTemplateService,
    builder: (context, _) =>
        // Adding a scrollbar with a visible thumb so that there is a visual
        // indication that the list can be scrolled when there are many templates
        Scrollbar(
          thumbVisibility: true,
          controller: _scrollController,
          child: ListView.builder(
            padding: const EdgeInsets.all(8.0),
            controller: _scrollController,
            itemCount: allTemplates.length,
            itemBuilder: (context, index) => TemplateTile(allTemplates[index]),
          ),
        ),
  );
}
