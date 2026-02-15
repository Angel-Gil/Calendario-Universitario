import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:local_notifier/local_notifier.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

// Conditional import: web-safe
import 'notification_web_stub.dart'
    if (dart.library.js_interop) 'notification_web_impl.dart';

class NotificationService {
  static NotificationService? _instance;
  static NotificationService get instance =>
      _instance ??= NotificationService._();

  NotificationService._();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  // Timer para verificar notificaciones en plataformas sin scheduling nativo (Windows/Web)
  Timer? _schedulerTimer;
  final List<_ScheduledNotification> _scheduledNotifications = [];

  bool get _isMobile {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  bool get _isDesktop {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.linux;
  }

  Future<void> initialize() async {
    if (_isInitialized) return;

    tz.initializeTimeZones();

    if (kIsWeb) {
      // Web Initialization (WASM-compatible)
      await initializeWebNotifications();
    } else if (_isDesktop) {
      // Windows/macOS/Linux Initialization
      await localNotifier.setup(
        appName: 'UniCal',
        shortcutPolicy: ShortcutPolicy.requireCreate,
      );
    } else if (_isMobile) {
      // Android/iOS Initialization
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      final InitializationSettings initializationSettings =
          InitializationSettings(android: initializationSettingsAndroid);

      await _flutterLocalNotificationsPlugin.initialize(
        settings: initializationSettings,
        onDidReceiveNotificationResponse: (details) {
          debugPrint('Notification clicked: ${details.payload}');
        },
      );

      // Solicitar permisos en Android 13+
      await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
    }

    // Iniciar timer para Windows/Web (sin scheduling nativo)
    if (kIsWeb || _isDesktop) {
      _startSchedulerTimer();
    }

    _isInitialized = true;
    debugPrint('NotificationService: Inicializado');
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (kIsWeb) {
      await showWebNotification(title, body);
    } else if (_isDesktop) {
      final notification = LocalNotification(
        identifier: id.toString(),
        title: title,
        body: body,
      );
      notification.show();
    } else {
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
            'calendario_channel',
            'Notificaciones del Calendario',
            channelDescription: 'Recordatorios de eventos y clases',
            importance: Importance.max,
            priority: Priority.high,
          );
      const NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
      );
      await _flutterLocalNotificationsPlugin.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: platformChannelSpecifics,
        payload: payload,
      );
    }
  }

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    final now = DateTime.now();
    if (scheduledDate.isBefore(now)) return;

    try {
      if (_isMobile) {
        await _flutterLocalNotificationsPlugin.zonedSchedule(
          id: id,
          title: title,
          body: body,
          scheduledDate: tz.TZDateTime.from(scheduledDate, tz.local),
          notificationDetails: const NotificationDetails(
            android: AndroidNotificationDetails(
              'calendario_channel',
              'Notificaciones del Calendario',
              channelDescription: 'Recordatorios de eventos y clases',
              importance: Importance.max,
              priority: Priority.high,
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.time,
          payload: payload,
        );
      } else {
        // Windows/Web: usar timer polling
        _scheduledNotifications.add(
          _ScheduledNotification(
            id: id,
            title: title,
            body: body,
            scheduledDate: scheduledDate,
            payload: payload,
          ),
        );
      }
      debugPrint('Notificación programada: $title para $scheduledDate');
    } catch (e) {
      debugPrint('Error programando notificación: $e');
    }
  }

  Future<void> cancelNotification(int id) async {
    if (_isMobile) {
      await _flutterLocalNotificationsPlugin.cancel(id: id);
    } else {
      _scheduledNotifications.removeWhere((n) => n.id == id);
    }
  }

  Future<void> cancelAllNotifications() async {
    if (_isMobile) {
      await _flutterLocalNotificationsPlugin.cancelAll();
    } else {
      _scheduledNotifications.clear();
    }
  }

  void _startSchedulerTimer() {
    _schedulerTimer?.cancel();
    _schedulerTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      final now = DateTime.now();
      final toShow = _scheduledNotifications
          .where(
            (n) =>
                n.scheduledDate.isBefore(now) ||
                n.scheduledDate.isAtSameMomentAs(now),
          )
          .toList();

      for (var n in toShow) {
        showNotification(
          id: n.id,
          title: n.title,
          body: n.body,
          payload: n.payload,
        );
        _scheduledNotifications.remove(n);
      }
    });
  }
}

class _ScheduledNotification {
  final int id;
  final String title;
  final String body;
  final DateTime scheduledDate;
  final String? payload;

  _ScheduledNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.scheduledDate,
    this.payload,
  });
}
