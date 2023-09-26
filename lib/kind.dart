import 'package:flutter/material.dart';
import 'package:flutter_google_datastore/database.dart';
import 'package:flutter_google_datastore/datastoremain.dart';
import 'package:flutter_google_datastore/entity.dart';
import 'package:googleapis/datastore/v1.dart' as dsv1;
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

final datastoreRequiredScopes = [
  "https://www.googleapis.com/auth/datastore",
];

class KindContentsPage extends StatefulWidget {
  final Project project;
  final dsv1.DatastoreApi dsApi;
  final Kind kind;

  const KindContentsPage(
      {super.key,
      required this.project,
      required this.dsApi,
      required this.kind});

  @override
  State createState() {
    return _KindContentsPageState();
  }
}

class _KindContentsPageState extends State<KindContentsPage> {
  int limit = 100;
  String? startCursor;
  Set<String> expanded = {};
  final PagingController<int, EntityRow> _pagingController =
      PagingController(firstPageKey: 0);

  void closePressed() async {
    if (!Navigator.canPop(context)) {
      return;
    }
    Navigator.pop(context);
  }

  @override
  void initState() {
    _pagingController.addPageRequestListener((pageKey) {
      _fetchPage(pageKey);
    });
    super.initState();
  }

  void popupItemSelected(String value) {
    switch (value) {
      case 'refresh':
        setState(() {
          startCursor = null;
        });
        _pagingController.refresh();
        break;
    }
  }

  List<PopupMenuEntry<String>> createPopupItems(BuildContext context) {
    return <PopupMenuEntry<String>>[
      const PopupMenuItem<String>(
        value: 'refresh',
        child: Text('Refresh'),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text("${widget.kind.key} In Project: ${widget.project.key}"),
        actions: <Widget>[
          PopupMenuButton<String>(
            onSelected: popupItemSelected,
            itemBuilder: createPopupItems,
          ),
        ],
      ),
      body: PagedListView<int, EntityRow>(
        pagingController: _pagingController,
        builderDelegate: PagedChildBuilderDelegate<EntityRow>(
            itemBuilder: (BuildContext context, EntityRow item, int index) =>
                Column(
                  children: [
                    ListTile(
                      title: Text(item.key),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextButton(
                              onPressed: () {
                                setState(() {
                                  if (expanded.contains(item.key)) {
                                    expanded.remove(item.key);
                                  } else {
                                    expanded.add(item.key);
                                  }
                                });
                              },
                              child: expanded.contains(item.key)
                                  ? const Text("Collapse")
                                  : const Text("Expand")),
                          TextButton(
                              onPressed: () {
                                Navigator.of(context).push(MaterialPageRoute(
                                    builder: (BuildContext context) =>
                                        ViewEntityPage(widget.project, widget.dsApi,
                                            widget.kind, item)));
                              },
                              child: const Text("View")),
                        ],
                      ),
                    ),
                    ...(expanded.contains(item.key) ? [ViewEntity(
                        widget.project, widget.dsApi, widget.kind, item,
                        key: widget.key)] : [])
                  ],
                )
        ),
      ),
    );
  }

  Future<List<EntityRow>> retrieveRows() async {
    List<EntityRow> results = [];

    dsv1.RunQueryResponse response = await widget.dsApi!.projects.runQuery(
        dsv1.RunQueryRequest(
          query: dsv1.Query(
              kind: [dsv1.KindExpression(name: widget.kind.name)],
              startCursor: startCursor,
              limit: limit,
            ),
          partitionId: widget.kind.namespace != null
              ? dsv1.PartitionId(namespaceId: widget.kind.namespace!.name)
              : null,
        ),
        widget.project.projectId);
    startCursor = response?.batch?.endCursor;
    results.addAll(response?.batch?.entityResults
            ?.map((e) => e.entity)
            ?.whereType<dsv1.Entity>()
            ?.map((e) => EntityRow(entity: e)) ??
        []);

    return results;
  }

  void _fetchPage(int pageKey) async {
    try {
      final newItems = await retrieveRows();
      final isLastPage = newItems.length < limit;
      if (isLastPage) {
        _pagingController.appendLastPage(newItems);
      } else {
        final nextPageKey = pageKey + newItems.length;
        _pagingController.appendPage(newItems, nextPageKey);
      }
    } catch (error) {
      _pagingController.error = error;
    }
  }
}

String keyToString(dsv1.Key? key) {
  return key?.path
          ?.map((e) => "${e.kind ?? ""} ( ${e.name ?? e.id ?? ""} )")
          .join(" => ") ??
      "#KEY ERROR";
}

class EntityRow {
  dsv1.Entity entity;

  EntityRow({required this.entity});

  String get key => keyToString(entity.key);
}
