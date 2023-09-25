import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_google_datastore/kind.dart';
import 'package:googleapis/datastore/v1.dart' as dsv1;
import 'database.dart';
import 'datastoremain.dart';

class ViewEntityPage extends StatefulWidget {
  final Project project;
  final dsv1.DatastoreApi dsApi;
  final Kind kind;
  final EntityRow entityRow;

  const ViewEntityPage(this.project, this.dsApi, this.kind, this.entityRow,
      {super.key});

  @override
  State createState() => _ViewEntityPageState();
}

class _ViewEntityPageState extends State<ViewEntityPage> {
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
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(
            "${widget.entityRow.key} In ${widget.kind.key} In Project: ${widget.project.key}"),
        actions: <Widget>[
          TextButton(onPressed: closePressed, child: const Text("Close")),
          // PopupMenuButton<String>(
          //   onSelected: popupItemSelected,
          //   itemBuilder: createPopupItems,
          // ),
        ],
      ),
      body: SingleChildScrollView(
        child: ViewEntity(
            widget.project, widget.dsApi, widget.kind, widget.entityRow,
            key: widget.key),
      ),
    );
  }
}

class ViewEntity extends StatefulWidget {
  final Project project;
  final dsv1.DatastoreApi dsApi;
  final Kind kind;
  final EntityRow entityRow;

  const ViewEntity(this.project, this.dsApi, this.kind, this.entityRow,
      {super.key});

  @override
  State createState() => _ViewEntityState();
}

class _ViewEntityState extends State<ViewEntity> {
  void closePressed() async {
    if (!Navigator.canPop(context)) {
      return;
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Card(
          margin: const EdgeInsets.all(16.0),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Text("Details", style: Theme.of(context).textTheme.headlineSmall),
                Table(
                  children: [
                    TableRow(children: [
                      const Text("Project Id"),
                      SelectableText(widget.project.projectId ?? ""),
                    ]),
                    TableRow(children: [
                      const Text("End Point"),
                      SelectableText(
                          widget.project.endpointUrl ?? "Google Cloud"),
                    ]),
                    TableRow(children: [
                      const Text("Namespace"),
                      SelectableText(
                          widget.kind.namespace?.name ?? "Default namespace"),
                    ]),
                    TableRow(children: [
                      const Text("Kind"),
                      SelectableText(widget.kind.name),
                    ]),
                    TableRow(children: [
                      const Text("Database Id"),
                      SelectableText(widget.entityRow.entity.key?.partitionId?.databaseId ?? ""),
                    ]),
                    TableRow(children: [
                      const Text("Key Path"),
                      SelectableText(widget.entityRow.key),
                    ]),
                  ],
                )
              ],
            ),
          ),
        ),
        Card(
          margin: const EdgeInsets.all(16.0),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Text("Properties", style: Theme.of(context).textTheme.headlineSmall),
                Table(
                  children:
                      widget.entityRow.entity.properties?.entries.map((e) {
                            String type = "unknown";
                            String displayValue = "";
                            if (e.value.arrayValue != null) {
                              type = "array";
                              // TODO Recursive....
                              displayValue =
                                  "[${e.value.arrayValue?.values?.join(" , ") ?? "#ERROR"}]";
                            } else if (e.value.blobValue != null) {
                              type = "blob";
                              // TODO a way of looking at the content.
                              displayValue =
                                  "Blob Length: ${e.value.blobValue?.length ?? "#ERROR"}";
                            } else if (e.value.booleanValue != null) {
                              type = "boolean";
                              displayValue =
                                  e.value.booleanValue?.toString() ?? "#ERROR";
                            } else if (e.value.doubleValue != null) {
                              type = "double";
                              displayValue =
                                  "${e.value.doubleValue ?? "#ERROR"}";
                            } else if (e.value.entityValue != null) {
                              type = "entity";
                              // TODO recursive
                              displayValue = "#ERROR nested entity type";
                            } else if (e.value.geoPointValue != null) {
                              type = "geoPoint";
                              displayValue =
                                  "lat: ${e.value.geoPointValue?.latitude ?? "null"} long: ${e.value.geoPointValue?.latitude ?? "null"}";
                            } else if (e.value.integerValue != null) {
                              type = "integer";
                              displayValue = e.value.integerValue ?? "null";
                            } else if (e.value.keyValue != null) {
                              type = "key";
                              displayValue =
                                  "Key: ${keyToString(e.value.keyValue)}";
                            } else if (e.value.meaning != null) {
                              type = "me";
                              displayValue = "${e.value.meaning}";
                            } else if (e.value.nullValue != null) {
                              type = "null";
                              displayValue = e.value.nullValue ?? "null";
                            } else if (e.value.stringValue != null) {
                              type = "string";
                              displayValue = e.value.stringValue ?? "#ERROR";
                            } else if (e.value.timestampValue != null) {
                              type = "timestamp";
                              displayValue = e.value.timestampValue ?? "#ERROR";
                            } else {}
                            return TableRow(children: [
                              SelectableText(e.key),
                              SelectableText(
                                  "$type ${e.value.excludeFromIndexes == true ? "" : "Indexed"}"),
                              SelectableText(displayValue),
                            ]);
                          }).toList() ??
                          [],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
