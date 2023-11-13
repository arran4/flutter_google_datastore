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
  final int index;
  final EntityActions? actions;

  const ViewEntityPage(this.project, this.dsApi, this.kind, this.entityRow, this.index, this.actions, {super.key});

  @override
  State createState() => _ViewEntityPageState();
}

class _ViewEntityPageState extends State<ViewEntityPage> {
  late EntityRow entityRow;
  int _loading = 0;

  @override
  void initState() {
    entityRow = widget.entityRow;
  }

  void closePressed() async {
    if (!Navigator.canPop(context)) {
      return;
    }
    Navigator.pop(context);
  }

  List<PopupMenuEntry<String>> createRowPopupItems(BuildContext context) {
    return <PopupMenuEntry<String>>[
      const PopupMenuItem<String>(
        value: 'refresh',
        child: Text('Refresh'),
      ),
      const PopupMenuItem<String>(
        value: 'delete',
        child: Text('Delete'),
      ),
    ];
  }

  void popupRowItemSelected(String value) async {
    try {
      setState(() {
        _loading++;
      });
      switch (value) {
        case 'refresh':
          if (widget.entityRow.entity.key == null) {
            return;
          }
          if (widget.actions == null) {
            return;
          }
          dsv1.Entity? newEntity = await widget.actions!.refreshEntity(widget.entityRow.entity.key!);
          if (newEntity == null) {
            return;
          }
          EntityRow? er = await widget.actions!.replaceEntity(widget.index, newEntity);
          if (er != null) {
            setState(() {
              entityRow = er;
            });
          }
          break;
        case 'delete':
          if (widget.entityRow.entity.key == null) {
            return;
          }
          if (widget.actions == null) {
            return;
          }
          if (!context.mounted) break;
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text("Delete Confirmation"),
                content: const Text("Are you sure you want to delete this item?"),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // Close the dialog
                      if (context.mounted) {
                        if (this.context.mounted) {
                          Navigator.of(this.context).pop(); // Close the element window
                        }
                      }
                    },
                    child: const Text("Cancel"),
                  ),
                  TextButton(
                    onPressed: () async {
                      try {
                        _loading++;
                        await widget.actions!.deleteEntity(widget.index, widget.entityRow!.entity);
                      } catch (e) {
                        if (context.mounted) {
                          await ScaffoldMessenger.of(context)
                              .showSnackBar(
                                SnackBar(
                                  content: Text("Failed to delete the record. $e"),
                                  action: SnackBarAction(
                                    label: "OK",
                                    onPressed: () {
                                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                                    },
                                  ),
                                ),
                              )
                              .closed;
                          return;
                        }
                      } finally {
                        setState(() {
                          setState(() {
                            _loading--;
                          });
                        });
                        if (!context.mounted || !Navigator.canPop(context)) {
                          return;
                        }
                        if (context.mounted) {
                          Navigator.of(context).pop(); // Close the dialog
                        }
                      }
                      if (context.mounted) {
                        if (this.context.mounted) {
                          Navigator.of(this.context).pop(); // Close the element window
                        }
                      }
                    },
                    child: const Text("Delete"),
                  ),
                ],
              );
            },
          );
          break;
      }
    } finally {
      setState(() {
        _loading--;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text("${widget.entityRow.key} In ${widget.kind.key} In Project: ${widget.project.key}"),
        actions: <Widget>[
          PopupMenuButton<String>(
            onSelected: popupRowItemSelected,
            itemBuilder: createRowPopupItems,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: _loading > 0
            ? const Opacity(
                opacity: 0.4,
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              )
            : ViewEntity(widget.project, widget.dsApi, widget.kind, widget.entityRow, key: widget.key),
      ),
    );
  }
}

class ViewEntity extends StatefulWidget {
  final Project project;
  final dsv1.DatastoreApi dsApi;
  final Kind kind;
  final EntityRow entityRow;

  const ViewEntity(this.project, this.dsApi, this.kind, this.entityRow, {super.key});

  @override
  State createState() => _ViewEntityState();
}

class _ViewEntityState extends State<ViewEntity> {
  Map<String, dsv1.Value>? newProperties;

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
                  defaultColumnWidth: const IntrinsicColumnWidth(flex: 1),
                  children: [
                    TableRow(children: [
                      const TableCell(
                        child: Padding(
                          padding: EdgeInsets.all(4.0),
                          child: Text(
                            "Project Id",
                            textAlign: TextAlign.end,
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      TableCell(
                        child: Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: SelectableText(widget.project.projectId ?? ""),
                        ),
                      ),
                    ]),
                    TableRow(
                      children: [
                        const TableCell(
                          child: Padding(
                            padding: EdgeInsets.all(4.0),
                            child: Text(
                              "End Point",
                              textAlign: TextAlign.end,
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        TableCell(
                          child: Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: SelectableText(widget.project.endpointUrl ?? "Google Cloud"),
                          ),
                        ),
                      ],
                    ),
                    TableRow(
                      children: [
                        const TableCell(
                          child: Padding(
                            padding: EdgeInsets.all(4.0),
                            child: Text(
                              "Namespace",
                              textAlign: TextAlign.end,
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        TableCell(
                          child: Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: SelectableText(widget.kind.namespace?.name ?? "Default namespace"),
                          ),
                        ),
                      ],
                    ),
                    TableRow(
                      children: [
                        const TableCell(
                          child: Padding(
                            padding: EdgeInsets.all(4.0),
                            child: Text(
                              "Kind",
                              textAlign: TextAlign.end,
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        TableCell(
                          child: Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: SelectableText(widget.kind.name),
                          ),
                        ),
                      ],
                    ),
                    TableRow(
                      children: [
                        const TableCell(
                          child: Padding(
                            padding: EdgeInsets.all(4.0),
                            child: Text(
                              "Database Id",
                              textAlign: TextAlign.end,
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        TableCell(
                          child: Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: SelectableText(widget.entityRow.entity.key?.partitionId?.databaseId ?? ""),
                          ),
                        ),
                      ],
                    ),
                    TableRow(
                      children: [
                        const TableCell(
                          child: Padding(
                            padding: EdgeInsets.all(4.0),
                            child: Text(
                              "Key Path",
                              textAlign: TextAlign.end,
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        TableCell(
                          child: Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: SelectableText(widget.entityRow.key),
                          ),
                        ),
                      ],
                    ),
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
                  columnWidths: const {
                    0: IntrinsicColumnWidth(),
                    1: FlexColumnWidth(1),
                    2: IntrinsicColumnWidth(),
                  },
                  children: [
                    ...((newProperties ?? widget.entityRow.entity.properties)?.entries.expand(expandProperties).toList() ?? []),
                    TableRow(
                      children: [
                        const SizedBox(),
                        const SizedBox(),
                        Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton(
                            onPressed: () async {
                              dynamic result = await showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return const PropertyAddEditDeleteDialog(null);
                                },
                              );
                              if (result == null) {
                                return;
                              }
                              if (result is MapEntry<String, dsv1.Value>) {
                                newProperties ??= widget.entityRow.entity.properties ?? {};
                                newProperties![result.key] = result.value;
                              }
                            },
                            child: const Icon(Icons.add),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<TableRow> expandProperties(MapEntry<String, dsv1.Value> e) {
    String type = "unknown";
    String displayValue = "";
    List<TableRow> more = [];
    if (e.value.blobValue != null) {
      type = "blob";
      // TODO a way of looking at the content.
      displayValue = "Blob Length: ${e.value.blobValue?.length ?? "#ERROR"}";
    } else if (e.value.arrayValue != null) {
      type = "array";
      // TODO Recursive....
      displayValue = "[${e.value.arrayValue?.values?.map(valuesToString).join(" , ") ?? "#ERROR"}]";
    } else if (e.value.booleanValue != null) {
      type = "boolean";
      displayValue = e.value.booleanValue?.toString() ?? "#ERROR";
    } else if (e.value.doubleValue != null) {
      type = "double";
      displayValue = "${e.value.doubleValue ?? "#ERROR"}";
    } else if (e.value.entityValue != null) {
      type = "entity";
      more = (e.value.entityValue!.properties ?? {}).entries.expand(expandProperties).toList();
    } else if (e.value.geoPointValue != null) {
      type = "geoPoint";
      displayValue = "lat: ${e.value.geoPointValue?.latitude ?? "null"} long: ${e.value.geoPointValue?.latitude ?? "null"}";
    } else if (e.value.integerValue != null) {
      type = "integer";
      displayValue = e.value.integerValue ?? "null";
    } else if (e.value.keyValue != null) {
      type = "key";
      displayValue = "Key: ${keyToString(e.value.keyValue)}";
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
    return [
      TableRow(children: [
        SelectableText.rich(
          TextSpan(children: [
            TextSpan(text: "($type${e.value.excludeFromIndexes == true ? "" : ", Indexed"}) ", style: const TextStyle(fontStyle: FontStyle.italic)),
            TextSpan(text: "${e.key}: ", style: const TextStyle(fontWeight: FontWeight.bold)),
          ]),
          textAlign: TextAlign.end,
        ),
        SelectableText(displayValue),
        Align(
          alignment: Alignment.centerRight,
          child: IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              dynamic result = await showDialog(
                context: context,
                builder: (BuildContext context) {
                  return PropertyAddEditDeleteDialog(e);
                },
              );
              if (result == null) {
                return;
              }
              if (result is MapEntry<String, dsv1.Value>) {
                setState(() {
                  newProperties ??= widget.entityRow.entity.properties ?? {};
                  newProperties![result.key] = result.value;
                });
              }
            },
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ),
      ]),
      ...more,
    ];
  }

  String valuesToString(dsv1.Value e) {
    if (e.blobValue != null) {
      return "Blob Length: ${e.blobValue?.length ?? "#ERROR"}";
    } else if (e.arrayValue != null) {
      return "array:[${e.arrayValue?.values?.join(" , ") ?? "#ERROR"}]";
    } else if (e.booleanValue != null) {
      return "boolean:${e.booleanValue?.toString() ?? "#ERROR"}";
    } else if (e.doubleValue != null) {
      return "double:${e.doubleValue ?? "#ERROR"}";
    } else if (e.entityValue != null) {
      return "entity:{${(e.entityValue!.properties ?? {}).entries.map((e) => "${e.key}:${valuesToString(e.value)}",).toList()}";
    } else if (e.geoPointValue != null) {
      return "geoPoint:lat: ${e.geoPointValue?.latitude ?? "null"} long: ${e.geoPointValue?.latitude ?? "null"}";
    } else if (e.integerValue != null) {
      return "integer:${e.integerValue ?? "null"}";
    } else if (e.keyValue != null) {
      return "key:Key: ${keyToString(e.keyValue)}";
    } else if (e.meaning != null) {
      return "me:${e.meaning}";
    } else if (e.nullValue != null) {
      return "null:${e.nullValue ?? "null"}";
    } else if (e.stringValue != null) {
      return "string:${e.stringValue ?? "#ERROR"}";
    } else if (e.timestampValue != null) {
      return "timestamp:${e.timestampValue ?? "#ERROR"}";
    } else {
      return "unknown:#ERROR";
    }
  }
}

class PropertyAddEditDeleteDialog extends StatefulWidget {
  const PropertyAddEditDeleteDialog(MapEntry<String, dsv1.Value>? e, {super.key});

  @override
  State<PropertyAddEditDeleteDialog> createState() => _PropertyAddEditDeleteDialogState();
}

class _PropertyAddEditDeleteDialogState extends State<PropertyAddEditDeleteDialog> {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Custom Dialog'),
      content: Column(
        children: [
          Text('This is a custom dialog.'),
          SizedBox(height: 10),
          // Add any custom content you need
          // For example, you can add text fields, buttons, images, etc.
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            // Close the dialog
            Navigator.of(context).pop();
          },
          child: Text('Close'),
        ),
        // Add more buttons if needed
      ],
    );
  }
}
