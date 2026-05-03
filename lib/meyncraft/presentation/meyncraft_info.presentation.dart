import 'package:flutter/material.dart';
import 'package:meyncraft/meyncraft/presentation/meyncraft_info.service.dart';
import 'package:meyncraft/meyncraft/presentation/tab.presentation.dart';
import 'package:meyncraft/meyncraft/style/markdown_style_sheet.presentation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

class MeynCraftInfoTab extends ClosableTab {
  MeynCraftInfoTab() : super(tabName: 'MeynCraft Info', closable: true);

  @override
  Widget buildContent(BuildContext context) => FutureBuilder(
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
    data: meynCraftInfoMarkdown(version: version),
    onTapLink: (text, href, title) {
      if (href != null) {
        launchUrl(Uri.parse(href));
      }
    },
  );
}
