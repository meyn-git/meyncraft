import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:meyncraft/meyncraft/presentation/all_templates.service.dart';
import 'package:meyncraft/meyncraft/presentation/tab.presentation.dart';
import 'package:meyncraft/meyncraft/presentation/tab.service.dart';
import 'package:meyncraft/meyncraft/presentation/template_manifest_tab.presentation.dart';
import 'package:meyncraft/meyncraft/template_manifest/template_manifest.domain.dart';

class AllTemplatesTab extends ClosableTab {
  AllTemplatesTab() : super(tabName: 'All Templates', closable: false);

  @override
  Widget buildContent(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 0),
      child: ListView(
        children: getAllTemplateManifests()
            .map((manifest) => TemplateManifestTile(manifest))
            .toList(),
      ),
    );
  }
}

class TemplateManifestTile extends StatefulWidget {
  const TemplateManifestTile(this.manifest, {super.key});

  final TemplateManifest manifest;

  @override
  State<TemplateManifestTile> createState() => _TemplateManifestTileState();
}

class _TemplateManifestTileState extends State<TemplateManifestTile> {
  Offset? _tapPosition;

  final _tabService = GetIt.I.get<TabService>();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (details) {
        _tapPosition = details.globalPosition;
      },
      child: ListTile(
        leading: const Icon(Icons.check_box),
        title: Text(widget.manifest.name),
        subtitle: Text(widget.manifest.description),

        onTap: () {
          if (_tapPosition != null) {
            _showContextMenu(context, widget.manifest, _tapPosition!);
          }
        },
      ),
    );
  }

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
