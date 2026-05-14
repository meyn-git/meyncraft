import 'package:flutter/material.dart';
import 'package:meyncraft/meyncraft/about/meyncraft_about_tab.domain.dart';
import 'package:meyncraft/meyncraft/tab/tab.presentation.dart';
import 'package:meyncraft/meyncraft/style/markdown_style_sheet.presentation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

class MeynCraftAboutTab extends ClosableTab {
  const MeynCraftAboutTab({super.key})
    : super(tabTitle: 'About MeynCraft', closable: true);

  @override
  State<StatefulWidget> createState() => _MeynCraftAboutTabState();
}

class _MeynCraftAboutTabState extends State<MeynCraftAboutTab> {
  @override
  Widget build(BuildContext context) => FutureBuilder(
    future: applicationVersion(),
    builder: (context, AsyncSnapshot<String> snapshot) {
      if (snapshot.hasData) {
        final version = snapshot.data!;
        return createInfo(context, version);
      } else {
        return createInfo(context);
      }
    },
  );

  Widget createInfo(BuildContext context, [String? version]) => Markdown(
    styleSheet: MeynMarkdownStyleSheet(context),
    data: aboutMeynCraftMarkdown(version: version),
    onTapLink: (text, href, title) {
      if (href != null) {
        launchUrl(Uri.parse(href));
      }
    },
  );
}
