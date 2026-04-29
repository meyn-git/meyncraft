import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:meyncraft/meyncraft/presentation/all_templates.service.dart';
import 'package:meyncraft/meyncraft/presentation/selected_templates.service.dart';
import 'package:meyncraft/meyncraft/presentation/tab.presentation.dart';
import 'package:meyncraft/meyncraft/presentation/tab.service.dart';
import 'package:meyncraft/meyncraft/presentation/template_manifest_tab.presentation.dart';
import 'package:meyncraft/meyncraft/template_manifest/template_manifest.domain.dart';

class AllTemplatesTab extends ClosableTab {
  AllTemplatesTab() : super(tabName: 'All Templates', closable: false);

  final selectedTemplateService = GetIt.I<SelectedTemplateService>();

  @override
  Widget buildContent(BuildContext context) => ListenableBuilder(
    listenable: selectedTemplateService,
    builder: (context, _) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
        child: ListView(
          children: getAllTemplateManifests()
              .map((manifest) => TemplateManifestTile(manifest))
              .toList(),
        ),
      );
    },
  );
}

class TemplateManifestTile extends StatefulWidget {
  const TemplateManifestTile(this.templateManifest, {super.key});

  final TemplateManifest templateManifest;

  @override
  State<TemplateManifestTile> createState() => _TemplateManifestTileState();
}

class _TemplateManifestTileState extends State<TemplateManifestTile> {
  final _tabService = GetIt.I.get<TabService>();

  List<TemplateManifest> get selectedTemplates =>
      GetIt.I<SelectedTemplateService>().selectedTemplates;

  TemplateManifest get templateManifest => widget.templateManifest;

  bool get isSelected => selectedTemplates.contains(templateManifest);

  @override
  Widget build(BuildContext context) => Row(
    children: [
      IconButton(
        onPressed: () {
          setState(() {
            if (isSelected) {
              GetIt.I<SelectedTemplateService>().remove(templateManifest);
            } else {
              GetIt.I<SelectedTemplateService>().add(templateManifest);
            }
          });
        },
        icon: isSelected
            ? const Icon(Icons.check_box)
            : const Icon(Icons.check_box_outline_blank),
      ),
      Expanded(
        child: ListTile(
          title: Text(templateManifest.name),
          subtitle: Text(templateManifest.description),
          onTap: () {
            _tabService.addTab(TemplateManifestTab(templateManifest));
          },
        ),
      ),
    ],
  );

  void _showContextMenu(
    BuildContext context,
    TemplateManifest manifest,
    Offset position,
  ) {
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;

    showMenu<String>(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromLTWH(position.dx, position.dy, 0, 0),
        Offset.zero & overlay.size,
      ),
      items: [
        const PopupMenuItem(
          child: Row(
            children: [
              Icon(Icons.check_box, size: 20),
              SizedBox(width: 8),
              Text('Select template'),
            ],
          ),
        ),

        const PopupMenuItem(
          child: Row(
            children: [
              Icon(Icons.check_box_outline_blank, size: 20),
              SizedBox(width: 8),
              Text('De-select template'),
            ],
          ),
        ),

        PopupMenuItem(
          child: Row(
            children: const [
              Icon(Icons.info, size: 20),
              SizedBox(width: 8),
              Text('Show details'),
            ],
          ),

          onTap: () {
            _tabService.addTab(TemplateManifestTab(manifest));
          },
        ),
      ],
    );
  }
}
