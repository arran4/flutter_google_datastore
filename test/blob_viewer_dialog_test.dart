import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_google_datastore/blob_viewer_dialog.dart';

void main() {
  group('BlobViewerDialog responsive behavior', () {
    final longData = List<int>.generate(2000, (i) => i % 256);
    final blobData = base64Encode(longData);

    Future<void> pumpDialog(WidgetTester tester) async {
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
    }

    testWidgets('Compact width layout owns scrolling without overflow', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await pumpDialog(tester);

      expect(tester.takeException(), isNull);

      final dialogFinder = find.byType(AlertDialog);
      final segmentedButtonFinder = find.byType(SegmentedButton<int>);

      expect(segmentedButtonFinder, findsOneWidget);
      // Select Hex to view long content and test scrolling
      await tester.tap(find.text('Hex'));
      await tester.pumpAndSettle();

      final hexScrollFinder = find.descendant(
        of: dialogFinder,
        matching: find.byType(SingleChildScrollView),
      );
      expect(hexScrollFinder, findsWidgets);
    });

    testWidgets('Expanded desktop width uses space without overflow', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await pumpDialog(tester);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Large text scale respects layout constraints', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2.0)),
            child: Builder(
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
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });
}
