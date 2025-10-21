import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mi_boti/models/med_model.dart';

void main() {
  group('Medication', () {
    test('timeOfDay returns a matching TimeOfDay', () {
      final medication = Medication(
        name: 'Paracetamol',
        dose: '1 tableta',
        strength: '500mg',
        hour: 9,
        minute: 45,
        colorValue: 0xFF123456,
      );

      expect(medication.timeOfDay, const TimeOfDay(hour: 9, minute: 45));
    });

    test('frequencyHours defaults to 8 hours', () {
      final medication = Medication(
        name: 'Amoxicilina',
        dose: '1 capsula',
        strength: '250mg',
        hour: 7,
        minute: 0,
        colorValue: 0xFF654321,
      );

      expect(medication.frequencyHours, 8);
    });
  });
}
