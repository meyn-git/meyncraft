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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Expanded(
        child: Column(
          children: [
            Expanded(
              child: Container(
                padding: EdgeInsets.all(8),
                child: Scrollbar(
                  child: ListView.builder(
                    itemCount: logger.logs.length,
                    itemBuilder: (context, index) {
                      return Text(
                        logger.logs[index],
                        style: TextStyle(fontFamily: 'monospace'),
                      );
                    },
                  ),
                ),
              ),
            ),
            if (logger.completed)
              RestartButtonBar(),
          ],
        ),
      ),
    );
  }
}

class RestartButtonBar extends StatelessWidget {
  const RestartButtonBar({
    super.key,
  });

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
