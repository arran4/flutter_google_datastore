import 'package:flutter/material.dart';
import 'package:gcloud/datastore.dart' as datastore;
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

void main() {
  runApp(const MyApp());
}

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

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class UrlEntry {
  final int id;
  final String url;
  final String username;
  final String password;

  UrlEntry({required this.id, required this.url, required this.username, required this.password});
}

class _LoginPageState extends State<LoginPage> {
  late Future<List<UrlEntry>> urlEntries;

  @override
  void initState() {
    super.initState();
    urlEntries = _loadEntries();
  }

  Future<List<UrlEntry>> _loadEntries() async {
    final database = await openDatabase(
      p.join(await getDatabasesPath(), 'urls_database.db'),
      onCreate: (db, version) {
        return db.execute(
          'CREATE TABLE urls(id INTEGER PRIMARY KEY, url TEXT, username TEXT, password TEXT)',
        );
      },
      version: 1,
    );

    final List<Map<String, dynamic>> maps = await database.query('urls');
    await database.close();

    return List.generate(maps.length, (i) {
      return UrlEntry(
        id: maps[i]['id'],
        url: maps[i]['url'],
        username: maps[i]['username'],
        password: maps[i]['password'],
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text("Datastore login"),
      ),
      body: ListView.builder(
          itemCount: urlEntries.length,
          itemBuilder: (BuildContext context, int index) {
            return ListTile(
              title: Text(urlEntries[index].url),
              subtitle: Text('Username: ${urlEntries[index].username}\nPassword: ${urlEntries[index].password}'),
              // You can add onTap functionality here if needed
            );
          },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: addLogin,
        tooltip: 'addLogin',
        child: const Icon(Icons.add),
      ),
    );
  }
}
