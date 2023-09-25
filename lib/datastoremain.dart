import 'package:flutter/material.dart';
import 'package:flutter_google_datastore/database.dart';
import 'package:googleapis/datastore/v1.dart' as dsv1;
import 'package:http/http.dart' as http;

class DatastoreMainPage extends StatefulWidget {
  final int index;
  final Project project;


  const DatastoreMainPage(
      {super.key, required this.index, required this.project});

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
}

class _DatastoreMainPageState extends State<DatastoreMainPage> {
  dsv1.DatastoreApi? dsApi;
  Future<List<Kind>>? listOfKinds;
  Future<List<Namespace>>? listOfNamespaces;

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
                      TextButton(onPressed: () {

                      }, child: const Text("View")),
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
    if (widget.project.endpointUrl != null) {
      dsApi ??= dsv1.DatastoreApi(http.Client(), rootUrl: widget.project.endpointUrl!);
    } else {
      dsApi ??= dsv1.DatastoreApi(http.Client());
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
