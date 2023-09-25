import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_google_datastore/database.dart';
import 'package:googleapis/datastore/v1.dart' as dsv1;
import 'package:googleapis_auth/auth_io.dart';
import 'package:googleapis_auth/src/auth_http_utils.dart';
import 'package:http/http.dart' as http;
//import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart' as googleSignin;
import 'package:ini/ini.dart' as ini;
import 'package:path/path.dart' as path;
import 'package:xdg_directories/xdg_directories.dart' as xdg;
import 'package:path_provider/path_provider.dart' as ppath;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'kind.dart';
import 'main.dart';

final datastoreRequiredScopes = [
  "https://www.googleapis.com/auth/datastore",
];

class DatastoreMainPage extends StatefulWidget {
  final Project project;

  const DatastoreMainPage(
      {super.key, required this.project});

  @override
  State createState() {
    return _DatastoreMainPageState();
  }
}

class Namespace {
  final String name;

  Namespace(this.name);
  Namespace.fromKey(dsv1.Key key) :name = key.path?[0]?.name??"";
  Namespace.fromEntity(dsv1.Entity entity) : this.fromKey(entity.key!);
}

class Kind {
  final String name;
  final Namespace? namespace;

  Kind(this.name, this.namespace);
  Kind.fromKey(dsv1.Key key) : name = key.path?[0]?.name??"", namespace = null;
  Kind.fromEntity(dsv1.Entity entity) : this.fromKey(entity.key!);
  Kind.fromKeyWithNamespace(dsv1.Key key, this.namespace) : name = key.path?[0]?.name??"";
  Kind.fromEntityWithNamespace(dsv1.Entity entity, Namespace? namespace) : this.fromKeyWithNamespace(entity.key!, namespace);

  get key => "${namespace?.name ?? "default"}-$name";
}

class _DatastoreMainPageState extends State<DatastoreMainPage> {
  dsv1.DatastoreApi? dsApi;
  Future<List<Kind>>? listOfKinds;
  Future<List<Namespace>>? listOfNamespaces;
  GCloudCLICredentialDiscover gCloudCLICredentials = GCloudCLICredentialDiscover();
  @override
  void initState() {
    listOfKinds = retrieveKinds();
  }

