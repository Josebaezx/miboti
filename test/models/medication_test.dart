import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mi_boti/models/med_model.dart';

// La función main() agrupa y ejecuta todas las pruebas unitarias de este archivo
void main() {

  // 'group' permite organizar las pruebas por tema o clase. 
  // En este caso, todas las pruebas pertenecen al modelo 'Medication'.
  group('Medication', () {

    // ✅ PRIMERA PRUEBA
    // Comprueba que el método o propiedad 'timeOfDay' de la clase Medication 
    // devuelva correctamente un objeto TimeOfDay con la hora y los minutos asignados.
    test('timeOfDay returns a matching TimeOfDay', () {

      // Se crea una instancia de la clase Medication con valores de ejemplo.
      final medication = Medication(
        name: 'Paracetamol',
        dose: '1 tableta',
        strength: '500mg',
        hour: 9,
        minute: 45,
        colorValue: 0xFF123456,
      );

      // Se espera que la propiedad 'timeOfDay' sea igual a un TimeOfDay con 9:45.
      expect(medication.timeOfDay, const TimeOfDay(hour: 9, minute: 45));
    });

    // ✅ SEGUNDA PRUEBA
    // Verifica que la propiedad 'frequencyHours' tenga el valor por defecto de 8 horas
    // si no se le pasa otro valor al crear el objeto.
    test('frequencyHours defaults to 8 hours', () {

      // Se crea otra instancia de Medication, sin especificar frequencyHours.
      final medication = Medication(
        name: 'Amoxicilina',
        dose: '1 capsula',
        strength: '250mg',
        hour: 7,
        minute: 0,
        colorValue: 0xFF654321,
      );

      // Se espera que el valor por defecto sea 8 horas.
      expect(medication.frequencyHours, 8);
    });
  });
}
