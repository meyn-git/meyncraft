import 'package:flutter/material.dart';
import 'package:meyncraft/meyncraft/logger/logger.service.dart';
import 'package:meyncraft/meyncraft/meyncraft.presentation.dart';

class LogView extends StatefulWidget {
  const LogView({super.key});

  @override
  State<LogView> createState() => _LogViewState();
}

class _LogViewState extends State<LogView> {
  @override
  void initState() {
    super.initState();
    logger.addListener(_onLogUpdate);
  }

  @override
  void dispose() {
    logger.removeListener(_onLogUpdate);
    super.dispose();
  }

  void _onLogUpdate() => setState(() {});

  final ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: Container(
              padding: EdgeInsets.all(8),
              child: Scrollbar(
                controller: _scrollController,
                child: ListView.builder(
                  controller: _scrollController,
                  itemCount: logger.messages.length,
                  itemBuilder: (context, index) {
                    return SelectableText(
                      logger.messages[index].text,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        color: logger.messages[index].messageType.colorFunction(
                          theme,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          if (logger.completed) RestartButtonBar(),
        ],
      ),
    );
  }
}

class RestartButtonBar extends StatelessWidget {
  const RestartButtonBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      padding: EdgeInsets.all(8),
      child: OverflowBar(
        alignment: MainAxisAlignment.end,
        children: [
          Center(
            child: ElevatedButton(
              onPressed: () async => await selectSysmacFileAndGenerate(),
              child: Text('Generate for another project'),
            ),
          ),
        ],
      ),
    );
  }
}
