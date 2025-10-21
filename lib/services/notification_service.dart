import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:hive/hive.dart';
import 'package:mi_boti/models/med_model.dart';

typedef _ScheduleNotificationHandler = Future<void> Function(
  int id,
  String title,
  String body,
  DateTime dateTime, {
  String? payload,
});
typedef _CancelNotificationHandler = Future<void> Function(int id);
typedef _CancelAllHandler = Future<void> Function();
typedef _EnsurePermissionsHandler = Future<bool> Function();

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static _ScheduleNotificationHandler scheduleNotificationHandler =
      _scheduleNotification;
  static _CancelNotificationHandler cancelNotificationHandler =
      _cancelNotification;
  static _CancelAllHandler cancelAllHandler = _cancelAll;
  static _EnsurePermissionsHandler ensureNotificationPermissionsHandler =
      _ensureNotificationPermissions;

  /// Restablece los handlers por defecto. Util para pruebas unitarias.
  static void resetHandlers() {
    scheduleNotificationHandler = _scheduleNotification;
    cancelNotificationHandler = _cancelNotification;
    cancelAllHandler = _cancelAll;
    ensureNotificationPermissionsHandler = _ensureNotificationPermissions;
  }

  /// Inicializar el servicio de notificaciones.
  static Future<void> init() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        try {
          final payload = response.payload;
          if (payload != null && payload.isNotEmpty) {
            final historyBox = await Hive.openBox<HistoryEntry>('history_box');
            await historyBox.add(
              HistoryEntry(
                dateTime: DateTime.now(),
                medName: payload,
                taken: false,
              ),
            );
          }
        } catch (e) {
          // ignore: avoid_print
          print(
            '[NotificationService] Error registrando historial desde notificacion: $e',
          );
        }
      },
    );
    try {
      final launchDetails = await _plugin.getNotificationAppLaunchDetails();
      final launchedPayload = launchDetails?.notificationResponse?.payload;
      if (launchedPayload != null && launchedPayload.isNotEmpty) {
        final historyBox = await Hive.openBox<HistoryEntry>('history_box');
        await historyBox.add(
          HistoryEntry(
            dateTime: DateTime.now(),
            medName: launchedPayload,
            taken: false,
          ),
        );
      }
    } catch (e) {
      // ignore: avoid_print
      print(
        '[NotificationService] Error registrando historial en app launch: $e',
      );
    }
    // ignore: avoid_print
    print('[NotificationService] Notificaciones inicializadas correctamente.');
  }

  /// Cancelar una notificacion por ID.
  static Future<void> cancelNotification(int id) async {
    await cancelNotificationHandler(id);
  }

  static Future<void> _cancelNotification(int id) async {
    await _plugin.cancel(id);
  }

  /// Cancelar todas las notificaciones.
  static Future<void> cancelAll() async {
    await cancelAllHandler();
  }

  static Future<void> _cancelAll() async {
    await _plugin.cancelAll();
  }

  /// Programar notificacion local exacta.
  static Future<void> scheduleNotification(
    int id,
    String title,
    String body,
    DateTime dateTime, {
    String? payload,
  }) async {
    await scheduleNotificationHandler(
      id,
      title,
      body,
      dateTime,
      payload: payload,
    );
  }

  static Future<void> _scheduleNotification(
    int id,
    String title,
    String body,
    DateTime dateTime, {
    String? payload,
  }) async {
    final hasPermissions = await ensureNotificationPermissions();
    if (!hasPermissions) {
      return;
    }

    tz.initializeTimeZones();

    final asuncion = tz.getLocation('America/Asuncion');
    final tzDate = tz.TZDateTime(
      asuncion,
      dateTime.year,
      dateTime.month,
      dateTime.day,
      dateTime.hour,
      dateTime.minute,
    );

    final androidDetails = AndroidNotificationDetails(
      'meds_channel_sound_v1',
      'Recordatorios de medicamentos',
      channelDescription: 'Notificaciones exactas para tomar medicamentos',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      sound: const RawResourceAndroidNotificationSound('pastillas'),
      audioAttributesUsage: AudioAttributesUsage.alarm,
      enableVibration: true,
      fullScreenIntent: true,
    );

    final notificationDetails = NotificationDetails(android: androidDetails);

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tzDate,
      notificationDetails,
      payload: payload,
      matchDateTimeComponents: DateTimeComponents.time,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  /// Solicita permisos de notificaciones y alarmas exactas.
  static Future<bool> ensureNotificationPermissions() async {
    return ensureNotificationPermissionsHandler();
  }

  static Future<bool> _ensureNotificationPermissions() async {
    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }

    if (await Permission.notification.isDenied) {
      return false;
    }

    if (await Permission.scheduleExactAlarm.isDenied) {
      await openAppSettings();
      return false;
    }

    return true;
  }
}
