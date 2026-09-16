import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_google_datastore/main.dart';
import 'package:flutter_google_datastore/ui/confirmation_dialog.dart';
import 'package:settings_ui/settings_ui.dart';

class SettingsWidget extends StatefulWidget {
  final Future<String> Function() filepathCallback;
  final Future<void> Function() databaseDeleteCallback;

  SettingsWidget({
    super.key,
    Future<String> Function()? filepathCallback,
    Future<void> Function()? databaseDeleteCallback,
  }) : filepathCallback = filepathCallback ?? (() => db.filepath()),
       databaseDeleteCallback =
           databaseDeleteCallback ?? (() => db.deleteEntireDatabase());

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
    widget.filepathCallback().then(
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
                        title: 'Delete Entire database?',
                        content: 'Delete Entire database ?',
                        onCancel: () {
                          Navigator.of(context).pop();
                        },
                        onConfirm: () async {
                          await widget.databaseDeleteCallback();
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
