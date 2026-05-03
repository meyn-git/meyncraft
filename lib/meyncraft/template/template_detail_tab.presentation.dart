import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:meyncraft/meyncraft/presentation/tab.presentation.dart';
import 'package:meyncraft/meyncraft/presentation/tab.service.dart';
import 'package:meyncraft/meyncraft/style/markdown_style_sheet.presentation.dart';
import 'package:meyncraft/meyncraft/template/template.domain.dart';
import 'package:meyncraft/meyncraft/template/template.service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

class TemplateDetailTab extends ClosableTab {
  final Template template;
  TemplateDetailTab(this.template)
    : super(tabName: template.name, closable: true);

  @override
  Widget buildContent(BuildContext context) => Markdown(
    styleSheet: MeynMarkdownStyleSheet(context),
    data: createMarkdown(),
    onTapLink: (text, href, title) {
      if (href == null) return;
      var uri = Uri.parse(href);
      if (uri.scheme == 'detail') {
        var templateName = uri.path;
        var template = allTemplates().firstWhere(
          (t) => t.name == templateName,
          orElse: () => throw Exception('Template not found: $templateName'),
        );
        var tabService = GetIt.I.get<TabService>();
        tabService.addOrSelectTab(TemplateDetailTab(template));
      } else {
        launchUrl(uri);
      }
    },
  );

  String createMarkdown() {
    final buffer = StringBuffer();

    buffer.writeln('# ${template.name} Manifest');
    buffer.writeln();

    buffer.writeln('## Description');
    buffer.writeln();
    buffer.writeln(template.description);
    buffer.writeln();

    if (template.generatedFileInstructions != null) {
      buffer.writeln('## Generated File Instructions');
      buffer.writeln();
      buffer.writeln(template.generatedFileInstructions!);
      buffer.writeln();
    }

    if (template.gitRepository != null) {
      buffer.writeln('## Git Repository');
      buffer.writeln();
      buffer.writeln('[${template.gitRepository}](${template.gitRepository})');
      buffer.writeln();
    }

    if (template.documentation != null) {
      buffer.writeln('## Documentation');
      buffer.writeln();
      buffer.writeln('[${template.documentation}](${template.documentation})');
      buffer.writeln();
    }

    if (template.tags.isNotEmpty) {
      buffer.writeln('## Tags');
      buffer.writeln();
      for (final tag in template.tags) {
        buffer.writeln('* $tag');
      }
    }

    if (template.parameters.isNotEmpty) {
      buffer.writeln('## Parameters');
      buffer.writeln();
      for (final parameter in template.parameters) {
        buffer.writeln('* name: ${parameter.name}\\');
        buffer.writeln('  description: ${parameter.description}\\');
        buffer.writeln(
          '  type: ${parameter.type.toString().split('.').last}\\',
        );
        buffer.writeln('  required: ${parameter.required ? 'true' : 'false'}');
      }
    }

    if (template.generators.isNotEmpty) {
      buffer.writeln('## Generators');
      buffer.writeln();
      for (final generator in template.generators) {
        var texts = [
          ' source: ${generator.source}',
          ' target: ${generator.target}',
          //TODO if (template.when != null) ' when: ${template.when}',
        ];
        buffer.writeln("* ${texts.join('\\\n  ')}");
      }
    }

    return buffer.toString();
  }
}
