import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:mi_boti/models/background_config.dart';
import 'package:mi_boti/models/med_model.dart';
import 'package:mi_boti/services/notification_service.dart';

class MedRepository extends ChangeNotifier {
  static const String medsBoxName = 'meds_box';
  static const String historyBoxName = 'history_box';
  static const String settingsBoxName = 'settings_box';
  static const String backgroundKey = 'background_config';

  late Box<Medication> _medsBox;
  late Box<HistoryEntry> _historyBox;
  late Box _settingsBox;

  BackgroundConfig _backgroundConfig = BackgroundConfig.defaults;

  Future<void> init() async {
    _medsBox = await Hive.openBox<Medication>(medsBoxName);
    _historyBox = await Hive.openBox<HistoryEntry>(historyBoxName);
    _settingsBox = await Hive.openBox(settingsBoxName);
    _backgroundConfig = BackgroundConfig.fromMap(
      _settingsBox.get(backgroundKey) as Map?,
    );
  }

  List<Medication> get meds => _medsBox.values.toList();

  List<HistoryEntry> get history {
    return _historyBox.values.toList();
  }

  Future<void> addMedication(Medication med) async {
    final int key = await _medsBox.add(med);
    final now = DateTime.now();
    final occurrences = (24 ~/ med.frequencyHours).clamp(1, 12);
    for (int i = 0; i < occurrences; i++) {
      final addHours = med.frequencyHours * i;
      DateTime scheduled = DateTime(
        now.year,
        now.month,
        now.day,
        med.hour,
        med.minute,
      ).add(Duration(hours: addHours));
      // Si por sumar horas pasamos al día siguiente, la repetición diaria se mantiene en esa hora
      if (scheduled.isBefore(now)) {
        scheduled = scheduled.add(const Duration(days: 1));
      }
      final notifId = key * 100 + i; // IDs determinísticos por franja
      await NotificationService.scheduleNotification(
        notifId,
        'Hora de tomar',
        '${med.name} ${med.dose}',
        scheduled,
        payload: med.name,
      );
    }
    notifyListeners();
  }

  Future<void> addHistory(HistoryEntry entry) async {
    await _historyBox.add(entry);
    notifyListeners();
  }

  Future<void> markHistory(HistoryEntry entry, bool taken) async {
    final entries = _historyBox.values.toList();
    final idx = entries.indexOf(entry);
    if (idx != -1) {
      final key = _historyBox.keyAt(idx);
      entry.taken = taken;
      await _historyBox.put(key, entry);
      notifyListeners();
    }
  }

  /// Elimina una entrada específica del historial
  Future<void> deleteHistory(HistoryEntry entry) async {
    final entries = _historyBox.values.toList();
    final idx = entries.indexOf(entry);
    if (idx != -1) {
      final key = _historyBox.keyAt(idx);
      await _historyBox.delete(key);
      notifyListeners();
    }
  }

  /// Limpia todo el historial
  Future<void> clearHistory() async {
    await _historyBox.clear();
    notifyListeners();
  }

  BackgroundConfig get backgroundConfig => _backgroundConfig;

  Future<void> updateBackground(BackgroundConfig config) async {
    _backgroundConfig = config;
    await _settingsBox.put(backgroundKey, config.toMap());
    notifyListeners();
  }

  /// Actualiza un medicamento y reprograma su notificación
  Future<void> updateMedication(int key, Medication updated) async {
    // Cancelar notificaciones previas de este medicamento (hasta 12 franjas)
    for (int i = 0; i < 12; i++) {
      await NotificationService.cancelNotification(key * 100 + i);
    }
    // Guardar cambios
    await _medsBox.put(key, updated);
    // Reprogramar todas las ocurrencias según la nueva frecuencia
    final now = DateTime.now();
    final occurrences = (24 ~/ updated.frequencyHours).clamp(1, 12);
    for (int i = 0; i < occurrences; i++) {
      final addHours = updated.frequencyHours * i;
      DateTime scheduled = DateTime(
        now.year,
        now.month,
        now.day,
        updated.hour,
        updated.minute,
      ).add(Duration(hours: addHours));
      if (scheduled.isBefore(now)) {
        scheduled = scheduled.add(const Duration(days: 1));
      }
      final notifId = key * 100 + i;
      await NotificationService.scheduleNotification(
        notifId,
        'Hora de tomar',
        '${updated.name} ${updated.dose}',
        scheduled,
        payload: updated.name,
      );
    }
    notifyListeners();
  }

  /// Elimina un medicamento y cancela su notificación
  Future<void> removeMedication(Medication med) async {
    final int key = med.key as int;
    // Cancelar todas las notificaciones asociadas
    for (int i = 0; i < 12; i++) {
      await NotificationService.cancelNotification(key * 100 + i);
    }
    await _medsBox.delete(key);
    notifyListeners();
  }
}
