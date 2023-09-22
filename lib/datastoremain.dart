import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_google_datastore/database.dart';

class DatastoreMainPage extends StatefulWidget {
  final int index;
  final UrlEntry urlEntry;


  const DatastoreMainPage({super.key, required this.index, required this.urlEntry});

  @override
  State createState() {
    return _DatastoreMainPageState();
  }
}


class _DatastoreMainPageState extends State<DatastoreMainPage> {

  void closePressed() async {
    if (!Navigator.canPop(context)) {
      return;
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:  AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text("Datastore: ${widget.urlEntry.url}"),
        actions: <Widget>[
          TextButton(onPressed: closePressed, child: const Text("Close")),
          // PopupMenuButton<String>(
          //   onSelected: popupItemSelected,
          //   itemBuilder: createPopupItems,
          // ),
        ],
      ),
    );
  }
}
