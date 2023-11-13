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
                        newProperties != null
                            ? Align(
                                alignment: Alignment.center,
                                child: ElevatedButton(
                                  onPressed: _saveChanges,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red, // Change to the color you prefer
                                    textStyle: const TextStyle(fontSize: 18), // Change to the size you prefer
                                  ),
                                  child: const Text(
                                    'Save Changes',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ),
                              )
                            : const SizedBox(),
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
                              if (result is MapEntry<String, dsv1.Value?>) {
                                setState(() {
                                  newProperties ??= widget.entityRow.entity.properties ?? {};
                                  if (result.value != null) {
                                    newProperties![result.key] = result.value!;
                                  } else {
                                    newProperties!.remove(result.key);
                                  }
                                });
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
    String type = getValueType(e.value) ?? "unknown";
    String displayValue = getValueDisplayValue(e.value);
    List<TableRow> more = getValueMore(e.value);
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
              if (result is MapEntry<String, dsv1.Value?>) {
                setState(() {
                  newProperties ??= widget.entityRow.entity.properties ?? {};
                  if (result.value != null) {
                    newProperties![result.key] = result.value!;
                  } else {
                    newProperties!.remove(result.key);
                  }
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
      return "entity:{${(e.entityValue!.properties ?? {}).entries.map(
            (e) => "${e.key}:${valuesToString(e.value)}",
          ).toList()}";
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

  String getValueDisplayValue(dsv1.Value value) {
    if (value.blobValue != null) {
      // TODO a way of looking at the content.
      return "Blob Length: ${value.blobValue?.length ?? "#ERROR"}";
    } else if (value.arrayValue != null) {
      return "[${value.arrayValue?.values?.map(valuesToString).join(" , ") ?? "#ERROR"}]";
    } else if (value.booleanValue != null) {
      return value.booleanValue?.toString() ?? "#ERROR";
    } else if (value.doubleValue != null) {
      return "${value.doubleValue ?? "#ERROR"}";
    } else if (value.entityValue != null) {
      // MORE
    } else if (value.geoPointValue != null) {
      return "lat: ${value.geoPointValue?.latitude ?? "null"} long: ${value.geoPointValue?.latitude ?? "null"}";
    } else if (value.integerValue != null) {
      return value.integerValue ?? "null";
    } else if (value.keyValue != null) {
      return "Key: ${keyToString(value.keyValue)}";
    } else if (value.meaning != null) {
      return "${value.meaning}";
    } else if (value.nullValue != null) {
      return value.nullValue ?? "null";
    } else if (value.stringValue != null) {
      return value.stringValue ?? "#ERROR";
    } else if (value.timestampValue != null) {
      return value.timestampValue ?? "#ERROR";
    } else {}
    return "";
  }

  List<TableRow> getValueMore(dsv1.Value value) {
    if (value.entityValue != null) {
      return (value.entityValue!.properties ?? {}).entries.expand(expandProperties).toList();
    }
    return [];
  }

  void _saveChanges() {
    // TODO
  }
}

String? getValueType(dsv1.Value? value) {
  if (value == null) {
    return null;
  }
  if (value.blobValue != null) {
    return "blob";
  } else if (value.arrayValue != null) {
    return "array";
  } else if (value.booleanValue != null) {
    return "boolean";
  } else if (value.doubleValue != null) {
    return "double";
  } else if (value.entityValue != null) {
    return "entity";
  } else if (value.geoPointValue != null) {
    return "geoPoint";
  } else if (value.integerValue != null) {
    return "integer";
  } else if (value.keyValue != null) {
    return "key";
  } else if (value.meaning != null) {
    return "me";
  } else if (value.nullValue != null) {
    return "null";
  } else if (value.stringValue != null) {
    return "string";
  } else if (value.timestampValue != null) {
    return "timestamp";
  } else {}
  return null;
}

class PropertyAddEditDeleteDialog extends StatefulWidget {
  final MapEntry<String, dsv1.Value>? propertyEntry;

  const PropertyAddEditDeleteDialog(this.propertyEntry, {Key? key}) : super(key: key);

  @override
  State<PropertyAddEditDeleteDialog> createState() => _PropertyAddEditDeleteDialogState();
}

class _PropertyAddEditDeleteDialogState extends State<PropertyAddEditDeleteDialog> {
  TextEditingController? _textEditingController;
  TextEditingController? _nameController;
  String _selectedType = "string";
  bool _indexData = false;

  @override
  void initState() {
    super.initState();
    _selectedType = getValueType(widget.propertyEntry?.value) ?? "string";
    _nameController = TextEditingController(text: widget.propertyEntry?.key ?? "unnamed");
    _indexData = !(widget.propertyEntry?.value.excludeFromIndexes ?? false);
    switch (_selectedType) {
      case "string":
        _textEditingController = TextEditingController(text: widget.propertyEntry?.value.stringValue ?? "");
        break;
      case "blob":
        // TODO
      case "array":
        // TODO
      case "boolean":
        // TODO
      case "double":
        // TODO
      case "entity":
        // TODO
      case "geoPoint":
        // TODO
      case "integer":
        // TODO
      case "key":
        // TODO
      case "me":
        // TODO
      case "null":
      case "timestamp":
        // TODO
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.propertyEntry == null ? 'Add Property' : 'Edit Property'),
      content: Column(
        children: [
          DropdownButton<String>(
            value: _selectedType,
            items: [
              "blob",
              "array",
              "boolean",
              "double",
              "entity",
              "geoPoint",
              "integer",
              "key",
              "me",
              "null",
              "string",
              "timestamp",
            ].map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
            onChanged: (String? value) {
              setState(() {
                _selectedType = value ?? "string";
              });
            },
          ),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Property Name'),
          ),
          Checkbox(
            value: _indexData,
            onChanged: (bool? v) {
              if (v == null) {
                return;
              }
              setState(() {
                _indexData = v;
              });
            },
          ),
          ...(editComponent(context))
        ],
      ),
      actions: [
        if (widget.propertyEntry != null)
          TextButton(
            onPressed: () {
              // Delete the property
              Navigator.of(context).pop(MapEntry<String, dsv1.Value?>(_nameController?.text ?? "", null));
            },
            child: const Text('Delete'),
          ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(MapEntry<String, dsv1.Value?>(_nameController?.text ?? "", createValue()));
          },
          child: const Text('Save'),
        ),
        TextButton(
          onPressed: () {
            // Close the dialog without saving
            Navigator.of(context).pop();
          },
          child: const Text('Close'),
        ),
      ],
    );
  }

  List<Widget> editComponent(BuildContext context) {
    switch (_selectedType) {
      case "string":
        return [
          TextField(
            controller: _textEditingController,
            decoration: const InputDecoration(labelText: 'Value'),
          ),
        ];
      case "blob":
      case "array":
      case "boolean":
      case "double":
      case "entity":
      case "geoPoint":
      case "integer":
      case "key":
      case "me":
      case "null":
        return const [Text("Null")];
      case "timestamp":
    }
    return [
      const Text("Not implemented"),
    ];
  }

  dsv1.Value? createValue() {
    dsv1.Value? value;
    switch (_selectedType) {
      case "string":
        value = dsv1.Value(
            stringValue: _textEditingController?.text ?? "",
        );
      case "blob":
        // return dsv1.Value()..blobValue = null;
      case "array":
        // return dsv1.Value()..arrayValue = null;
      case "boolean":
        // return dsv1.Value()..booleanValue = null;
      case "double":
      case "entity":
      case "geoPoint":
      case "integer":
      case "key":
      case "me":
      case "null":
        value = dsv1.Value(
          stringValue: "NULL_VALUE",
        );
      case "timestamp":
    }
    if (value != null) {
      value.excludeFromIndexes = !_indexData;
    }
    return value;
  }
}
