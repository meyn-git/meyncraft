import 'package:meyncraft/meyncraft/tab/markdown_tab.presentation.dart';
import 'package:meyncraft/template/template.domain.dart';

class TemplateAboutTab extends MarkdownTab {
  TemplateAboutTab(Template template, {super.key})
    : super(TemplateAboutMarkdownContent(template));
  //, closable: true
}

class TemplateAboutMarkdownContent extends StaticMarkdownContent {
  TemplateAboutMarkdownContent(Template template)
    : super(
        markdown: createMarkdown(template),
        tabTitle: 'About ${template.name}',
      );

  static String createMarkdown(Template template) {
    final buffer = StringBuffer();

    buffer.writeln('# About the ${template.name} template');
    buffer.writeln();

    buffer.writeln('## Description');
    buffer.writeln();
    buffer.writeln(template.description);
    buffer.writeln();

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
        buffer.writeln(
          '* **${parameter.name}** '
          '(${parameter.required ? 'required ' : ''}'
          '${parameter.type.toString().split('.').last})\\',
        );
        buffer.writeln('  ${parameter.description}');
      }
    }

    if (template.generators.isNotEmpty) {
      buffer.writeln('## Generators');

      for (final generator in template.generators) {
        buffer.writeln('* Source: ${generator.source}');
        buffer.writeln('* Output path: ${generator.outputPath}');
        if (generator.outputInstructions != null) {
          buffer.writeln(
            '* Output file instructions: ${generator.outputInstructions!.replaceAll('\n', '\n  ')}',
          );
        }
      }
    }

    return buffer.toString();
  }
}
