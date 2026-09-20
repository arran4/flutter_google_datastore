import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_google_datastore/main.dart';

void main() {
  testWidgets('AddEditProjectScreenState disposes controllers properly', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(home: AddEditProjectScreen()));

    // The screen should render correctly
    expect(find.byType(AddEditProjectScreen), findsOneWidget);

    final state = tester.state<AddEditProjectScreenState>(find.byType(AddEditProjectScreen));

    final endpointUrlController = state.endpointUrlController;
    final projectIdController = state.projectIdController;
    final databaseIdController = state.databaseIdController;

    // Pump another widget to unmount AddEditProjectScreen
    await tester.pumpWidget(Container());

    expect(() => endpointUrlController.addListener(() {}), throwsFlutterError);
    expect(() => projectIdController.addListener(() {}), throwsFlutterError);
    expect(() => databaseIdController.addListener(() {}), throwsFlutterError);
  });
}
