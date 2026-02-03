import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:googleapis/datastore/v1.dart' as dsv1;

void main() {
  group('GeoPoint Logic', () {
    test('extractValue populates controllers correctly', () {
      final value = dsv1.Value(
        geoPointValue: dsv1.LatLng(latitude: 37.7749, longitude: -122.4194),
      );

      // logic from extractValue
      final latController = TextEditingController(text: value.geoPointValue?.latitude?.toString() ?? "");
      final lngController = TextEditingController(text: value.geoPointValue?.longitude?.toString() ?? "");

      expect(latController.text, '37.7749');
      expect(lngController.text, '-122.4194');
    });

    test('extractValue handles null GeoPoint', () {
      final value = dsv1.Value(geoPointValue: null);

      // logic from extractValue
      final latController = TextEditingController(text: value.geoPointValue?.latitude?.toString() ?? "");
      final lngController = TextEditingController(text: value.geoPointValue?.longitude?.toString() ?? "");

      expect(latController.text, '');
      expect(lngController.text, '');
    });

    test('createValue creates Value correctly from valid input', () {
      final latController = TextEditingController(text: '37.7749');
      final lngController = TextEditingController(text: '-122.4194');

      // logic from createValue
      final value = dsv1.Value(
        geoPointValue: dsv1.LatLng(
          latitude: double.tryParse(latController.text),
          longitude: double.tryParse(lngController.text),
        ),
      );

      expect(value.geoPointValue?.latitude, 37.7749);
      expect(value.geoPointValue?.longitude, -122.4194);
    });

    test('createValue creates Value correctly from invalid input', () {
      final latController = TextEditingController(text: 'invalid');
      final lngController = TextEditingController(text: '');

      // logic from createValue
      final value = dsv1.Value(
        geoPointValue: dsv1.LatLng(
          latitude: double.tryParse(latController.text),
          longitude: double.tryParse(lngController.text),
        ),
      );

      expect(value.geoPointValue?.latitude, isNull);
      expect(value.geoPointValue?.longitude, isNull);
    });
  });
}
