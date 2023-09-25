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

  void itemPopupItemSelected(Project project, String value) {
    switch (value) {
      case 'connect':
        connectPressed(project);
        break;
      case 'edit':
        editProjectPressed(project);
        break;
      case 'delete':
        deletePressed(project);
        break;
    }
  }

  List<PopupMenuEntry<String>> createItemPopupItems(BuildContext context) {
    return <PopupMenuEntry<String>>[
      const PopupMenuItem<String>(
        value: 'connect',
        child: Text('Connect'),
      ),
      const PopupMenuItem<String>(
        value: 'edit',
        child: Text('Edit'),
      ),
      const PopupMenuItem<String>(
        value: 'delete',
        child: Text('Delete'),
      ),
    ];
  }

  addProjectPressed () async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const AddEditProjectScreen(),
      ),
    );
    setState(() {
      projects = _loadEntries();
    });
  }

  editProjectPressed (Project project) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddEditProjectScreen(project: project),
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
                        connectPressed(projects[index]);
                      }, child: const Text("Connect")),
                      PopupMenuButton<String>(
                        onSelected: (String value) => itemPopupItemSelected(projects[index], value),
                        itemBuilder: createItemPopupItems,
                      ),
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
        tooltip: 'Add Project',
        child: const Icon(Icons.add),
      ),
    );
  }

  void connectPressed(Project project) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => DatastoreMainPage(project: project,),
      ),
    );
  }

  void deletePressed(Project project) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => DeleteProjectScreen(project: project,),
      ),
    );
    setState(() {
      projects = _loadEntries();
    });
  }
}

class AddEditProjectScreen extends StatefulWidget {
  final Project? project;
  const AddEditProjectScreen({super.key, this.project});

  @override
  AddEditProjectScreenState createState() => AddEditProjectScreenState();
}

class AddEditProjectScreenState extends State<AddEditProjectScreen> {
  final TextEditingController endpointUrlController = TextEditingController();
  final TextEditingController projectIdController = TextEditingController();

  void saveProject() async {
    String? endpointUrl = endpointUrlController.text;
    if (endpointUrl.isEmpty) {
      endpointUrl = null;
    }
    var project = widget.project;
    if (project == null) {
      await db.createNewProject(
        endpointUrl,
        projectIdController.text,
      );
    } else {
      await db.updateProject(
        project.id,
        endpointUrl,
        projectIdController.text,
      );
    }

    if (!context.mounted) return;
    Navigator.of(context).pop();
  }


  @override
  void initState() {
    projectIdController.text = widget.project?.projectId ?? "";
    endpointUrlController.text = widget.project?.endpointUrl ?? "";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.project == null ? 'Add Project' : 'Edit Project'),
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
              onPressed: saveProject,
              child: Text(widget.project == null ? 'Add Project' : 'Edit Project'),
            ),
          ],
        ),
      ),
    );
  }
}

class DeleteProjectScreen extends StatelessWidget {
  final Project project;
  const DeleteProjectScreen({super.key, required this.project});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Delete Project?'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text("Delete ${project.projectId} @ ${project.endpointUrl} ?"),
            ButtonBar(
              children: [
                ElevatedButton(
                  onPressed: () => back(context),
                  child: const Text("Don't Delete"),
                ),
                ElevatedButton(
                  onPressed: () => deleteProject(context),
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

  void deleteProject(BuildContext context) async {
    await db.deleteProject(project.id);
    await db.removeProject(project.id);
    if (context.mounted) {
      Navigator.of(context).pop();
    }
  }
}
