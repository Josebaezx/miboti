import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:hive/hive.dart';
import 'package:mi_boti/models/med_model.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  /// Inicializar el servicio de notificaciones
  static Future<void> init() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        try {
          final payload = response.payload; // medName
          if (payload != null && payload.isNotEmpty) {
            // Abrir caja de historial y agregar entrada con taken=false por defecto
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
          // Evitar crash en callbacks
          // ignore: avoid_print
          print(
            '[NotificationService] Error registrando historial desde notificación: $e',
          );
        }
      },
    );
    // Si la app fue lanzada al tocar una notificación, también registrar historial
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
    print('[NotificationService] Notificaciones inicializadas correctamente.');
  }

  /// Cancelar una notificación por ID
  static Future<void> cancelNotification(int id) async {
    await _plugin.cancel(id);
  }

  /// Cancelar todas las notificaciones
  static Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  /// Programar notificación local exacta
  static Future<void> scheduleNotification(
    int id,
    String title,
    String body,
    DateTime dateTime, {
    String? payload,
  }) async {
    // ⚠️ Importante: Verifica los permisos antes de continuar.
    final hasPermissions = await ensureNotificationPermissions();
    if (!hasPermissions) {
      // Si no tenemos los permisos, sal del método.
      return;
    }

    // Es crucial inicializar las zonas horarias.
    tz.initializeTimeZones();

    // ✅ CORRECCIÓN: Ajusta la fecha a la zona horaria de Asunción.
    // Esto resuelve el desfase de 3 horas.
    final asuncion = tz.getLocation('America/Asuncion');
    final tzDate = tz.TZDateTime(
      asuncion,
      dateTime.year,
      dateTime.month,
      dateTime.day,
      dateTime.hour,
      dateTime.minute,
    );

    // Canal nuevo para forzar la recreación con sonido personalizado (Android 8+)
    final androidDetails = AndroidNotificationDetails(
      'meds_channel_sound_v1', // ID del canal (cámbialo si ajustas el sonido de nuevo)
      'Recordatorios de medicamentos', // Nombre del canal
      channelDescription: 'Notificaciones exactas para tomar medicamentos',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      sound: RawResourceAndroidNotificationSound(
        'pastillas',
      ), // res/raw/pastillas.mp3
      audioAttributesUsage: AudioAttributesUsage.alarm,
      enableVibration: true,
      fullScreenIntent: true, // Muestra la notificación a pantalla completa
    );

    final notificationDetails = NotificationDetails(android: androidDetails);

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tzDate,
      notificationDetails,
      payload: payload,
      matchDateTimeComponents:
          DateTimeComponents.time, // Repetir a la misma hora
      androidScheduleMode:
          AndroidScheduleMode.exactAllowWhileIdle, // Nuevo modo exacto
    );
  }

  /// Solicita permisos de notificaciones y alarmas exactas
  /// Devuelve true si se concedieron todos los permisos, de lo contrario, false
  static Future<bool> ensureNotificationPermissions() async {
    // Permiso de notificaciones (Android 13+)
    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }

    // Si el usuario no otorga el permiso, no podemos continuar
    if (await Permission.notification.isDenied) {
      return false;
    }

    // Permiso de alarmas exactas (Android 12+)
    if (await Permission.scheduleExactAlarm.isDenied) {
      // Si el permiso está denegado, se debe abrir ajustes para que el usuario lo active.
      // Esto es un punto de quiebre. El usuario debe hacerlo manualmente.
      await openAppSettings();
      return false; // Retorna falso porque no podemos garantizar que el usuario otorgue el permiso
    }

    return true; // Todos los permisos están OK
  }
}
