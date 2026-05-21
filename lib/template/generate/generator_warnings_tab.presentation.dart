import 'package:meyncraft/meyncraft/command.domain.dart';
import 'package:meyncraft/meyncraft/command.presentation.dart';
import 'package:meyncraft/meyncraft/tab/markdown_tab.presentation.dart';
import 'package:meyncraft/template/generate/generator.domain.dart';
import 'package:meyncraft/template/generate/warning.domain.dart';
import 'package:meyncraft/template/template.domain.dart';
import 'package:meyncraft/template/template_about_tab.presentation.dart';

class GeneratorWarningsTab extends MarkdownTab {
  GeneratorWarningsTab(
    TemplateProject template,
    Generator generator,
    List<Warning> warnings, {
    super.key,
  }) : super(createMarkdownContent(template, generator, warnings));

  static MarkdownTabContent createMarkdownContent(
    TemplateProject template,
    Generator generator,
    List<Warning> warnings,
  ) {
    var templateTab = TemplateAboutTab(template);
    var templateTabUri = meynCraftUriToTab(templateTab);
    return StaticMarkdownContent(
      tabTitle: warnings.length == 1 ? 'Warning' : 'Warnings',
      buttons: [ElevatedCommandButton(CloseCurrentTab())],
      markdown: createMarkdown(template, templateTabUri, generator, warnings),
      linkedTabs: [templateTab],
    );
  }

  static String createMarkdown(
    TemplateProject template,
    Uri templateTabUri,
    Generator generator,
    List<Warning> warnings,
  ) {
    return '## Source\n'
        '* Template: [${template.name}]($templateTabUri)\n'
        '* Generator source: ${generator.source}\n'
        '## ${warnings.length == 1 ? 'Warning' : 'Warnings'}\n'
        '${warnings.map((w) => '* ${w.message}').toSet().toList().join('\n')}\n';
  }
}

// Uses a template engine to create the output path eg:
// * outputPath: '{{removeFileExtension(sysmacProjectFilePath)}}-Sysmac-PackMlMonitor.xml'
// * parameters: { sysmacProjectFilePath: 'C:/myProject/sysmacProject.smc2' }
// * result: 'C:/myProject/sysmacProject-Sysmac-PackMlMonitor.xml'
