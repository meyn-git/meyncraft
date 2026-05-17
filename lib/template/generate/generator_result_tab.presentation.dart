import 'package:meyncraft/meyncraft/tab/markdown_tab.presentation.dart';
import 'package:meyncraft/template/template.domain.dart';

class GeneratorResultTab extends MarkdownTab {
  final List<Template> selectedTemplates;
  final Map<String, dynamic> parameterValues;

  GeneratorResultTab(this.selectedTemplates, this.parameterValues, {super.key})
    : super(DynamicMarkdownTabContent('Generator result'));
}
