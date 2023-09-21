import 'package:flutter/material.dart';
import 'package:gcloud/datastore.dart' as datastore;
import 'database.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text("Datastore login"),
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
                );
              },
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => AddLoginScreen(),
            ),
          );
        },
        tooltip: 'addLogin',
        child: const Icon(Icons.add),
      ),
    );
  }
}

class AddLoginScreen extends StatefulWidget {
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
