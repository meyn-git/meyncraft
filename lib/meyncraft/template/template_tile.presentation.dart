import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:meyncraft/meyncraft/presentation/selected_templates.service.dart';
import 'package:meyncraft/meyncraft/presentation/tab.service.dart';
import 'package:meyncraft/meyncraft/template/template.domain.dart';
import 'package:meyncraft/meyncraft/template/template_detail_tab.presentation.dart';

class TemplateTile extends StatefulWidget {
  const TemplateTile(this.templateManifest, {super.key});

  final TemplateManifest templateManifest;

  @override
  State<TemplateTile> createState() => _TemplateTileState();
}

class _TemplateTileState extends State<TemplateTile> {
  final _tabService = GetIt.I.get<TabService>();

  List<TemplateManifest> get selectedTemplates =>
      GetIt.I<SelectedTemplateService>().selectedTemplates;

  TemplateManifest get templateManifest => widget.templateManifest;

  bool get isSelected => selectedTemplates.contains(templateManifest);

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
          title: Text(templateManifest.name),
          subtitle: Text(templateManifest.description),
          onTap: addOrSelectInfoTab,
        ),
      ),
    ],
  );

  void toggleTemplateSelection() {
    if (isSelected) {
      GetIt.I<SelectedTemplateService>().remove(templateManifest);
    } else {
      GetIt.I<SelectedTemplateService>().add(templateManifest);
    }
  }

  void addOrSelectInfoTab() {
    _tabService.addOrSelectTab(TemplateDetailTab(templateManifest));
  }
}
