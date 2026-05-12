import 'package:meyncraft/meyncraft/presentation/markdown_tab.presentation.dart';

class GeneratorResultTab extends MarkdownTab {
  GeneratorResultTab({super.key})
    : super(DynamicMarkdownTabContent('Generator result'));
}

// class _GeneratorResultTabState extends State<GeneratorResultTab> {
//   @override
//   Widget build(BuildContext context) => ListenableBuilder(
//     listenable: widget.outputReport,
//     builder: (BuildContext context, Widget? child) => Markdown(
//       styleSheet: MeynMarkdownStyleSheet(context),
//       data: widget.outputReport.markdown,
//       onTapLink: onLinkTap,
//     ),
//   );

//   void onLinkTap(String text, String? href, String? title) {
//     if (href != null) {
//       var uri = Uri.parse(href);
//       switch (uri.scheme.toLowerCase()) {
//         case 'meyncraft':
//           openMeynCraftTab(uri);
//           break;
//         case 'file':
//           openFileExplorerOpFileLocation(uri);
//           break;
//         default:
//           launchUrl(uri);
//       }
//     }
//   }

//   void openMeynCraftTab(Uri meynCraftUri) {
//     var templateName = meynCraftUri.path;
//     var template = allTemplates().firstWhere(
//       (t) => t.name == templateName,
//       orElse: () => throw Exception('Template not found: $templateName'),
//     );
//     var tabService = GetIt.I.get<TabService>();
//     tabService.addOrSelectTab(TemplateDetailTab(template: template));
//   }

//   void openFileExplorerOpFileLocation(Uri fileUri) {
//     final file = File.fromUri(fileUri);
//     Process.run('explorer', ['/select,', file.path]);
//   }
// }
