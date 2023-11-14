import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_google_datastore/kind.dart';
import 'package:googleapis/datastore/v1.dart' as dsv1;
import 'database.dart';
import 'datastoremain.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

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
                PropertyViewWidget(widget.entityRow, properties: widget.entityRow.entity.properties ?? {}, onSaveChanges: _saveChanges),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _saveChanges(Map<String, dsv1.Value> np) {
    // TODO
  }
}

class PropertyViewWidget extends StatefulWidget {
  final EntityRow entityRow;
  final Map<String, dsv1.Value> properties;
  final Function(Map<String, dsv1.Value> np)? onSaveChanges;
  final Function(Map<String, dsv1.Value> np)? onUpdate;

  const PropertyViewWidget(this.entityRow, {Key? key, required this.properties, this.onSaveChanges, this.onUpdate}) : super(key: key);

  @override
  State<PropertyViewWidget> createState() => _PropertyViewWidgetState();
}

class _PropertyViewWidgetState extends State<PropertyViewWidget> {
  Map<String, dsv1.Value>? newProperties;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Table(
      columnWidths: const {
        0: IntrinsicColumnWidth(),
        1: FlexColumnWidth(1),
        2: IntrinsicColumnWidth(),
      },
      children: [
        ...((newProperties ?? widget.properties).entries.expand(expandProperties).toList() ?? []),
        TableRow(
          children: [
            const SizedBox(),
            newProperties != null && widget.onSaveChanges != null
                ? Align(
                    alignment: Alignment.center,
                    child: ElevatedButton(
                      onPressed: () {
                        if (widget.onSaveChanges != null) {
                          widget.onSaveChanges!(newProperties ?? {});
                        }
                      },
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
                      return PropertyAddEditDeleteDialog(null, widget.entityRow);
                    },
                  );
                  if (result == null) {
                    return;
                  }
                  if (result is MapEntry<String, dsv1.Value?>) {
                    setState(() {
                      newProperties ??= {...(widget.properties ?? {})};
                      if (result.value != null) {
                        newProperties![result.key] = result.value!;
                      }
                    });
                    if (widget.onUpdate != null) {
                      widget.onUpdate!(newProperties ?? {});
                    }
                  }
                },
                child: const Icon(Icons.add),
              ),
            ),
          ],
        ),
      ],
    );
  }

  List<TableRow> expandProperties(MapEntry<String, dsv1.Value> prop) {
    String type = getValueType(prop.value) ?? "unknown";
    String displayValue = getValueDisplayValue(prop.value);
    List<TableRow> more = getValueMore(prop.value);
    return [
      TableRow(children: [
        SelectableText.rich(
          TextSpan(children: [
            TextSpan(text: "($type${prop.value.excludeFromIndexes == true ? "" : ", Indexed"}) ", style: const TextStyle(fontStyle: FontStyle.italic)),
            TextSpan(text: "${prop.key}: ", style: const TextStyle(fontWeight: FontWeight.bold)),
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
                  return PropertyAddEditDeleteDialog(prop, widget.entityRow);
                },
              );
              if (result == null) {
                return;
              }
              if (result is MapEntry<String, dsv1.Value?>) {
                setState(() {
                  newProperties ??= {...(widget.entityRow.entity.properties ?? {})};
                  if (result.value != null) {
                    newProperties![result.key] = result.value!;
                    if (result.key != prop.key) {
                      newProperties!.remove(prop.key);
                    }
                  } else {
                    newProperties!.remove(result.key);
                  }
                  if (widget.onUpdate != null) {
                    widget.onUpdate!(newProperties ?? {});
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

  List<TableRow> getValueMore(dsv1.Value value) {
    if (value.entityValue != null) {
      return (value.entityValue!.properties ?? {}).entries.expand(expandProperties).toList();
    }
    return [];
  }
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
  final EntityRow entityRow;
  final String type;
  final bool readonlyName;

  const PropertyAddEditDeleteDialog(this.propertyEntry, this.entityRow, {Key? key, this.type = "Property", this.readonlyName = false}) : super(key: key);

  @override
  State<PropertyAddEditDeleteDialog> createState() => _PropertyAddEditDeleteDialogState();
}

class _PropertyAddEditDeleteDialogState extends State<PropertyAddEditDeleteDialog> {
  TextEditingController? _textEditingController;
  TextEditingController? _numberEditingController;
  TextEditingController? _nameController;
  String _selectedType = "string";
  bool _indexData = false;
  bool? _booleanValue;
  String _selectedDateTime = DateTime.now().toUtc().toString();
  final TextEditingController _yearController = TextEditingController();
  final TextEditingController _monthController = TextEditingController();
  final TextEditingController _dayController = TextEditingController();
  final TextEditingController _hourController = TextEditingController();
  final TextEditingController _minuteController = TextEditingController();
  final TextEditingController _secondController = TextEditingController();
  final TextEditingController _millisecondController = TextEditingController();
  final TextEditingController _microsecondController = TextEditingController();
  final TextEditingController _timezoneController = TextEditingController();
  List<dsv1.PathElement>? _keyPath;
  List<dsv1.Value> _arrayValues = [];
  Map<String, dsv1.Value> newProperties = {};

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.propertyEntry?.key ?? "");
    _selectedType = getValueType(widget.propertyEntry?.value) ?? "string";
    _indexData = !(widget.propertyEntry?.value?.excludeFromIndexes ?? false);
    extractValue(widget.propertyEntry?.value);
  }

  Widget _buildDateTimeTextField(String label, TextEditingController controller) {
    return Padding(
      key: Key("DateTime:$label"),
      padding: const EdgeInsets.all(8.0),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(labelText: label),
        onChanged: (String value) {
          _updateDateTime();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var height = MediaQuery.of(context).size.height;
    var width = MediaQuery.of(context).size.width;
    return AlertDialog(
      scrollable: true,
      title: Text(widget.propertyEntry == null ? 'Add ${widget.type}' : 'Edit ${widget.type}'),
      content: SizedBox(
          height: height - 80,
          width: width - 80,
          child: Column(
            children: [
              TextField(
                controller: _nameController,
                decoration: InputDecoration(labelText: '${widget.type} Name'),
                readOnly: widget.readonlyName,
              ),
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
                    extractValue(widget.propertyEntry?.value);
                  });
                },
              ),
              ListTile(
                title: const Text('Indexed?'),
                trailing: Checkbox(
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
              ),
              ...(editComponent(context))
            ],
          )),
      actions: [
        if (widget.propertyEntry != null)
          TextButton(
            onPressed: () {
              // Delete the property
              Navigator.of(context).pop(MapEntry<String, dsv1.Value?>(_nameController?.text ?? widget.propertyEntry?.key ?? "", null));
            },
            child: const Text('Delete'),
          ),
        TextButton(
          onPressed: () {
            try {
              Navigator.of(context).pop(MapEntry<String, dsv1.Value?>(_nameController?.text ?? widget.propertyEntry?.key ?? "", createValue()));
            } catch (e) {
              _showErrorSnackBar("Error preparing to save changes: $e");
            }
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
            key: Key(_selectedType),
            controller: _textEditingController,
            decoration: const InputDecoration(labelText: 'Value'),
          ),
        ];
      case "blob":
        break; // TODO
      case "array":
        return [
          ..._arrayValues.map((dsv1.Value each) => ValueAddEditRow(
              value: each,
              onEdit: () async {
                dynamic result = await showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return PropertyAddEditDeleteDialog(
                      MapEntry<String, dsv1.Value>("Replace Element of ${widget.propertyEntry?.key}", each),
                      widget.entityRow,
                      readonlyName: true,
                      type: "Element",
                    );
                  },
                );
                if (result != null && result is MapEntry<String, dsv1.Value?>) {
                  setState(() {
                    if (result.value != null) {
                      _arrayValues = _arrayValues.map((e) => e == each ? result.value! : e).toList();
                    } else {
                      _arrayValues.remove(each);
                    }
                  });
                }
              },
              key: ValueKey(each))),
          TextButton(
              onPressed: () async {
                dynamic result = await showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return PropertyAddEditDeleteDialog(
                      MapEntry<String, dsv1.Value>("New Element to ${widget.propertyEntry?.key}", dsv1.Value()),
                      widget.entityRow,
                      readonlyName: true,
                      type: "Element",
                    );
                  },
                );
                if (result != null && result is MapEntry<String, dsv1.Value?> && result.value != null) {
                  setState(() {
                    _arrayValues.add(result.value!);
                  });
                }
              },
              child: const Text("Add Value")),
          TextButton(
              onPressed: () {
                setState(() {
                  _arrayValues.removeLast();
                });
              },
              child: const Text("Remove Value")),
        ];
        break;
      case "boolean":
        return [
          ListTile(
            key: Key(_selectedType),
            title: const Text('Boolean value'),
            trailing: Checkbox(
              value: _booleanValue ?? false,
              onChanged: (bool? v) {
                setState(() {
                  _booleanValue = v;
                });
              },
              // tristate: true,
            ),
          ),
        ];
      case "double":
        return [
          TextField(
            key: Key(_selectedType),
            controller: _numberEditingController,
            decoration: const InputDecoration(labelText: 'Double Value'),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
        ];
      case "entity":
        return [
          PropertyViewWidget(
            widget.entityRow,
            properties: newProperties ?? {},
            onUpdate: (Map<String, dsv1.Value> np) {
              setState(() {
                newProperties = {...(np ?? {})};
              });
            },
          ),
        ];
      case "geoPoint":
        break; // TODO
      case "integer":
        return [
          TextField(
            key: Key(_selectedType),
            controller: _numberEditingController,
            decoration: const InputDecoration(labelText: 'Integer Value'),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
        ];
      case "key":
        return [
          ...(_keyPath ?? []).reversed.map((dsv1.PathElement each) => KeyPatElementTextInputWidget(each: each, key: ValueKey(each))),
          TextButton(
              onPressed: () {
                setState(() {
                  _keyPath ??= [];
                  _keyPath!.insert(0, dsv1.PathElement(kind: "New Kind", name: "New Id"));
                });
              },
              child: const Text("Add parent")),
          TextButton(
              onPressed: () {
                setState(() {
                  _keyPath ??= [];
                  _keyPath!.removeAt(0);
                });
              },
              child: const Text("Remove parent")),
        ];
      case "me":
        break; // TODO
      case "null":
        return const [Text("Null")];
      case "timestamp":
        return [
          Text("Timestamp: $_selectedDateTime"),
          _buildDateTimeTextField("Year", _yearController),
          _buildDateTimeTextField("Month", _monthController),
          _buildDateTimeTextField("Day", _dayController),
          _buildDateTimeTextField("Hour", _hourController),
          _buildDateTimeTextField("Minute", _minuteController),
          _buildDateTimeTextField("Second", _secondController),
          _buildDateTimeTextField("Millisecond", _millisecondController),
          _buildDateTimeTextField("Microsecond", _microsecondController),
          _buildDateTimeTextField("Timezone", _timezoneController),
        ];
    }
    return [
      const Text("Not implemented"),
    ];
  }

  void _updateDateTime() {
    DateTime d = convertToDateTime();

    setState(() {
      _selectedDateTime = d.toString();
    });
  }

  DateTime convertToDateTime() {
    int year = int.parse(_yearController.text);
    int month = int.parse(_monthController.text);
    int day = int.parse(_dayController.text);
    int hour = int.parse(_hourController.text);
    int minute = int.parse(_minuteController.text);
    int second = int.parse(_secondController.text);
    int millisecond = int.parse(_millisecondController.text);
    int microsecond = int.parse(_microsecondController.text);
    String timezone = _timezoneController.text;

    // TODO a better library...
    tz.Location location = tz.UTC;
    if (timezone.isNotEmpty) {
      location = tz.getLocation(timezone);
    }

    DateTime d = tz.TZDateTime(location, year, month, day, hour, minute, second, millisecond, microsecond);

    return d;
  }

  dsv1.Value? createValue() {
    dsv1.Value? value;
    switch (_selectedType) {
      case "string":
        value = dsv1.Value(
          stringValue: _textEditingController?.text ?? "",
        );
        break;
      case "blob":
        throw UnimplementedError();
      case "array":
        value = dsv1.Value(
          arrayValue: dsv1.ArrayValue(
            values: _arrayValues,
          ),
        );
        break;
      case "boolean":
        value = dsv1.Value(
          booleanValue: _booleanValue,
        );
        break;
      case "double":
        value = dsv1.Value(
          doubleValue: double.tryParse(_numberEditingController?.text ?? ""),
        );
        break;
      case "entity":
        value = dsv1.Value(
          entityValue: dsv1.Entity(
            properties: newProperties,
          ),
        );
        break;
      case "geoPoint":
        throw UnimplementedError();
      case "integer":
        value = dsv1.Value(
          integerValue: int.parse(_numberEditingController?.text ?? "").toString(),
        );
        break;
      case "key":
        value = dsv1.Value(
          keyValue: dsv1.Key(
            partitionId: widget.entityRow.entity.key!.partitionId,
            path: _keyPath,
          ),
        );
        break;
      case "me":
        throw UnimplementedError();
      case "null":
        value = dsv1.Value(
          nullValue: "NULL_VALUE",
        );
        break;
      case "timestamp":
        value = dsv1.Value(
          timestampValue: convertToDateTime().toIso8601String(),
        );
        break;
    }
    if (value != null) {
      value.excludeFromIndexes = !_indexData;
    }
    return value;
  }

  void _showErrorSnackBar(String message) {
    final snackBar = SnackBar(
      content: Text(message),
      backgroundColor: Colors.red,
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  void extractValue(dsv1.Value? value) {
    switch (_selectedType) {
      case "string":
        _textEditingController = TextEditingController(text: value?.stringValue ?? "");
        break;
      case "blob":
        // TODO
        break;
      case "array":
        _arrayValues = value?.arrayValue?.values ?? [];
        break;
      case "boolean":
        _booleanValue = value?.booleanValue;
        break;
      case "double":
        _numberEditingController = TextEditingController(text: value?.doubleValue.toString() ?? "");
        break;
      case "entity":
        newProperties = {...(value?.entityValue?.properties ?? {})};
        break;
      case "geoPoint":
        // TODO
        break;
      case "integer":
        _numberEditingController = TextEditingController(text: value?.integerValue.toString() ?? "");
        break;
      case "key":
        if (value?.keyValue?.path != null) {
          _keyPath = [...(value?.keyValue?.path ?? [])];
        } else {
          _keyPath = null;
        }
        break;
      case "me":
        // TODO
        break;
      case "null":
        break;
      case "timestamp":
        _selectedDateTime = value?.timestampValue ?? "";
        refreshTimestampControllers();
        break;
    }
  }

  void refreshTimestampControllers() {
    DateTime? d = DateTime.tryParse(_selectedDateTime);
    if (d != null) {
      _yearController.text = d!.year.toString();
      _monthController.text = d!.month.toString();
      _dayController.text = d!.day.toString();
      _hourController.text = d!.hour.toString();
      _minuteController.text = d!.minute.toString();
      _secondController.text = d!.second.toString();
      _millisecondController.text = d!.millisecond.toString();
      _microsecondController.text = d!.microsecond.toString();
      _timezoneController.text = d!.timeZoneName;
    }
  }
}

// I am aware the UI / UX is horrible.. If it is an issue I will fix it later or accept PRs to fix it.
class KeyPatElementTextInputWidget extends StatefulWidget {
  final dsv1.PathElement each;

  const KeyPatElementTextInputWidget({required this.each, Key? key}) : super(key: key);

  @override
  _KeyPatElementTextInputWidgetState createState() => _KeyPatElementTextInputWidgetState();
}

class _KeyPatElementTextInputWidgetState extends State<KeyPatElementTextInputWidget> {
  late TextEditingController _kindController;
  late TextEditingController _idController;
  late TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _kindController = TextEditingController(text: widget.each.kind);
    _idController = TextEditingController(text: widget.each.id ?? '');
    _nameController = TextEditingController(text: widget.each.name ?? '');
  }

  @override
  Widget build(BuildContext context) {
    var type = widget.each.id != null ? "id" : "name";

    return Column(
      key: ObjectKey(widget.each),
      children: [
        Text("Kind: ${widget.each.kind}"),
        TextField(
          key: CompositeKey(key1: ObjectKey(widget.each), key2: const Key("Kind")),
          controller: _kindController,
          decoration: const InputDecoration(labelText: 'Kind'),
          onChanged: (String value) {
            setState(() {
              widget.each.kind = value;
            });
          },
        ),
        DropdownButton(
          key: CompositeKey(key1: ObjectKey(widget.each), key2: const Key("Type")),
          items: const [
            DropdownMenuItem(value: "id", child: Text("Id")),
            DropdownMenuItem(value: "name", child: Text("Name")),
          ],
          value: type,
          onChanged: (value) {
            setState(() {
              widget.each.id = value == "id" ? widget.each.id ?? "" : null;
              widget.each.name = value == "name" ? widget.each.name ?? "" : null;
            });
          },
        ),
        if (type == "id")
          TextField(
            key: CompositeKey(key1: ObjectKey(widget.each), key2: const Key("Id")),
            controller: _idController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Id'),
            onChanged: (String value) {
              setState(() {
                widget.each.id = value;
              });
            },
          ),
        if (type == "name")
          TextField(
            key: CompositeKey(key1: ObjectKey(widget.each), key2: const Key("Name")),
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Name'),
            onChanged: (String value) {
              setState(() {
                widget.each.name = value;
              });
            },
          ),
        const Text(
          "Parent",
          style: TextStyle(fontSize: 24),
        ),
      ],
    );
  }
}

class CompositeKey extends Key {
  final Key key1;
  final Key key2;

  const CompositeKey({required this.key1, required this.key2}) : super.empty();

  @override
  int get hashCode => key1.hashCode ^ key2.hashCode;

  @override
  bool operator ==(Object other) => identical(this, other) || other is CompositeKey && runtimeType == other.runtimeType && key1 == other.key1 && key2 == other.key2;
}

class ValueAddEditRow extends StatelessWidget {
  final dsv1.Value value;
  final Function()? onEdit;

  const ValueAddEditRow({Key? key, required this.value, this.onEdit}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: SelectableText.rich(
              TextSpan(children: [
                TextSpan(
                  text: "${value.excludeFromIndexes == true ? "" : "Indexed"} ",
                  style: const TextStyle(fontStyle: FontStyle.italic),
                ),
                TextSpan(text: getValueType(value) ?? "unknown"),
              ]),
              textAlign: TextAlign.end,
            ),
          ),
          Expanded(
            flex: 4,
            child: SelectableText(getValueDisplayValue(value), style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          Expanded(
            flex: 1,
            child: Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                icon: const Icon(Icons.edit),
                onPressed: onEdit,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
