import 'responsive_layout.dart';
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_google_datastore/settings.dart';
import 'package:flutter_google_datastore/ui/confirmation_dialog.dart';
import 'database.dart';
import 'datastoremain.dart';
import 'package:timezone/data/latest.dart' as tz;

void main() {
  tz.initializeTimeZones();
  runApp(const MyApp());
}

final db = DB();

// Yes I know this is a mess I will clean it up when it becomes appropriate, it was quickly written to get the app working + using gpt etc didn't help at all.

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Datastore explorer',
      theme: ThemeData(useMaterial3: true),
      home: ProjectPage(),
    );
  }
}

class ProjectPage extends StatefulWidget {
  final Future<List<Project>> Function() projectLoadCallback;
  final Future<void> Function(Project project) projectDeleteCallback;

  ProjectPage({
    super.key,
    Future<List<Project>> Function()? projectLoadCallback,
    Future<void> Function(Project project)? projectDeleteCallback,
  })  : projectLoadCallback = projectLoadCallback ?? (() => db.getProjects),
        projectDeleteCallback = projectDeleteCallback ??
            ((Project project) async {
              await db.deleteProject(project.id);
              await db.removeProject(project.id);
            });

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
    return widget.projectLoadCallback();
  }

  Future<void> popupItemSelected(String value) async {
    switch (value) {
      case 'add':
        await addProjectPressed();
        break;
      case 'refresh':
        setState(() {
          projects = _loadEntries();
        });
        break;
      case 'settings':
        await Navigator.push(
          context,
          MaterialPageRoute<bool>(
            builder: (BuildContext context) {
              return SettingsWidget();
            },
          ),
        );
        if (!mounted) return;
        setState(() {
          projects = _loadEntries();
        });
        break;
    }
  }

  List<PopupMenuEntry<String>> createPopupItems(BuildContext context) {
    return <PopupMenuEntry<String>>[
      const PopupMenuItem<String>(value: 'add', child: Text('Add')),
      const PopupMenuItem<String>(value: 'refresh', child: Text('Refresh')),
      const PopupMenuItem<String>(value: 'settings', child: Text('Settings')),
    ];
  }

  Future<void> itemPopupItemSelected(Project project, String value) async {
    switch (value) {
      case 'connect':
        await connectPressed(project);
        break;
      case 'edit':
        await editProjectPressed(project);
        break;
      case 'delete':
        await deletePressed(project);
        break;
    }
  }

  List<PopupMenuEntry<String>> createItemPopupItems(BuildContext context) {
    return <PopupMenuEntry<String>>[
      const PopupMenuItem<String>(value: 'connect', child: Text('Connect')),
      const PopupMenuItem<String>(value: 'edit', child: Text('Edit')),
      const PopupMenuItem<String>(value: 'delete', child: Text('Delete')),
    ];
  }

  Future<void> addProjectPressed() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const AddEditProjectScreen()),
    );
    if (!mounted) return;
    setState(() {
      projects = _loadEntries();
    });
  }

  Future<void> editProjectPressed(Project project) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddEditProjectScreen(project: project),
      ),
    );
    if (!mounted) return;
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
          PopupMenuButton<String>(
            onSelected: (value) async {
              await popupItemSelected(value);
            },
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
                  subtitle: Text(
                    'Endpoint: ${projects[index].endpointUrl ?? "default"}',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton(
                        onPressed: () async {
                          await connectPressed(projects[index]);
                        },
                        child: const Text("Connect"),
                      ),
                      PopupMenuButton<String>(
                        onSelected: (String value) async {
                          await itemPopupItemSelected(projects[index], value);
                        },
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
        onPressed: () async {
          await addProjectPressed();
        },
        tooltip: 'Add Project',
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> connectPressed(Project project) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => DatastoreMainPage(project: project),
      ),
    );
  }

  Future<void> deletePressed(Project project) async {
    await showDialog(
      context: context,
      builder: (context) => DestructiveConfirmationDialog(
        title: 'Delete Project?',
        content: 'Delete ${project.projectId} @ ${project.endpointUrl} ?',
        onCancel: () {
          Navigator.of(context).pop();
        },
        onConfirm: () async {
          await widget.projectDeleteCallback(project);
          if (context.mounted) {
            Navigator.of(context).pop();
          }
        },
      ),
    );
    if (!mounted) return;
    setState(() {
      projects = _loadEntries();
    });
  }
}

final authModes = createAuthModes();

const gcloudCliAuthMode = "gcloud cli";

List<String> createAuthModes() {
  var elements = ["none"];
  if (Platform.isLinux) {
    elements.add(gcloudCliAuthMode);
  }
  return List.of(elements, growable: false);
}

class AddEditProjectScreen extends StatefulWidget {
  final Project? project;
  final GCloudCLICredentialDiscover? credentialDiscoverer;

  const AddEditProjectScreen({
    super.key,
    this.project,
    this.credentialDiscoverer,
  });

  @override
  AddEditProjectScreenState createState() => AddEditProjectScreenState();
}

