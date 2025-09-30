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
  String fp = "Loading";

  @override
  void initState() {
    db.filepath().then((value) => {
          setState(() {
            fp = value;
          })
        });
  }

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
                description: Text("SQLFile: $fp"),
                onPressed: (BuildContext context) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const DeleteDatabaseScreen(),
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

class DeleteDatabaseScreen extends StatelessWidget {
  const DeleteDatabaseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Delete Entire database?'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text("Delete Entire database ?"),
            ButtonBar(
              children: [
                ElevatedButton(
                  onPressed: () => back(context),
                  child: const Text("Don't Delete"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    await deleteProject(context);
                  },
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.resolveWith((states) => Colors.red),
                  ),
                  child: const Text("Delete"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }


  void back(BuildContext context) {
    Navigator.of(context).pop();
  }

  Future<void> deleteProject(BuildContext context) async {
    await db.deleteEntireDatabase();
    if (context.mounted) {
      Navigator.of(context).pop();
    }
  }
}
