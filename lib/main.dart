import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_google_datastore/settings.dart';
import 'database.dart';
import 'datastoremain.dart';

void main() {
  runApp(const MyApp());
}

final db = DB();

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Datastore explorer',
      theme: ThemeData(
        useMaterial3: true,
      ),
      home: const ProjectPage(),
    );
  }
}

class ProjectPage extends StatefulWidget {
  const ProjectPage({super.key});

  @override
  State<ProjectPage> createState() => _ProjectPageState();
}

class _ProjectPageState extends State<ProjectPage> {
  late Future<List<Project>> projects;

  @override
  void initState() {
    super.initState();
    projects = _loadEntries();
  }

  Future<List<Project>> _loadEntries() async {
    return db.getProjects;
  }

  void popupItemSelected(String value) {
    switch (value) {
      case 'settings':
        Navigator.push(context, MaterialPageRoute<bool>(builder: (BuildContext context) {
          return const SettingsWidget();
        })).then((dynamic value) {
          setState(() {
            projects = _loadEntries();
          });
        });
        break;
    }
  }

  List<PopupMenuEntry<String>> createPopupItems(BuildContext context) {
    return <PopupMenuEntry<String>>[
      const PopupMenuItem<String>(
        value: 'settings',
        child: Text('Settings'),
      ),
    ];
  }

  addProjectPressed () async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const AddProjectScreen(),
      ),
    );
    setState(() {
      projects = _loadEntries();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text("Datastore Project"),
        actions: <Widget>[
          TextButton(onPressed: addProjectPressed, child: const Text("Add")),
          PopupMenuButton<String>(
            onSelected: popupItemSelected,
            itemBuilder: createPopupItems,
          ),
        ],
      ),
      body: FutureBuilder<List<Project>>(
        future: projects,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CircularProgressIndicator();
          } else if (snapshot.hasError) {
            return SelectableText('Error: ${snapshot.error}');
          } else {
            final projects = snapshot.data;
            return ListView.builder(
              itemCount: projects!.length,
              itemBuilder: (BuildContext context, int index) {
                return ListTile(
                  title: Text(projects[index].projectId),
                  subtitle: Text('Endpoint: ${projects[index].endpointUrl ?? "default"}'),
                  trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton(onPressed: () {
                        connectPressed(index,projects[index]);
                      }, child: const Text("Connect")),
                    ],
                  ),
                );
              },
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: addProjectPressed,
        tooltip: 'addProject',
        child: const Icon(Icons.add),
      ),
    );
  }

  void connectPressed(int index, Project project) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => DatastoreMainPage(index: index, project: project,),
      ),
    );
  }
}

class AddProjectScreen extends StatefulWidget {
  const AddProjectScreen({super.key});

  @override
  _AddProjectScreenState createState() => _AddProjectScreenState();
}

class _AddProjectScreenState extends State<AddProjectScreen> {
  final TextEditingController endpointUrlController = TextEditingController();
  final TextEditingController projectIdController = TextEditingController();

  void addProject() async {
    String? endpointUrl = endpointUrlController.text;
    if (endpointUrl.isEmpty) {
      endpointUrl = null;
    }
    await db.createNewProject(
      endpointUrl,
      projectIdController.text,
    );

    if (!context.mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Project'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            TextField(
              controller: endpointUrlController,
              decoration: const InputDecoration(labelText: 'Endpoint URL (blank for default)'),
            ),
            TextField(
              controller: projectIdController,
              decoration: const InputDecoration(labelText: 'Project'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: addProject,
              child: const Text('Add Project'),
            ),
          ],
        ),
      ),
    );
  }
}
