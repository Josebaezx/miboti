import 'package:flutter/material.dart';

class Medication {
  Medication({
    required this.name,
    required this.dose,
    required this.strength,
    required this.timeOfDay,
    this.color,
  });

  final String name; // e.g., Ibuprofeno
  final String dose; // e.g., 400 mg
  final String strength; // e.g., "20 mg" (small subtitle) or frequency info
  final TimeOfDay timeOfDay;
  final Color? color;
}

class HistoryEntry {
  HistoryEntry({
    required this.dateTime,
    required this.medName,
    required this.taken,
  });

  final DateTime dateTime;
  final String medName;
  final bool taken;
}

class MedRepository extends ChangeNotifier {
  MedRepository({bool seed = false}) {
    if (seed) {
      _seed();
    }
  }

  final List<Medication> _meds = [];
  final List<HistoryEntry> _history = [];

  List<Medication> get meds => List.unmodifiable(_meds);
  List<HistoryEntry> get history => List.unmodifiable(_history);

  void addMedication(Medication med, {int days = 10}) {
    _meds.add(med);
    // create initial history entries for demo (one per upcoming day at med.timeOfDay)
    final now = DateTime.now();
    for (int i = -3; i < 4; i++) {
      final date = now.add(Duration(days: i));
      final dt = DateTime(date.year, date.month, date.day, med.timeOfDay.hour, med.timeOfDay.minute);
      _history.add(HistoryEntry(dateTime: dt, medName: med.name, taken: i.isEven));
    }
    notifyListeners();
  }

  void markHistory(HistoryEntry entry, bool taken) {
    final idx = _history.indexOf(entry);
    if (idx != -1) {
      _history[idx] = HistoryEntry(dateTime: entry.dateTime, medName: entry.medName, taken: taken);
      notifyListeners();
    }
  }

  void _seed() {
    addMedication(Medication(
      name: 'Ibuprofeno',
      dose: '400 mg',
      strength: '',
      timeOfDay: const TimeOfDay(hour: 8, minute: 0),
      color: const Color(0xFFEF4444),
    ));
    addMedication(Medication(
      name: 'Amoxicilina',
      dose: '20 mg',
      strength: '',
      timeOfDay: const TimeOfDay(hour: 13, minute: 0),
      color: const Color(0xFF10B981),
    ));
    addMedication(Medication(
      name: 'Omeprazol',
      dose: '20 mg',
      strength: '',
      timeOfDay: const TimeOfDay(hour: 21, minute: 0),
      color: const Color(0xFFF59E0B),
    ));
    addMedication(Medication(
      name: 'Metformina',
      dose: '600 mg',
      strength: '',
      timeOfDay: const TimeOfDay(hour: 22, minute: 0),
      color: const Color(0xFF3B82F6),
    ));
  }
}
