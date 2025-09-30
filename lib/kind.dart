import 'dart:async';

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

abstract class EntityActions {
   Future<dsv1.Entity?> refreshEntity(dsv1.Key key);
   Future<EntityRow?> replaceEntity(int index, dsv1.Entity newEntity);
   Future<bool> deleteEntity(int index, dsv1.Entity newEntity);
   Future<bool> updateEntity(dsv1.Key key, Map<String, dsv1.Value> props);
}


class _KindContentsPageState extends State<KindContentsPage> implements EntityActions {
  int limit = 100;
  String? startCursor;
  Set<String> expanded = {};
  late final PagingController<int, EntityRow> _pagingController;

  void closePressed() async {
    if (!Navigator.canPop(context)) {
      return;
    }
    Navigator.pop(context);
  }

  @override
  void initState() {
    _pagingController = PagingController<int, EntityRow>(
      getNextPageKey: (state) => (state.keys?.last ?? -1) + 1,
      fetchPage: _fetchPage,
    );
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

  Future<void> popupRowItemSelected(
      EntityRow entityRow, int index, String value) async {
    switch (value) {
      case 'refresh':
        if (entityRow.entity.key == null) {
          return;
        }
        dsv1.Entity? newEntity = await refreshEntity(entityRow.entity.key!);
        if (newEntity == null) {
          return;
        }
        await replaceEntity(index, newEntity);
        break;
    }
  }

  List<PopupMenuEntry<String>> createRowPopupItems(BuildContext context) {
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
      body: PagingListener<int, EntityRow>(
        controller: _pagingController,
        builder: (context, state, fetchNextPage) => PagedListView<int, EntityRow>(
          state: state,
          fetchNextPage: fetchNextPage,
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
                                        ViewEntityPage(widget.project, widget.dsApi, widget.kind, item, index, this)));
                              },
                              child: const Text("View")
                          ),
                          PopupMenuButton<String>(
                            onSelected: (String value) {
                              unawaited(popupRowItemSelected(item, index, value));
                            },
                            itemBuilder: createRowPopupItems,
                          ),
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

  Future<List<EntityRow>> _fetchPage(int pageKey) async {
    try {
      final newItems = await retrieveRows();
      if (newItems.length < limit) {
        _pagingController.value =
            _pagingController.value.copyWith(hasNextPage: false);
      }
      return newItems;
    } catch (error) {
      _pagingController.value =
          _pagingController.value.copyWith(error: error);
      return [];
    }
  }

  Future<dsv1.Entity?> refreshEntity(dsv1.Key key) async {
    dsv1.LookupResponse lookupResponse = await widget.dsApi!.projects.lookup(dsv1.LookupRequest(databaseId: widget.project.databaseId, keys: [key]), widget.project.projectId);
    if (lookupResponse.found?.length != 1) {
      throw Error.safeToString("no results found");
    }
    return lookupResponse.found![0].entity;
  }

  Future<bool> updateEntity(dsv1.Key key, Map<String, dsv1.Value> props) async {
    var r = await widget.dsApi!.projects.commit(dsv1.CommitRequest(databaseId: widget.project.databaseId, mode: "NON_TRANSACTIONAL", mutations: [dsv1.Mutation(update: dsv1.Entity(key: key, properties: props))]), widget.project.projectId);
    return r.mutationResults?[0]?.key != null;
  }

  Future<bool> deleteEntity(int index, dsv1.Entity newEntity) async {
    await widget.dsApi!.projects.commit(dsv1.CommitRequest(databaseId: widget.project.databaseId, mode: "NON_TRANSACTIONAL", mutations: [dsv1.Mutation(delete: newEntity.key)]), widget.project.projectId);
    return await removeEntity(index, newEntity);
  }

  Future<EntityRow?> replaceEntity(int index, dsv1.Entity newEntity) async {
    if (index >= (_pagingController.value.items?.length ?? 0)) {
      return null;
    }
    EntityRow er = _pagingController.value.items![index];
    Completer<EntityRow?> completer = Completer();
      setState(() {
        if (index < (_pagingController.value.items?.length ?? 0) &&
            _pagingController.value.items![index].key ==
                keyToString(newEntity.key)) {
          er.entity = newEntity!;
          _pagingController.mapItems(
              (item) => item.key == er.key ? er : item);
        }
        completer.complete(er);
      });
    return completer.future;
  }

  Future<bool> removeEntity(int index, dsv1.Entity newEntity) async {
    if (index >= (_pagingController.value.items?.length ?? 0)) {
      return false;
    }
    EntityRow er = _pagingController.value.items![index];
    Completer<bool> completer = Completer();
      setState(() {
        bool found = false;
        if (index < (_pagingController.value.items?.length ?? 0) &&
            _pagingController.value.items![index].key ==
                keyToString(newEntity.key)) {
          found = true;
          er.entity = newEntity!;
          _pagingController.value = _pagingController.value
              .filterItems((item) => item.key != er.key);
        }
        completer.complete(found);
      });
    return completer.future;
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