  void closePressed() async {
    if (!Navigator.canPop(context)) {
      return;
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme
            .of(context)
            .colorScheme
            .inversePrimary,
        title: Text("Project: ${widget.project.projectId} @ ${widget.project.endpointUrl ?? "default"}"),
        actions: <Widget>[
          TextButton(onPressed: closePressed, child: const Text("Close")),
          // PopupMenuButton<String>(
          //   onSelected: popupItemSelected,
          //   itemBuilder: createPopupItems,
          // ),
        ],
      ),
      body: FutureBuilder(
        future: listOfKinds,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            if (snapshot.error.runtimeType == dsv1.DetailedApiRequestError) {
              return SelectableText('Authentication Error: ${snapshot.error}'); // TODO self provide details.
            }
            return SelectableText('Error: ${snapshot.error}');
          } else if (snapshot.hasData) {
            final listOfKinds = snapshot.data;
            return ListView.builder(
              itemCount: listOfKinds!.length,
              itemBuilder: (BuildContext context, int index) {
                return ListTile(
                  title: Text(listOfKinds[index].name),
                  subtitle: Text((listOfKinds[index].namespace?.name != null && listOfKinds[index].namespace!.name.isNotEmpty) ? "Namespace: ${listOfKinds[index].namespace?.name??""}" : "Default namespace"),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton(onPressed: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => KindContentsPage(project: widget.project, kind: listOfKinds[index], dsApi: dsApi!, key: Key(listOfKinds[index].key)),
                          ),
                        );
                        }, child: const Text("View")
                      ),
                    ],
                  ),
                );
              },
            );
          } else {
            return const CircularProgressIndicator();
          }
        },
      ),
    );
  }

  Future<List<Kind>> retrieveKinds() async {
    await loadApiClient();
    await loadNamespaces();
    if (dsApi == null) {
      throw Error.safeToString("Invalid DS API");
    }
    List<Kind> results = [];

    for (Namespace namespace in (await listOfNamespaces)??[]) {
      dsv1.RunQueryResponse response = await dsApi!.projects.runQuery(dsv1.RunQueryRequest(
        query: dsv1.Query(kind: [dsv1.KindExpression(name: "__kind__")]),
        partitionId: dsv1.PartitionId(namespaceId: namespace.name)
      ), widget.project.projectId);
      results.addAll(response?.batch?.entityResults?.map((e) => e.entity)?.whereType<dsv1.Entity>()?.map((e) => Kind.fromEntityWithNamespace(e, namespace)) ?? []);
    }

    return results;
  }

  Future<void> loadApiClient() async {
    var client = http.Client();
    switch (widget.project.authMode) {
      case gcloudCliAuthMode:
        final credsJson = await gCloudCLICredentials.getJsonCredentials(widget.project.googleCliProfile??"default");
        var creds = jsonDecode(credsJson);
        ClientId clientId = ClientId(
          creds["client_id"],
          creds["client_secret"],
        );
        AccessToken accessToken = AccessToken("", "", DateTime.now().subtract(const Duration(days: 1)).toUtc());
        AccessCredentials accessCredentials = AccessCredentials(accessToken, creds["refresh_token"], datastoreRequiredScopes);
        accessCredentials = await refreshCredentials(clientId, accessCredentials, client);
        client = AutoRefreshingClient(client, clientId, accessCredentials);
        break;
    }
    if (widget.project.endpointUrl != null) {
      dsApi ??= dsv1.DatastoreApi(client, rootUrl: widget.project.endpointUrl!);
    } else {
      dsApi ??= dsv1.DatastoreApi(client);
    }
  }

  Future<void> loadNamespaces() async {
    listOfNamespaces ??= retrieveNamespaces();
  }

  Future<List<Namespace>> retrieveNamespaces() async {
    await loadApiClient();
    dsv1.RunQueryResponse response = await dsApi!.projects.runQuery(dsv1.RunQueryRequest(
    query: dsv1.Query(kind: [dsv1.KindExpression(name: "__namespace__")]),
    ), widget.project.projectId);
    return response?.batch?.entityResults?.map((e) => e.entity)?.whereType<dsv1.Entity>()?.map((e) => Namespace.fromEntity(e))?.toList() ?? [];
  }
}

class GCloudCLICredentialDiscover {
  late final String configDir;
  late final String credentialsDBFile;
  late final String accessTokensDBFile;
  late final String profileConfigDir;
  late final List<String> profiles;
  final String defaultProfileName = "default";

  bool get hasDefault {
    return profiles.contains(defaultProfileName);
}

  GCloudCLICredentialDiscover() {
    loadConfigDir();
  }

  Future<void> loadConfigDir() async {
    if (Platform.isLinux) {
      configDir = path.join(xdg.configHome.path, "gcloud");
    } else {
      configDir = path.join((await ppath.getLibraryDirectory()).path, "gcloud");
    }
    credentialsDBFile = path.join(configDir, "credentials.db");
    accessTokensDBFile = path.join(configDir, "access_tokens.db");
    profileConfigDir = path.join(configDir, "configurations");
    await loadProfiles();
  }

  loadProfiles() async {
    final dir = Directory(profileConfigDir);
    profiles = await dir.list().where((FileSystemEntity fse) {
      return path.basename(fse.path).startsWith("config_");
    }).map((FileSystemEntity fse) => path.basename(fse.path).substring("config_".length)).toList();
    if (profiles.isEmpty) {
      profiles = ["default"];
    }
  }

  Future<String> getJsonCredentials(String forProfile) async {
    String fileContents = await File(path.join(profileConfigDir, "config_$forProfile")).readAsString();
    ini.Config inic = ini.Config.fromString(fileContents);

    dynamic account = inic.get("core", "account");
    // TODO expand to other platforms.
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    Database db = await openDatabase(credentialsDBFile, readOnly: true);
    try {
      List<Map<String,Object?>> results = await db.query("credentials", where: "account_id=?", whereArgs: [account], limit: 1, columns: ["value"]);
      if (results.length != 1) {
        throw Error.safeToString("Credentials for profile not found");
      }
      var result = results[0]["value"];
      if (result is! String) {
        throw Error.safeToString("Credentials in an unknown format");
      }
      return result;
    } finally {
      db.close();
    }
  }
}

