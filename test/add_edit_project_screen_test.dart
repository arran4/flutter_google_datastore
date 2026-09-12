import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_google_datastore/database.dart';
import 'package:flutter_google_datastore/datastoremain.dart';
import 'package:flutter_google_datastore/main.dart';
import 'package:flutter_google_datastore/responsive_layout.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class FakeGCloudCLICredentialDiscover implements GCloudCLICredentialDiscover {
  @override
  final List<String> profiles;

  FakeGCloudCLICredentialDiscover([this.profiles = const ['default']]);

  @override
  String get configDir => '';
  @override
  set configDir(String _) {}

  @override
  String get credentialsDBFile => '';
  @override
  set credentialsDBFile(String _) {}

  @override
  String get accessTokensDBFile => '';
  @override
  set accessTokensDBFile(String _) {}

  @override
  String get profileConfigDir => '';
  @override
  set profileConfigDir(String _) {}

  @override
  set profiles(List<String> _) {}

  @override
  String get defaultProfileName => 'default';

  @override
  bool get hasDefault => profiles.contains(defaultProfileName);

  @override
  String? get overrideConfigDir => null;

  @override
  Future<void> get initFuture => Future.value();
  @override
  set initFuture(Future<void> _) {}

  @override
  Future<void> loadConfigDir() async {}

  @override
  Future<void> loadProfiles() async {}

  @override
  Future<String> getJsonCredentials(String forProfile) async => '';
}

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  Widget createTestWidget({
    Project? project,
    Key? key,
    List<String>? profileSource,
    GCloudCLICredentialDiscover? credentialDiscoverer,
  }) {
    return MaterialApp(
      home: AddEditProjectScreen(
        key: key ?? ValueKey(project?.id ?? 'new'),
        project: project,
        profileSource:
            profileSource ??
            (credentialDiscoverer == null ? const ['default'] : null),
        credentialDiscoverer: credentialDiscoverer,
      ),
    );
  }

  group('AddEditProjectScreen responsive layout and semantic hierarchy', () {
    testWidgets(
      'renders semantic sections and compact layout on narrow screen (mobile)',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Verify semantic section headers are visible
        expect(find.text('Project identity'), findsOneWidget);
        expect(find.text('Connection'), findsOneWidget);
        expect(find.text('Authentication'), findsOneWidget);
        expect(find.text('Actions'), findsOneWidget);

        // Verify form fields are present
        expect(find.byType(Form), findsOneWidget);
        final projIdFinder = find.widgetWithText(TextFormField, 'Project ID');
        final dbIdFinder = find.widgetWithText(
          TextFormField,
          'Database ID (blank for default)',
        );
        final endpointFinder = find.widgetWithText(
          TextFormField,
          'Endpoint URL (blank for default)',
        );
        final authModeFinder = find.widgetWithText(
          DropdownButtonFormField<String>,
          'Authentication mode',
        );
        final buttonFinder = find.widgetWithText(ElevatedButton, 'Add Project');

        expect(projIdFinder, findsOneWidget);
        expect(dbIdFinder, findsOneWidget);
        expect(endpointFinder, findsOneWidget);
        expect(authModeFinder, findsOneWidget);
        expect(find.text('Add Project'), findsNWidgets(2)); // AppBar and button

        // Compact layout verification: short fields stack vertically
        final projIdBottom = tester.getBottomLeft(projIdFinder).dy;
        final dbIdTop = tester.getTopLeft(dbIdFinder).dy;
        expect(dbIdTop, greaterThan(projIdBottom));

        // Primary action button is full-width on compact screens
        final buttonWidth = tester.getSize(buttonFinder).width;
        final formWidth = tester.getSize(find.byType(Form)).width;
        expect(buttonWidth, closeTo(formWidth, 2.0));

        // Validation test on empty submit
        await tester.enterText(projIdFinder, '');
        await tester.tap(buttonFinder);
        await tester.pumpAndSettle();
        expect(find.text('Project ID cannot be empty'), findsOneWidget);
      },
    );

    testWidgets(
      'handles keyboard view insets without overflow and keeps save action reachable',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        // Simulate soft keyboard taking up 350px at the bottom
        tester.view.viewInsets = const FakeViewPadding(bottom: 350.0);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetViewInsets);

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Ensure no RenderFlex overflow occurs with the keyboard up
        expect(tester.takeException(), isNull);

        // Verify content remains scrollable and the save action is reachable
        final buttonFinder = find.widgetWithText(ElevatedButton, 'Add Project');
        await tester.ensureVisible(buttonFinder);
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(buttonFinder, findsOneWidget);

        // Tap the action button to confirm interactivity with keyboard open
        await tester.tap(buttonFinder);
        await tester.pumpAndSettle();
        expect(find.text('Project ID cannot be empty'), findsOneWidget);
      },
    );

    testWidgets(
      'renders bounded width, two-column layout, and end-aligned action on desktop',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1024, 768);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);

        // Bounded width verification (Form inside ResponsiveContainer is bounded to maxWidth: 800)
        final formWidth = tester.getSize(find.byType(Form)).width;
        expect(formWidth, equals(800.0));
        // Form is centered within the 1024px viewport ((1024 - 800) / 2 = 112px)
        final formTopLeft = tester.getTopLeft(find.byType(Form));
        expect(formTopLeft.dx, equals(112.0));

        // Two-column layout: Project ID and Database ID are aligned horizontally
        final projIdFinder = find.widgetWithText(TextFormField, 'Project ID');
        final dbIdFinder = find.widgetWithText(
          TextFormField,
          'Database ID (blank for default)',
        );
        final projIdTopLeft = tester.getTopLeft(projIdFinder);
        final dbIdTopLeft = tester.getTopLeft(dbIdFinder);
        final projIdTopRight = tester.getTopRight(projIdFinder);

        expect(projIdTopLeft.dy, equals(dbIdTopLeft.dy));
        expect(dbIdTopLeft.dx, greaterThan(projIdTopRight.dx));

        // Expanded action button is end-aligned, not stretched full-width
        final buttonFinder = find.widgetWithText(ElevatedButton, 'Add Project');
        final buttonWidth = tester.getSize(buttonFinder).width;
        expect(buttonWidth, lessThan(formWidth / 2));

        final buttonRight = tester.getTopRight(buttonFinder).dx;
        final formRight = tester.getTopRight(find.byType(Form)).dx;
        expect(buttonRight, closeTo(formRight, 2.0));

        // Test dynamic window resizing without recreating widget tree
        // 1. Shrink to compact
        tester.view.physicalSize = const Size(390, 844);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final compactButtonWidth = tester.getSize(buttonFinder).width;
        final compactFormWidth = tester.getSize(find.byType(Form)).width;
        expect(compactButtonWidth, closeTo(compactFormWidth, 2.0));

        // 2. Expand back to desktop
        tester.view.physicalSize = const Size(1024, 768);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(
          tester.getSize(buttonFinder).width,
          lessThan(tester.getSize(find.byType(Form)).width / 2),
        );
      },
    );

    testWidgets('renders intentional layout on medium width (768px tablet)', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(768, 1024);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);

      // Medium width (> 600px breakpoint) uses two columns for identity
      final projIdFinder = find.widgetWithText(TextFormField, 'Project ID');
      final dbIdFinder = find.widgetWithText(
        TextFormField,
        'Database ID (blank for default)',
      );
      expect(
        tester.getTopLeft(projIdFinder).dy,
        equals(tester.getTopLeft(dbIdFinder).dy),
      );

      // Action button is placed at end/right, not stretched full-width
      final buttonFinder = find.widgetWithText(ElevatedButton, 'Add Project');
      final buttonWidth = tester.getSize(buttonFinder).width;
      final formWidth = tester.getSize(find.byType(Form)).width;
      expect(buttonWidth, lessThan(formWidth / 2));
    });

    testWidgets('supports Edit mode and populates existing values', (
      WidgetTester tester,
    ) async {
      final existingProject = Project(
        id: 99,
        created: DateTime.now(),
        updated: DateTime.now(),
        endpointUrl: 'http://custom-endpoint:8080',
        projectId: 'my-existing-project',
        authMode: 'none',
        googleCliProfile: 'default',
        databaseId: 'custom-db',
      );

      await tester.pumpWidget(createTestWidget(project: existingProject));
      await tester.pumpAndSettle();

      // Title shows Edit Project and button shows Save Project
      expect(find.text('Edit Project'), findsOneWidget);
      expect(find.text('Save Project'), findsOneWidget);

      // Existing values populated in controllers
      expect(find.text('my-existing-project'), findsOneWidget);
      expect(find.text('custom-db'), findsOneWidget);
      expect(find.text('http://custom-endpoint:8080'), findsOneWidget);
    });

    testWidgets(
      'Authentication section: without profile takes full width; with profile splits on desktop and stacks on mobile',
      (WidgetTester tester) async {
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        // Case 1: authMode = none (no profile field)
        // On desktop: auth dropdown must occupy full form width (800px), not half width
        tester.view.physicalSize = const Size(1024, 768);
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        final authModeFinder = find.widgetWithText(
          DropdownButtonFormField<String>,
          'Authentication mode',
        );
        expect(authModeFinder, findsOneWidget);
        expect(find.text('Google CLI Profile'), findsNothing);
        expect(tester.getSize(authModeFinder).width, equals(800.0));

        // Case 2: authMode = gcloud cli (with profile field)
        final gcloudProject = Project(
          id: 100,
          created: DateTime.now(),
          updated: DateTime.now(),
          endpointUrl: '',
          projectId: 'gcloud-project',
          authMode: gcloudCliAuthMode,
          googleCliProfile: 'default',
          databaseId: '',
        );

        // On desktop: two columns side-by-side
        await tester.pumpWidget(createTestWidget(project: gcloudProject));
        await tester.pumpAndSettle();

        final profileFinder = find.widgetWithText(
          DropdownButtonFormField<String>,
          'Google CLI Profile',
        );
        expect(profileFinder, findsOneWidget);
        expect(
          tester.getTopLeft(authModeFinder).dy,
          equals(tester.getTopLeft(profileFinder).dy),
        );
        expect(
          tester.getSize(authModeFinder).width,
          equals((800.0 - ResponsiveSpacing.md) / 2),
        );
        expect(
          tester.getSize(profileFinder).width,
          equals((800.0 - ResponsiveSpacing.md) / 2),
        );

        // On mobile: stacked vertically
        tester.view.physicalSize = const Size(390, 844);
        await tester.pumpAndSettle();

        expect(
          tester.getTopLeft(profileFinder).dy,
          greaterThan(tester.getBottomLeft(authModeFinder).dy),
        );
      },
    );
  });

  group('ResponsiveTwoColumnRow API and breakpoint behavior', () {
    testWidgets('with second field: stacks on compact and splits on expanded', (
      WidgetTester tester,
    ) async {
      // 1. Compact: 500px width (< 600px breakpoint)
      tester.view.physicalSize = const Size(500, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ResponsiveTwoColumnRow(
              left: Container(key: const Key('left'), height: 40),
              right: Container(key: const Key('right'), height: 40),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final leftPos = tester.getBottomLeft(find.byKey(const Key('left')));
      final rightPos = tester.getTopLeft(find.byKey(const Key('right')));
      expect(rightPos.dy, greaterThan(leftPos.dy)); // Vertically stacked
      expect(
        tester.getSize(find.byKey(const Key('left'))).width,
        equals(500.0),
      );
      expect(
        tester.getSize(find.byKey(const Key('right'))).width,
        equals(500.0),
      );

      // 2. Expanded: 800px width (>= 600px breakpoint)
      tester.view.physicalSize = const Size(800, 600);
      await tester.pumpAndSettle();

      final leftTop = tester.getTopLeft(find.byKey(const Key('left')));
      final rightTop = tester.getTopLeft(find.byKey(const Key('right')));
      expect(leftTop.dy, equals(rightTop.dy)); // Side-by-side
      final leftWidth = tester.getSize(find.byKey(const Key('left'))).width;
      final rightWidth = tester.getSize(find.byKey(const Key('right'))).width;
      expect(leftWidth, equals((800.0 - ResponsiveSpacing.md) / 2));
      expect(rightWidth, equals(leftWidth));
    });

    testWidgets(
      'without second field: renders only first field full-width without reserving empty column',
      (WidgetTester tester) async {
        // 1. Compact (< 600px)
        tester.view.physicalSize = const Size(500, 600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ResponsiveTwoColumnRow(
                left: Container(key: const Key('left-only'), height: 40),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          tester.getSize(find.byKey(const Key('left-only'))).width,
          equals(500.0),
        );

        // 2. Expanded (>= 600px): must naturally take full 800px, NOT 400px
        tester.view.physicalSize = const Size(800, 600);
        await tester.pumpAndSettle();

        expect(
          tester.getSize(find.byKey(const Key('left-only'))).width,
          equals(800.0),
        );
      },
    );

    testWidgets('transitions cleanly at exact 600px breakpoint boundary', (
      WidgetTester tester,
    ) async {
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      // Just below breakpoint: 599.0 -> stacked
      tester.view.physicalSize = const Size(599, 600);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ResponsiveTwoColumnRow(
              left: Container(key: const Key('boundary-left'), height: 40),
              right: Container(key: const Key('boundary-right'), height: 40),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        tester.getTopLeft(find.byKey(const Key('boundary-right'))).dy,
        greaterThan(
          tester.getBottomLeft(find.byKey(const Key('boundary-left'))).dy,
        ),
      );

      // At exact breakpoint: 600.0 -> two columns side-by-side
      tester.view.physicalSize = const Size(600, 600);
      await tester.pumpAndSettle();

      expect(
        tester.getTopLeft(find.byKey(const Key('boundary-left'))).dy,
        equals(tester.getTopLeft(find.byKey(const Key('boundary-right'))).dy),
      );
    });
  });

  group('Google CLI Profile consistency and determinism', () {
    testWidgets(
      'profile-value consistency: form aligns displayed and persisted profile when stored profile is absent from available profiles',
      (WidgetTester tester) async {
        final projectWithAbsentProfile = Project(
          id: 101,
          created: DateTime.now(),
          updated: DateTime.now(),
          endpointUrl: '',
          projectId: 'absent-profile-project',
          authMode: gcloudCliAuthMode,
          googleCliProfile: 'non_existent_profile',
          databaseId: '',
        );

        const availableProfiles = ['profile_alpha', 'profile_beta'];

        await tester.pumpWidget(
          createTestWidget(
            project: projectWithAbsentProfile,
            profileSource: availableProfiles,
          ),
        );
        await tester.pumpAndSettle();

        // Stored profile is absent, so the form falls back to the first available profile
        final dropdownFinder = find.widgetWithText(
          DropdownButtonFormField<String>,
          'Google CLI Profile',
        );
        expect(dropdownFinder, findsOneWidget);
        expect(find.text('profile_alpha'), findsOneWidget);
        expect(find.text('non_existent_profile'), findsNothing);

        // State value (which is persisted on save) MUST match the displayed/selected dropdown value
        final state = tester.state<AddEditProjectScreenState>(
          find.byType(AddEditProjectScreen),
        );
        expect(state.googleCliProfile, equals('profile_alpha'));

        final dropdownWidget = tester.widget<DropdownButtonFormField<String>>(
          dropdownFinder,
        );
        expect(dropdownWidget.initialValue, equals('profile_alpha'));
        expect(dropdownWidget.initialValue, equals(state.googleCliProfile));
      },
    );

    testWidgets(
      'profile-value consistency: preserves stored profile when present in available profiles',
      (WidgetTester tester) async {
        final projectWithPresentProfile = Project(
          id: 102,
          created: DateTime.now(),
          updated: DateTime.now(),
          endpointUrl: '',
          projectId: 'present-profile-project',
          authMode: gcloudCliAuthMode,
          googleCliProfile: 'profile_beta',
          databaseId: '',
        );

        const availableProfiles = ['profile_alpha', 'profile_beta'];

        await tester.pumpWidget(
          createTestWidget(
            project: projectWithPresentProfile,
            profileSource: availableProfiles,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('profile_beta'), findsOneWidget);

        final state = tester.state<AddEditProjectScreenState>(
          find.byType(AddEditProjectScreen),
        );
        expect(state.googleCliProfile, equals('profile_beta'));
      },
    );

    testWidgets(
      'profile-value consistency: user selection updates both displayed and persisted profile value',
      (WidgetTester tester) async {
        final project = Project(
          id: 103,
          created: DateTime.now(),
          updated: DateTime.now(),
          endpointUrl: '',
          projectId: 'selection-test-project',
          authMode: gcloudCliAuthMode,
          googleCliProfile: 'old_absent_profile',
          databaseId: '',
        );

        const availableProfiles = ['profile_alpha', 'profile_beta'];

        await tester.pumpWidget(
          createTestWidget(project: project, profileSource: availableProfiles),
        );
        await tester.pumpAndSettle();

        final state = tester.state<AddEditProjectScreenState>(
          find.byType(AddEditProjectScreen),
        );
        expect(state.googleCliProfile, equals('profile_alpha'));

        // Tap dropdown and select 'profile_beta'
        final dropdownFinder = find.widgetWithText(
          DropdownButtonFormField<String>,
          'Google CLI Profile',
        );
        await tester.tap(dropdownFinder);
        await tester.pumpAndSettle();

        final itemFinder = find
            .widgetWithText(DropdownMenuItem<String>, 'profile_beta')
            .last;
        await tester.tap(itemFinder);
        await tester.pumpAndSettle();

        expect(state.googleCliProfile, equals('profile_beta'));
        expect(find.text('profile_beta'), findsOneWidget);
      },
    );

    testWidgets(
      'supports deterministic profile discovery via credentialDiscoverer seam',
      (WidgetTester tester) async {
        final fakeDiscoverer = FakeGCloudCLICredentialDiscover([
          'fake_work',
          'fake_personal',
        ]);

        final project = Project(
          id: 104,
          created: DateTime.now(),
          updated: DateTime.now(),
          endpointUrl: '',
          projectId: 'seam-test-project',
          authMode: gcloudCliAuthMode,
          googleCliProfile: 'fake_personal',
          databaseId: '',
        );

        await tester.pumpWidget(
          createTestWidget(
            project: project,
            credentialDiscoverer: fakeDiscoverer,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('fake_personal'), findsOneWidget);
        final state = tester.state<AddEditProjectScreenState>(
          find.byType(AddEditProjectScreen),
        );
        expect(state.googleCliProfile, equals('fake_personal'));
      },
    );
  });
}
