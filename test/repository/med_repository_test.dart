import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:mi_boti/models/med_model.dart';
import 'package:mi_boti/repository/med_repository.dart';
import 'package:mi_boti/services/notification_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(MedicationAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(HistoryEntryAdapter());
    }
  });

  group('MedRepository', () {
    late Directory tempDir;
    late MedRepository repository;
    late List<Map<String, dynamic>> scheduledNotifications;
    late List<int> cancelledNotifications;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('med_repo_test');
      Hive.init(tempDir.path);

      scheduledNotifications = [];
      cancelledNotifications = [];

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

      repository = MedRepository();
      await repository.init();
    });

    tearDown(() async {
      NotificationService.resetHandlers();
      await Hive.close();
      await tempDir.delete(recursive: true);
    });

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

    HistoryEntry buildHistoryEntry({bool taken = false}) {
      return HistoryEntry(
        dateTime: DateTime(2024, 1, 1, 10, 0),
        medName: 'Ibuprofeno',
        taken: taken,
      );
    }

    test('addMedication stores medication, schedules notifications and notifies listeners', () async {
      var notified = false;
      repository.addListener(() {
        notified = true;
      });

      final medication = buildMedication(frequencyHours: 12, hour: 8, minute: 30);
      await repository.addMedication(medication);

      expect(repository.meds, hasLength(1));
      expect(repository.meds.first.name, 'Ibuprofeno');
      expect(notified, isTrue);

      // 24 / 12 = 2 programaciones
      expect(scheduledNotifications.length, 2);
      expect(scheduledNotifications.first['payload'], 'Ibuprofeno');
      expect(scheduledNotifications.first['title'], 'Hora de tomar');
      expect(scheduledNotifications.first['body'], 'Ibuprofeno 1 tableta');
    });

    test('addHistory persists entry and triggers listeners', () async {
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

    test('markHistory updates an existing entry', () async {
      final entry = buildHistoryEntry();
      await repository.addHistory(entry);

      await repository.markHistory(entry, true);

      final stored = repository.history.first;
      expect(stored.taken, isTrue);
    });

    test('deleteHistory removes the entry', () async {
      final entry = buildHistoryEntry();
      await repository.addHistory(entry);

      await repository.deleteHistory(entry);

      expect(repository.history, isEmpty);
    });

    test('clearHistory removes all entries', () async {
      await repository.addHistory(buildHistoryEntry());
      await repository.addHistory(buildHistoryEntry());

      await repository.clearHistory();

      expect(repository.history, isEmpty);
    });

    test('updateMedication reschedules notifications and updates data', () async {
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

      expect(cancelledNotifications, containsAll(List.generate(12, (i) => key * 100 + i)));
      // 24 / 6 = 4 programaciones nuevas
      expect(scheduledNotifications.length, 4);
      final refreshed = repository.meds.first;
      expect(refreshed.hour, 9);
      expect(refreshed.minute, 0);
      expect(refreshed.frequencyHours, 6);
    });

    test('removeMedication cancels notifications and deletes the item', () async {
      final medication = buildMedication(frequencyHours: 4);
      await repository.addMedication(medication);
      final stored = repository.meds.first;
      final key = stored.key as int;

      cancelledNotifications.clear();

      await repository.removeMedication(stored);

      expect(repository.meds, isEmpty);
      expect(
        cancelledNotifications,
        containsAll(List.generate(12, (i) => key * 100 + i)),
      );
    });
  });
}
