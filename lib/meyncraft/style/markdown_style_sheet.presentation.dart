import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

class MeynMarkdownStyleSheet extends MarkdownStyleSheet {
  MeynMarkdownStyleSheet(BuildContext context)
    : super(
        h1Padding: EdgeInsets.fromLTRB(0, 12, 0, 6),
        h2Padding: EdgeInsets.fromLTRB(0, 12, 0, 0),
        a: TextStyle(color: Theme.of(context).colorScheme.secondary),
      );
}
