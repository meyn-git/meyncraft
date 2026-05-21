import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:meyncraft/template/selected_templates.service.dart';
import 'package:meyncraft/meyncraft/tab/tab.service.dart';
import 'package:meyncraft/template/template.domain.dart';
import 'package:meyncraft/template/template_about_tab.presentation.dart';

class TemplateTile extends StatefulWidget {
  const TemplateTile(this.template,  this.focusNode, {super.key});

  final TemplateProject template;
  final FocusNode? focusNode;

  @override
  State<TemplateTile> createState() => _TemplateTileState();
}

class _TemplateTileState extends State<TemplateTile> {
  final _tabService = GetIt.I.get<TabService>();

  List<TemplateProject> get selectedTemplates =>
      GetIt.I<SelectedTemplateService>().selectedTemplates;

  TemplateProject get template => widget.template;

  bool get isSelected => selectedTemplates.contains(template);

@override
  void initState() {  
    super.initState();
    if (widget.focusNode != null) {
      // Request focus after the first frame to ensure the widget is built
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.focusNode!.requestFocus();
      });
    }
  }

  @override
  Widget build(BuildContext context) => Row(
    children: [
      IconButton(
        focusNode: widget.focusNode,
        onPressed: toggleTemplateSelection,
        icon: isSelected
            ? const Icon(Icons.check_box)
            : const Icon(Icons.check_box_outline_blank),
      ),
      Expanded(
        child: ListTile(
          title: Text(template.name),
          subtitle: Text(template.description),
          onTap: showAboutTemplateTab,
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

  void showAboutTemplateTab() {
    _tabService.addOrSelectTab(TemplateAboutTab(template));
  }
}
