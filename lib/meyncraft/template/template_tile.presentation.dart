import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:meyncraft/meyncraft/template/selected_templates.service.dart';
import 'package:meyncraft/meyncraft/presentation/tab.service.dart';
import 'package:meyncraft/meyncraft/template/template.domain.dart';
import 'package:meyncraft/meyncraft/template/template_detail_tab.presentation.dart';

class TemplateTile extends StatefulWidget {
  const TemplateTile(this.template, {super.key});

  final Template template;

  @override
  State<TemplateTile> createState() => _TemplateTileState();
}

class _TemplateTileState extends State<TemplateTile> {
  final _tabService = GetIt.I.get<TabService>();

  List<Template> get selectedTemplates =>
      GetIt.I<SelectedTemplateService>().selectedTemplates;

  Template get template => widget.template;

  bool get isSelected => selectedTemplates.contains(template);

  @override
  Widget build(BuildContext context) => Row(
    children: [
      IconButton(
        onPressed: toggleTemplateSelection,
        icon: isSelected
            ? const Icon(Icons.check_box)
            : const Icon(Icons.check_box_outline_blank),
      ),
      Expanded(
        child: ListTile(
          title: Text(template.name),
          subtitle: Text(template.description),
          onTap: addOrSelectInfoTab,
        ),
      ),
    ],
  );

  void toggleTemplateSelection() {
    if (isSelected) {
      GetIt.I<SelectedTemplateService>().remove(template);
    } else {
      GetIt.I<SelectedTemplateService>().add(template);
    }
  }

  void addOrSelectInfoTab() {
    _tabService.addOrSelectTab(TemplateDetailTab(template: template));
  }
}
