import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_google_datastore/main.dart';
import 'package:settings_ui/settings_ui.dart';
import 'ui/confirmation_dialog.dart';

class SettingsWidget extends StatefulWidget {
  const SettingsWidget({super.key});

  @override
  State<StatefulWidget> createState() {
    return SettingsWidgetState();
  }
}

class SettingsWidgetState extends State<SettingsWidget> {
  String fp = "Loading";

  @override
  void initState() {
    super.initState();
    db.filepath().then(
          (value) => {
            setState(() {
              fp = value;
            }),
          },
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Flutter Google Datastore: Settings")),
      body: SettingsList(
        sections: <AbstractSettingsSection>[
          SettingsSection(
            title: const Text('Advanced'),
            tiles: <SettingsTile>[
              SettingsTile.navigation(
                leading: const Icon(Icons.dangerous),
                title: const Text('Delete Database'),
                description: Text("SQLFile: $fp"),
                onPressed: (BuildContext context) {
                  unawaited(
                    showDialog(
                      context: context,
                      builder: (context) => DestructiveConfirmationDialog(
                        title: 'Delete Entire Database?',
                        content:
                            'Are you sure you want to delete the entire database?',
                        onCancel: () => Navigator.of(context).pop(),
                        onConfirm: () async {
                          await db.deleteEntireDatabase();
                          if (context.mounted) {
                            Navigator.of(context).pop();
                          }
                        },
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