class AddEditProjectScreenState extends State<AddEditProjectScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController endpointUrlController = TextEditingController();
  final TextEditingController projectIdController = TextEditingController();
  final TextEditingController databaseIdController = TextEditingController();
  String authMode = "none";
  late final GCloudCLICredentialDiscover _defaultCredentialDiscover =
      GCloudCLICredentialDiscover();

  GCloudCLICredentialDiscover get gCloudCLICredentialDiscover =>
      widget.credentialDiscoverer ?? _defaultCredentialDiscover;

  String? googleCliProfile;

  void saveProject() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    String? endpointUrl = endpointUrlController.text;
    if (endpointUrl.isEmpty) {
      endpointUrl = null;
    }
    String databaseId = databaseIdController.text;
    var project = widget.project;
    if (project == null) {
      await db.createNewProject(
        endpointUrl,
        projectIdController.text,
        authMode,
        googleCliProfile,
        databaseId,
      );
    } else {
      await db.updateProject(
        project.id,
        endpointUrl,
        projectIdController.text,
        authMode,
        googleCliProfile,
        databaseId,
      );
    }

    // ignore: use_build_context_synchronously
    if (context.mounted && Navigator.canPop(context)) {
      // ignore: use_build_context_synchronously
      Navigator.of(context).pop();
    }
  }

  @override
  void initState() {
    super.initState();
    projectIdController.text = widget.project?.projectId ?? "";
    endpointUrlController.text = widget.project?.endpointUrl ?? "";
    databaseIdController.text = widget.project?.databaseId ?? "";
    authMode = widget.project?.authMode ?? "none";
    googleCliProfile = widget.project?.googleCliProfile;
  }

  @override
  Widget build(BuildContext context) {
    Widget? googleCliWidget;
    if (authMode == gcloudCliAuthMode) {
      googleCliWidget = FutureBuilder<GCloudProfileDiscoveryResult>(
        future: gCloudCLICredentialDiscover.initFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Padding(
              padding: EdgeInsets.all(8.0),
              child: Row(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(width: ResponsiveSpacing.md),
                  Text('Loading profiles...'),
                ],
              ),
            );
          } else if (snapshot.hasError) {
            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Failed to load profiles: ${snapshot.error}',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            );
          } else if (snapshot.hasData) {
            final availableProfiles = snapshot.data!.profiles;
            if (!availableProfiles.contains(googleCliProfile)) {
              // Wait for build to finish before updating state to avoid warnings
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  setState(() {
                    googleCliProfile = availableProfiles.isNotEmpty
                        ? availableProfiles.first
                        : null;
                  });
                }
              });
            }

            // It's possible that googleCliProfile is still the old value during this build frame,
            // so we make sure the DropdownButtonFormField value exists in the items.
            String? currentValue = availableProfiles.contains(googleCliProfile)
                ? googleCliProfile
                : (availableProfiles.isNotEmpty
                    ? availableProfiles.first
                    : null);

            return DropdownButtonFormField<String>(
              initialValue: currentValue,
              decoration:
                  const InputDecoration(labelText: 'Google CLI Profile'),
              icon: const Icon(Icons.arrow_downward),
              elevation: 16,
              onChanged: (String? value) {
                setState(() {
                  googleCliProfile = value;
                });
              },
              items: availableProfiles
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                    value: value, child: Text(value));
              }).toList(),
            );
          } else {
            return const SizedBox();
          }
        },
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.project == null ? 'Add Project' : 'Edit Project'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(ResponsiveSpacing.md),
          child: ResponsiveContainer(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FormSection(
                    title: 'Project identity',
                    child: ResponsiveTwoColumnRow(
                      left: TextFormField(
                        controller: projectIdController,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Project ID',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Project ID cannot be empty';
                          }
                          return null;
                        },
                      ),
                      right: TextFormField(
                        controller: databaseIdController,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Database ID (blank for default)',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: ResponsiveSpacing.lg),
                  FormSection(
                    title: 'Connection',
                    child: TextFormField(
                      controller: endpointUrlController,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Endpoint URL (blank for default)',
                        helperText:
                            'Leave blank to use the default Google Cloud Datastore endpoint.',
                      ),
                    ),
                  ),
                  const SizedBox(height: ResponsiveSpacing.lg),
                  FormSection(
                    title: 'Authentication',
                    child: ResponsiveTwoColumnRow(
                      left: DropdownButtonFormField<String>(
                        initialValue: authMode,
                        decoration: const InputDecoration(
                          labelText: 'Authentication mode',
                        ),
                        icon: const Icon(Icons.arrow_downward),
                        elevation: 16,
                        onChanged: (String? value) {
                          setState(() {
                            authMode = value!;
                          });
                        },
                        items: authModes.map<DropdownMenuItem<String>>((
                          String value,
                        ) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                      ),
                      right: googleCliWidget,
                    ),
                  ),
                  const SizedBox(height: ResponsiveSpacing.lg),
                  FormSection(
                    title: 'Actions',
                    child: ResponsiveFormActions(
                      children: [
                        FutureBuilder<GCloudProfileDiscoveryResult>(
                            future: gCloudCLICredentialDiscover.initFuture,
                            builder: (context, snapshot) {
                              bool disableSave =
                                  authMode == gcloudCliAuthMode &&
                                      (snapshot.connectionState ==
                                              ConnectionState.waiting ||
                                          snapshot.hasError);
                              return ElevatedButton(
                                onPressed: disableSave ? null : saveProject,
                                child: Text(
                                  widget.project == null
                                      ? 'Add Project'
                                      : 'Save Project',
                                ),
                              );
                            }),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
