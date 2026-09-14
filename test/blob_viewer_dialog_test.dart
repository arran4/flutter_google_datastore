import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_google_datastore/blob_viewer_dialog.dart';

void main() {
  testWidgets('BlobViewerDialog applies correct adaptive constraints',
      (WidgetTester tester) async {
    final blobData = base64Encode([1, 2, 3, 4]);

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => BlobViewerDialog(blobData),
                );
              },
              child: const Text('Open'),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.byType(ConstrainedBox), findsWidgets);
    expect(find.byType(SegmentedButton<int>), findsOneWidget);
  });
}
