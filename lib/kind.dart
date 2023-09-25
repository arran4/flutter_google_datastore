import 'package:flutter/material.dart';
import 'package:flutter_google_datastore/database.dart';
import 'package:flutter_google_datastore/datastoremain.dart';
import 'package:googleapis/datastore/v1.dart' as dsv1;

final datastoreRequiredScopes = [
  "https://www.googleapis.com/auth/datastore",
];

class KindContentsPage extends StatefulWidget {
  final Project project;
  final dsv1.DatastoreApi dsApi;
  final Kind kind;

  const KindContentsPage(
      {super.key, required this.project, required this.dsApi, required this.kind});

  @override
  State createState() {
    return _KindContentsPageState();
  }
}

class _KindContentsPageState extends State<KindContentsPage> {
  int offset = 0;
  int limit = 100;
  int pages = -1;
  late Future<List<EntityRow>> rows;

  @override
  void initState() {
    rows = retrieveRows();
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
        title: Text("${widget.kind.key} In Project: ${widget.project.projectId} @ ${widget.project.endpointUrl ?? "default"}"),
        actions: <Widget>[
          TextButton(onPressed: closePressed, child: const Text("Close")),
          // PopupMenuButton<String>(
          //   onSelected: popupItemSelected,
          //   itemBuilder: createPopupItems,
          // ),
        ],
      ),
      body: FutureBuilder(
        future: rows,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            if (snapshot.error.runtimeType == dsv1.DetailedApiRequestError) {
              return SelectableText('Authentication Error: ${snapshot.error}'); // TODO self provide details.
            }
            return SelectableText('Error: ${snapshot.error}');
          } else if (snapshot.hasData) {
            final rows = snapshot.data;
            return ListView.builder(
              itemCount: rows!.length,
              itemBuilder: (BuildContext context, int index) {
                return ListTile(
                  title: Text(rows[index].key),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton(onPressed: () {
                        // TODO
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

  Future<List<EntityRow>> retrieveRows() async {
    List<EntityRow> results = [];

    dsv1.RunQueryResponse response = await widget.dsApi!.projects.runQuery(dsv1.RunQueryRequest(
      query: dsv1.Query(kind: [dsv1.KindExpression(name: widget.kind.name)], limit: limit, offset: offset),
      partitionId: widget.kind.namespace != null ? dsv1.PartitionId(namespaceId: widget.kind.namespace!.name) : null,
    ), widget.project.projectId);
    results.addAll(response?.batch?.entityResults?.map((e) => e.entity)?.whereType<dsv1.Entity>()?.map((e) => EntityRow(entity: e)) ?? []);

    return results;
  }
}

class EntityRow {
  dsv1.Entity entity;
  EntityRow({required this.entity});

  String get key => entity.key?.path?.map((e) => "${e.kind ?? ""} ( ${e.name ?? e.id ?? ""} )").join(" => ") ?? "#KEY ERROR";
}