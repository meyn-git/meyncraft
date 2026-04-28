import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:meyncraft/meyncraft/presentation/all_templates.service.dart';
import 'package:meyncraft/meyncraft/presentation/tab.presentation.dart';
import 'package:meyncraft/meyncraft/presentation/tab.service.dart';
import 'package:meyncraft/meyncraft/presentation/template_manifest_tab.presentation.dart';

class AllTemplatesTab extends ClosableTab {
  AllTemplatesTab() : super(tabName: 'All Templates', closable: false);

  final _tabService = GetIt.I.get<TabService>();

  @override
  Widget buildContent(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 0),
      child: ListView(
        children: getAllTemplateManifests()
            .map(
              (manifest) => ListTile(
                title: Text(manifest.name),
                subtitle: Text(manifest.description),
                onTap: () {
                  _tabService.addTab(TemplateManifestTab(manifest));
                },
              ),
            )
            .toList(),
      ),
    );
  }
}
