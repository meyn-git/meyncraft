import 'package:meyncraft/meyncraft/about/meyncraft_about_tab.domain.dart';
import 'package:meyncraft/meyncraft/command.domain.dart';
import 'package:meyncraft/meyncraft/command.presentation.dart';
import 'package:meyncraft/meyncraft/tab/markdown_tab.presentation.dart';

class MeynCraftAboutTab extends MarkdownTab {
  MeynCraftAboutTab._(super.content);

  static Future<MeynCraftAboutTab> create() async {
    final version = await applicationVersion();
    final content = StaticMarkdownContent(
      tabTitle: 'About MeynCraft',
      markdown: aboutMeynCraftMarkdown(version: version),
      buttons: [ElevatedCommandButton(CloseCurrentTab())],
    );
    return MeynCraftAboutTab._(content);
  }
}

// class _MeynCraftAboutTabState extends State<MeynCraftAboutTab> {
//   @override
//   Widget build(BuildContext context) => FutureBuilder(
//     future: applicationVersion(),
//     builder: (context, AsyncSnapshot<String> snapshot) {
//       if (snapshot.hasData) {
//         final version = snapshot.data!;
//         return createInfo(context, version);
//       } else {
//         return createInfo(context);
//       }
//     },
//   );

//   Widget createInfo(BuildContext context, [String? version]) => Markdown(
//     styleSheet: MeynMarkdownStyleSheet(context),
//     data: aboutMeynCraftMarkdown(version: version),
//     onTapLink: (text, href, title) {
//       if (href != null) {
//         launchUrl(Uri.parse(href));
//       }
//     },
//   );
// }
