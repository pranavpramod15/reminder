import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as time;
import 'package:flutter_timezone/flutter_timezone.dart';

class NotificationService {
  final notificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    time.initializeTimeZones();
    final currentTimeZone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(currentTimeZone));

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    final androidPlugin =
        notificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.requestNotificationsPermission();
    await androidPlugin?.requestExactAlarmsPermission();
    await androidPlugin?.canScheduleExactNotifications();

    await notificationsPlugin.initialize(
      initSettings,
    );
  }

  NotificationDetails notificationDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        'sample',
        'notifications',
        icon: "@mipmap/ic_launcher",
        channelDescription: "channel_description",
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
  }

  Future<void> showNotification({
    int id = 0,
    String? title,
    String? body,
    String? payload,
  }) async {
    await notificationsPlugin.show(
      id,
      title,
      body,
      notificationDetails(),
      payload: payload,
    );
  }

  void listenForTaskUpdates() {
    FirebaseFirestore.instance
        .collection('tasks')
        .snapshots()
        .listen((snapshot) {
      for (var doc in snapshot.docChanges) {
        var taskData = doc.doc.data();
        if (taskData != null) {
          String docId = doc.doc.id;
          scheduleNotificationFromTask(docId, taskData);
        }
      }
    });
  }

  void scheduleNotificationFromTask(
      String docId, Map<String, dynamic> taskData) {
    try {
      Timestamp timestamp = taskData['time'];
      DateTime localTime = timestamp.toDate();
      int hour = localTime.hour;
      int minute = localTime.minute;

      NotificationService().scheduledNotification(
        id: docId.hashCode,
        title: taskData['task'],
        body: taskData['description'],
        hour: hour,
        minute: minute,
      );
    } catch (e) {
      print("⚠️ Error scheduling notification: $e");
    }
  }

  Future<void> scheduledNotification({
    int id = 1,
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    final scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    final scheduledTime = scheduledDate.isBefore(now)
        ? scheduledDate.add(const Duration(days: 1))
        : scheduledDate;

    await notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      scheduledTime,
      notificationDetails(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }
}
