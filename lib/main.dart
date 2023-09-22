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
      home: const LoginPage(),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  late Future<List<UrlEntry>> urlEntries;

  @override
  void initState() {
    super.initState();
    urlEntries = _loadEntries();
  }

  Future<List<UrlEntry>> _loadEntries() async {
    return db.getUrlEntries;
  }

  void popupItemSelected(String value) {
    switch (value) {
      case 'settings':
        Navigator.push(context, MaterialPageRoute<bool>(builder: (BuildContext context) {
          return const SettingsWidget();
        })).then((dynamic value) {
          setState(() {
            urlEntries = _loadEntries();
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

  addLoginPressed () async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const AddLoginScreen(),
      ),
    );
    setState(() {
      urlEntries = _loadEntries();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text("Datastore login"),
        actions: <Widget>[
          TextButton(onPressed: addLoginPressed, child: const Text("Add")),
          PopupMenuButton<String>(
            onSelected: popupItemSelected,
            itemBuilder: createPopupItems,
          ),
        ],
      ),
      body: FutureBuilder<List<UrlEntry>>(
        future: urlEntries,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CircularProgressIndicator();
          } else if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          } else {
            final urlEntries = snapshot.data;
            return ListView.builder(
              itemCount: urlEntries!.length,
              itemBuilder: (BuildContext context, int index) {
                return ListTile(
                  title: Text(urlEntries[index].url),
                  subtitle: Text('Username: ${urlEntries[index].username}'),
                  trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton(onPressed: () {
                        connectPressed(index,urlEntries[index]);
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
        onPressed: addLoginPressed,
        tooltip: 'addLogin',
        child: const Icon(Icons.add),
      ),
    );
  }

  void connectPressed(int index, UrlEntry urlEntry) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => DatastoreMainPage(index: index, urlEntry: urlEntry,),
      ),
    );
  }
}

class AddLoginScreen extends StatefulWidget {
  const AddLoginScreen({super.key});

  @override
  _AddLoginScreenState createState() => _AddLoginScreenState();
}

class _AddLoginScreenState extends State<AddLoginScreen> {
  final TextEditingController urlController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  void addLogin() async {
    await db.createNewUrlEntry(
      urlController.text,
      usernameController.text,
      passwordController.text,
    );

    if (!context.mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Login'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            TextField(
              controller: urlController,
              decoration: const InputDecoration(labelText: 'URL'),
            ),
            TextField(
              controller: usernameController,
              decoration: const InputDecoration(labelText: 'Username'),
            ),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true, // Hide password text
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: addLogin,
              child: const Text('Add Login'),
            ),
          ],
        ),
      ),
    );
  }
}
