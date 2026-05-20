import 'dart:io';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:get_it/get_it.dart';
import 'package:meyncraft/meyncraft/tab/tab.presentation.dart';
import 'package:meyncraft/meyncraft/tab/tab.service.dart';
import 'package:meyncraft/meyncraft/style/markdown_style_sheet.presentation.dart';
import 'package:meyncraft/template/template.domain.dart';
import 'package:meyncraft/template/template_about_tab.presentation.dart';
import 'package:url_launcher/url_launcher.dart';

class GeneratorParametersTab extends ClosableTab {
  final List<TemplateProject> templatesToGenerate;

  const GeneratorParametersTab({super.key, required this.templatesToGenerate})
    : super(tabTitle: 'Generator Parameters');

  @override
  State<StatefulWidget> createState() => _GeneratorParametersTabState();
}

class _GeneratorParametersTabState extends State<GeneratorParametersTab> {
  @override
  Widget build(BuildContext context) =>
      ParameterForm(widget.templatesToGenerate, widget);
}

class ParameterForm extends StatefulWidget {
  final List<TemplateProject> templatesToGenerate;
  final GeneratorParametersTab tab;
  const ParameterForm(this.templatesToGenerate, this.tab, {super.key});

  @override
  State<ParameterForm> createState() => _ParameterFormState();
}

class _ParameterFormState extends State<ParameterForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _pathController = TextEditingController();

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles();

    if (result != null && result.files.single.path != null) {
      _pathController.text = result.files.single.path!;
      _formKey.currentState!.validate(); // re-run validation
    }
  }

  String? _validatePath(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please select a file';
    }

    final file = File(value);
    if (!file.existsSync()) {
      return 'File does not exist';
    }

    return null;
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      debugPrint('Valid path: ${_pathController.text}');
    }
  }

  @override
  void dispose() {
    _pathController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: MarkdownBody(
                  styleSheet: MeynMarkdownStyleSheet(context),
                  data: createMarkdown(),
                  onTapLink: (text, href, title) {
                    openHref(href);
                  },
                ),
              ),
              TextFormField(
                controller: _pathController,
                validator: _validatePath,
                decoration: InputDecoration(
                  labelText: 'Sysmac Project File',
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.folder_open),
                    onPressed: _pickFile,
                  ),
                ),
                //readOnly: true, // optional: prevents manual editing
              ),

              const Spacer(),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 200,
                    child: ElevatedButton(
                      onPressed: _submit,

                      child: const Text('Generate'),
                    ),
                  ),
                  SizedBox(width: 16),
                  SizedBox(
                    width: 200,
                    child: OutlinedButton(
                      onPressed: () {
                        GetIt.I.get<TabService>().closeTab(widget.tab);
                      },

                      child: const Text('Cancel'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void openHref(String? href) {
    if (href != null) {
      var uri = Uri.parse(href);
      if (uri.scheme == 'detail') {
        var templateName = uri.path;
        var template = widget.templatesToGenerate.firstWhere(
          (t) => t.name == templateName,
          orElse: () => throw Exception('Template not found: $templateName'),
        );
        var tabService = GetIt.I.get<TabService>();
        tabService.addOrSelectTab(TemplateAboutTab(template));
      } else {
        launchUrl(uri);
      }
    }
  }

  String createMarkdown() =>
      '# Templates to generate\n\n'
      '${widget.templatesToGenerate.map((t) => '[${t.name}](detail:${t.name})').join(', ')}\n'
      '# Parameters\n\n';
}
