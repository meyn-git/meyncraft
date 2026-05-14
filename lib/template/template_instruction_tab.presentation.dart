import 'dart:io';

import 'package:meyncraft/meyncraft/tab/markdown_tab.presentation.dart';
import 'package:meyncraft/template/generate/generator.domain.dart';
import 'package:meyncraft/template/template.domain.dart';
import 'package:meyncraft/template/template_about_tab.presentation.dart';

class TemplateInstructionTab extends MarkdownTab {
  TemplateInstructionTab(
    Template template,
    Generator generator,
    List<File> generatedFiles, {
    super.key,
  }) : super(createMarkdownContent(template, generator, generatedFiles));
  //, closable: true

  static DynamicMarkdownTabContent createMarkdownContent(
    Template template,
    Generator generator,
    List<File> generatedFiles,
  ) {
    var output = DynamicMarkdownTabContent('Instructions');
    var urlLink = output.addLink(TemplateAboutTab(template));
    output.addToMarkdown(
      '## Source\n'
      '* Template: [${template.name}]($urlLink)\n'
      '* Generator source: ${generator.source}\n'
      '## Generated ${generatedFiles.length == 1 ? 'File' : 'Files'}\n'
      '${generatedFiles.map((file) => '* [${file.path}](${file.uri})').join('\n')}'
      '\n## Instructions\n'
      '${generator.outputInstructions}',
    );

    return output;
  }
}
