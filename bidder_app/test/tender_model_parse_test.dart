import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:bidder_app/models/tender_models.dart';

void main() {
  test('All 53 bundled tenders parse correctly into TenderModel', () {
    final file = File('../backend/app/data/tenders.json');
    expect(file.existsSync(), isTrue, reason: 'tenders.json must exist');

    final jsonMap = json.decode(file.readAsStringSync()) as Map<String, dynamic>;
    expect(jsonMap.length, 53, reason: 'Should contain all 53 tenders');

    int parsedCount = 0;
    for (final entry in jsonMap.entries) {
      final map = entry.value as Map<String, dynamic>;
      expect(() {
        final model = TenderModel.fromJson(map);
        expect(model.tenderId.isNotEmpty, isTrue);
        parsedCount++;
      }, returnsNormally, reason: 'Failed parsing ${entry.key}');
    }

    expect(parsedCount, 53);
  });
}
