import 'package:meyncraft/meyncraft/command.domain.dart';
import 'package:meyncraft/meyncraft/command.presentation.dart';
import 'package:meyncraft/meyncraft/tab/markdown_tab.presentation.dart';
import 'package:meyncraft/template/generate/generator.domain.dart';
import 'package:meyncraft/template/template.domain.dart';
import 'package:meyncraft/template/template_about_tab.presentation.dart';

class GeneratorErrorTab extends MarkdownTab {
  GeneratorErrorTab(
    TemplateProject template,
    Generator generator,
    Exception exception,
    StackTrace stackTrace, {
    super.key,
  }) : super(createMarkdownContent(template, generator, exception, stackTrace));

  static MarkdownTabContent createMarkdownContent(
    TemplateProject template,
    Generator generator,
    Exception exception,
    StackTrace stackTrace,
  ) {
    var templateTab = TemplateAboutTab(template);
    var templateTabUri = meynCraftUriToTab(templateTab);
    return StaticMarkdownContent(
      tabTitle: 'Error',
      buttons: [ElevatedCommandButton(CloseCurrentTab())],
      markdown: createMarkdown(
        template,
        templateTabUri,
        generator,
        exception,
        stackTrace,
      ),
      linkedTabs: [templateTab],
    );
  }

  static String createMarkdown(
    TemplateProject template,
    Uri templateTabUri,
    Generator generator,
    Exception exception,
    StackTrace stackTrace,
  ) {
    return '## Source\n'
        '* Template: [${template.name}]($templateTabUri)\n'
        '* Generator source: ${generator.source}\n'
        '## Exception\n'
        '${exception.toString()}\n'
        '## Stack trace\n'
        '${stackTrace.toString().replaceAll('\n', '\\\n')}\n';
  }
}

// Uses a template engine to create the output path eg:
// * outputPath: '{{removeFileExtension(sysmacProjectFilePath)}}-Sysmac-PackMlMonitor.xml'
// * parameters: { sysmacProjectFilePath: 'C:/myProject/sysmacProject.smc2' }
// * result: 'C:/myProject/sysmacProject-Sysmac-PackMlMonitor.xml'
