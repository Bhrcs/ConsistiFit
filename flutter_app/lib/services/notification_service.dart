import 'package:flutter_local_notifications/flutter_local_notifications.dart';
class NotificationService {
  final plugin=FlutterLocalNotificationsPlugin();
  Future<void> initialize() async { const settings=InitializationSettings(android:AndroidInitializationSettings('@mipmap/ic_launcher'),iOS:DarwinInitializationSettings()); await plugin.initialize(settings:settings); }
  Future<void> requestPermissions() async { await plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission(); await plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()?.requestPermissions(alert:true,badge:true,sound:true); }
  Future<void> showWorkoutReady()=>plugin.show(id:1001,title:'Your workout is ready',body:'Full Body A is scheduled today. Staying consistent moves your rank.',notificationDetails:const NotificationDetails(android:AndroidNotificationDetails('training','Training reminders',importance:Importance.high),iOS:DarwinNotificationDetails()));
}
