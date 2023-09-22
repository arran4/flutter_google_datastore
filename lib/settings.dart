import 'package:flutter/material.dart';
import 'package:flutter_google_datastore/main.dart';
import 'package:settings_ui/settings_ui.dart';

class SettingsWidget extends StatefulWidget {
  const SettingsWidget({super.key});

  @override
  State<StatefulWidget> createState() {
    return SettingsWidgetState();
  }

}

class SettingsWidgetState extends State<SettingsWidget> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("Flutter Google Datastore: Settings"),
        ),
        body: SettingsList(
          sections: <AbstractSettingsSection>[
            SettingsSection(
              title: const Text('Advanced'),
              tiles: <SettingsTile>[
                SettingsTile.navigation(
                  leading: const Icon(Icons.dangerous),
                  title: const Text('Delete Database'),
                  onPressed: (BuildContext context) {
                    db.deleteEntireDatabase();
                  },
                ),
              ],
            ),
          ],
        ),
    );
  }
}
