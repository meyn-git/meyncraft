import 'package:flutter/material.dart';
import 'package:meyncraft/meyncraft/presentation/meyncraft_info.service.dart';
import 'package:meyncraft/meyncraft/presentation/tab.presentation.dart';
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
        return createInfo(version);
      } else {
        return createInfo();
      }
    },
  );

  Widget createInfo([String? version]) => Markdown(
    styleSheet: MarkdownStyleSheet(pPadding: EdgeInsets.symmetric(vertical: 6)),
    data: meynCraftInfoMarkdown(version: version),
    onTapLink: (text, href, title) {
      if (href != null) {
        launchUrl(Uri.parse(href));
      }
    },
  );
}
