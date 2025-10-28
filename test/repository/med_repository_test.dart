import 'dart:io'; 
import 'package:flutter_test/flutter_test.dart'; 
import 'package:hive/hive.dart'; 
import 'package:mi_boti/models/med_model.dart'; 
import 'package:mi_boti/repository/med_repository.dart';
import 'package:mi_boti/services/notification_service.dart';

void main() {
  // Inicializa el entorno de pruebas para Flutter
  TestWidgetsFlutterBinding.ensureInitialized();

  // Se ejecuta una sola vez antes de todas las pruebas
  setUpAll(() {
    // Registra los adaptadores Hive si aún no lo están
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(MedicationAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(HistoryEntryAdapter());
    }
  });

  group('MedRepository', () {
    // Variables reutilizadas en las pruebas
    late Directory tempDir;
    late MedRepository repository;
    late List<Map<String, dynamic>> scheduledNotifications;
    late List<int> cancelledNotifications;

    // Se ejecuta antes de cada prueba individual
    setUp(() async {
      // Crea una carpeta temporal para los datos de Hive
      tempDir = await Directory.systemTemp.createTemp('med_repo_test');
      Hive.init(tempDir.path);

      // Listas para simular notificaciones agendadas y canceladas
      scheduledNotifications = [];
      cancelledNotifications = [];

      // Sobrescribe los manejadores del NotificationService con funciones simuladas (mocks)
      NotificationService.scheduleNotificationHandler = (
        int id,
        String title,
        String body,
        DateTime dateTime, {
        String? payload,
      }) async {
        scheduledNotifications.add({
          'id': id,
          'title': title,
          'body': body,
          'dateTime': dateTime,
          'payload': payload,
        });
      };

      NotificationService.cancelNotificationHandler = (int id) async {
        cancelledNotifications.add(id);
      };

      NotificationService.ensureNotificationPermissionsHandler =
          () async => true;

      // Inicializa el repositorio
      repository = MedRepository();
      await repository.init();
    });

    // Se ejecuta después de cada prueba individual
    tearDown(() async {
      // Restaura los manejadores originales
      NotificationService.resetHandlers();
      // Cierra Hive y elimina la carpeta temporal
      await Hive.close();
      await tempDir.delete(recursive: true);
    });

    // Función auxiliar para construir un medicamento de prueba
    Medication buildMedication({
      int frequencyHours = 8,
      int? hour,
      int? minute,
    }) {
      final now = DateTime.now();
      return Medication(
        name: 'Ibuprofeno',
        dose: '1 tableta',
        strength: '400mg',
        hour: hour ?? now.hour,
        minute: minute ?? now.minute,
        colorValue: 0xFF2196F3,
        frequencyHours: frequencyHours,
      );
    }

    // Función auxiliar para construir una entrada de historial de prueba
    HistoryEntry buildHistoryEntry({bool taken = false}) {
      return HistoryEntry(
        dateTime: DateTime(2024, 1, 1, 10, 0),
        medName: 'Ibuprofeno',
        taken: taken,
      );
    }

    // ---------------------- TESTS ----------------------

    test('addMedication almacena medicamento y programa notificaciones', () async {
      var notified = false;
      repository.addListener(() {
        notified = true;
      });

      final medication = buildMedication(frequencyHours: 12, hour: 8, minute: 30);
      await repository.addMedication(medication);

      // Verifica que se haya guardado el medicamento
      expect(repository.meds, hasLength(1));
      expect(repository.meds.first.name, 'Ibuprofeno');
      expect(notified, isTrue);

      // 24 / 12 = 2 notificaciones programadas por día
      expect(scheduledNotifications.length, 2);
      expect(scheduledNotifications.first['payload'], 'Ibuprofeno');
      expect(scheduledNotifications.first['title'], 'Hora de tomar');
      expect(scheduledNotifications.first['body'], 'Ibuprofeno 1 tableta');
    });

    test('addHistory guarda la entrada en el historial y notifica', () async {
      var notified = false;
      repository.addListener(() {
        notified = true;
      });

      final entry = buildHistoryEntry();
      await repository.addHistory(entry);

      expect(repository.history, hasLength(1));
      expect(repository.history.first.medName, 'Ibuprofeno');
      expect(notified, isTrue);
    });

    test('markHistory actualiza una entrada existente', () async {
      final entry = buildHistoryEntry();
      await repository.addHistory(entry);

      await repository.markHistory(entry, true);

      final stored = repository.history.first;
      expect(stored.taken, isTrue);
    });

    test('deleteHistory elimina una entrada del historial', () async {
      final entry = buildHistoryEntry();
      await repository.addHistory(entry);

      await repository.deleteHistory(entry);

      expect(repository.history, isEmpty);
    });

    test('clearHistory elimina todas las entradas', () async {
      await repository.addHistory(buildHistoryEntry());
      await repository.addHistory(buildHistoryEntry());

      await repository.clearHistory();

      expect(repository.history, isEmpty);
    });

    test('updateMedication reprograma notificaciones y actualiza datos', () async {
      final original = buildMedication(frequencyHours: 8, hour: 7, minute: 15);
      await repository.addMedication(original);
      final stored = repository.meds.first;
      final key = stored.key as int;

      scheduledNotifications.clear();
      cancelledNotifications.clear();

      final updated = buildMedication(
        frequencyHours: 6,
        hour: 9,
        minute: 0,
      );

      await repository.updateMedication(key, updated);

      // Verifica que se cancelaron las notificaciones anteriores
      expect(cancelledNotifications, containsAll(List.generate(12, (i) => key * 100 + i)));

      // 24 / 6 = 4 nuevas notificaciones
      expect(scheduledNotifications.length, 4);

      // Verifica que los datos del medicamento fueron actualizados
      final refreshed = repository.meds.first;
      expect(refreshed.hour, 9);
      expect(refreshed.minute, 0);
      expect(refreshed.frequencyHours, 6);
    });

    test('removeMedication cancela notificaciones y elimina el medicamento', () async {
      final medication = buildMedication(frequencyHours: 4);
      await repository.addMedication(medication);
      final stored = repository.meds.first;
      final key = stored.key as int;

      cancelledNotifications.clear();

      await repository.removeMedication(stored);

      // Verifica que se eliminó del repositorio y se cancelaron las notificaciones
      expect(repository.meds, isEmpty);
      expect(
        cancelledNotifications,
        containsAll(List.generate(12, (i) => key * 100 + i)),
      );
    });
  });
}
