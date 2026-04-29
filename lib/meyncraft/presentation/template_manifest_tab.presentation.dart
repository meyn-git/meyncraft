import 'package:flutter/material.dart';
import 'package:meyncraft/meyncraft/presentation/tab.presentation.dart';
import 'package:meyncraft/meyncraft/template_manifest/template_manifest.domain.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

class TemplateManifestTab extends ClosableTab {
  final TemplateManifest templateManifest;
  TemplateManifestTab(this.templateManifest)
    : super(tabName: templateManifest.name, closable: true);

  @override
  Widget buildContent(BuildContext context) => Markdown(
    styleSheet: MarkdownStyleSheet(h2Padding: EdgeInsets.fromLTRB(0, 10, 0, 0)),
    data: createMarkdown(),
    onTapLink: (text, href, title) {
      if (href != null) {
        launchUrl(Uri.parse(href));
      }
    },
  );

  String createMarkdown() {
    final buffer = StringBuffer();

    buffer.writeln('# ${templateManifest.name} Manifest');
    buffer.writeln();

    buffer.writeln('## Description');
    buffer.writeln();
    buffer.writeln(templateManifest.description);
    buffer.writeln();

    if (templateManifest.generatedFileInstructions != null) {
      buffer.writeln('## Generated File Instructions');
      buffer.writeln();
      buffer.writeln(templateManifest.generatedFileInstructions!);
      buffer.writeln();
    }

    if (templateManifest.gitRepository != null) {
      buffer.writeln('## Git Repository');
      buffer.writeln();
      buffer.writeln(
        '[${templateManifest.gitRepository}](${templateManifest.gitRepository})',
      );
      buffer.writeln();
    }

    if (templateManifest.documentation != null) {
      buffer.writeln('## Documentation');
      buffer.writeln();
      buffer.writeln(
        '[${templateManifest.documentation}](${templateManifest.documentation})',
      );
      buffer.writeln();
    }

    if (templateManifest.tags.isNotEmpty) {
      buffer.writeln('## Tags');
      buffer.writeln();
      for (final tag in templateManifest.tags) {
        buffer.writeln('* $tag');
      }
    }

    if (templateManifest.parameters.isNotEmpty) {
      buffer.writeln('## Parameters');
      buffer.writeln();
      for (final parameter in templateManifest.parameters) {
        buffer.writeln('* name: ${parameter.name}\\');
        buffer.writeln('  description: ${parameter.description}\\');
        buffer.writeln(
          '  type: ${parameter.type.toString().split('.').last}\\',
        );
        buffer.writeln('  required: ${parameter.required ? 'true' : 'false'}');
      }
    }

    if (templateManifest.templates.isNotEmpty) {
      buffer.writeln('## Templates');
      buffer.writeln();
      for (final template in templateManifest.templates) {
        var texts = [
          ' source: ${template.source}',
          ' target: ${template.target}',
          if (template.when != null) ' when: ${template.when}',
        ];
        buffer.writeln("* ${texts.join('\\\n  ')}");
      }
    }

    return buffer.toString();
  }
}
