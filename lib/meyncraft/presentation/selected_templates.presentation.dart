import 'package:flutter/material.dart';

class SelectedTemplatesPanel extends StatelessWidget {
  const SelectedTemplatesPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 40,
          width: double.infinity,
          alignment: Alignment.centerLeft,
          color: Colors.black,
          padding: const EdgeInsets.only(left: 8),
          child: const Text(
            'Selected templates',
            style: TextStyle(color: Colors.white),
          ),
        ),

        /// ✅ ListView now has bounded height
        Expanded(
          child: ListView(
            children: const [
              ListTile(
                title: Text('JMobileTags'),
                subtitle: Text(
                  'Creates JMobile tags from a Sysmac project file.',
                ),
              ),
              ListTile(
                title: Text('JMobileEvents'),
                subtitle: Text(
                  'Creates JMobile events from a Sysmac project file.',
                ),
              ),
              ListTile(
                title: Text('SysmacEventGlobalArray'),
                subtitle: Text(
                  'Creates EventGlobalArray mapping code from a Sysmac project file.',
                ),
              ),
              ListTile(
                title: Text('EventReport'),
                subtitle: Text(
                  'Generates a report of events from a Sysmac project.',
                ),
              ),
              ListTile(
                title: Text('Isa88Report'),
                subtitle: Text(
                  'Generates an ISA 88 report from a Sysmac project.',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
