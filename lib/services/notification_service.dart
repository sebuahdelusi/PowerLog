import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:intl/intl.dart';
import 'session_service.dart';

class NotificationService extends GetxService {
  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  final _session = SessionService();
  String _timezoneCode = 'WIB';

  static const AndroidNotificationChannel _dailyChannel = AndroidNotificationChannel(
    'daily_reminder_channel',
    'Daily Reminders',
    description: 'Reminds you to log your usage',
    importance: Importance.high,
  );

  static const AndroidNotificationChannel _customChannel = AndroidNotificationChannel(
    'custom_reminder_channel',
    'Custom Reminders',
    description: 'User scheduled reminders',
    importance: Importance.high,
  );

  static const Map<String, String> _tzLocations = {
    'WIB': 'Asia/Jakarta',
    'WITA': 'Asia/Makassar',
    'WIT': 'Asia/Jayapura',
    'London': 'Europe/London',
  };

  Future<NotificationService> init() async {
    tz.initializeTimeZones();
    _timezoneCode = await _session.getTimezoneCode();
    _applyTimezone(_timezoneCode);

    const AndroidInitializationSettings androidInit =
        AndroidInitializationSettings('@mipmap/ic_launcher');
        
    const DarwinInitializationSettings iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await _plugin.initialize(settings: initSettings);

    final android = _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await android?.createNotificationChannel(_dailyChannel);
    await android?.createNotificationChannel(_customChannel);
    return this;
  }

  void setTimezoneCode(String code) {
    _timezoneCode = code;
    _applyTimezone(code);
  }

  void _applyTimezone(String code) {
    final locationName = _tzLocations[code] ?? 'Asia/Jakarta';
    try {
      tz.setLocalLocation(tz.getLocation(locationName));
    } catch (_) {
      // Keep default tz.local if lookup fails.
    }
  }

  Future<void> scheduleDailyReminder({
    required bool enable,
    int hour = 20,
    int minute = 0,
  }) async {
    if (!enable) {
      await _plugin.cancel(id: 0);
      return;
    }

    final granted = await _ensurePermissions();
    if (!granted) {
      throw Exception('Notification permission not granted.');
    }

    // Schedule for 8:00 PM every day
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate =
      tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    final scheduleMode = await _resolveAndroidScheduleMode();

    await _plugin.zonedSchedule(
      id: 0,
      title: 'Log Your Electricity Usage ⚡',
      body: "Don't forget to log today's kWh usage to track your expenses!",
      scheduledDate: scheduledDate,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_reminder_channel',
          'Daily Reminders',
          channelDescription: 'Reminds you to log your usage',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: scheduleMode,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> scheduleTokenReminder({
    required bool enable,
    DateTime? scheduledAt,
  }) async {
    if (!enable || scheduledAt == null) {
      await _plugin.cancel(id: 0);
      return;
    }

    final granted = await _ensurePermissions();
    if (!granted) {
      throw Exception('Notification permission not granted.');
    }

    final scheduleMode = await _resolveAndroidScheduleMode();
    var tzDate = tz.TZDateTime.from(scheduledAt, tz.local);
    final now = tz.TZDateTime.now(tz.local);

    if (tzDate.isBefore(now)) {
      // If estimation is in the past, don't schedule
      return;
    }

    await _plugin.zonedSchedule(
      id: 0,
      title: 'Token Low Estimation ⚡',
      body:
          "Your token is estimated to run out on ${DateFormat('EEE, d MMM').format(scheduledAt)}. Better top up soon!",
      scheduledDate: tzDate,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_reminder_channel',
          'Token Reminders',
          channelDescription: 'Reminds you when token is estimated to run out',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: scheduleMode,
    );
  }

  Future<void> scheduleCustomReminder({
    required bool enable,
    required DateTime scheduledAt,
  }) async {
    if (!enable) {
      await _plugin.cancel(id: 1);
      return;
    }

    final granted = await _ensurePermissions();
    if (!granted) {
      throw Exception('Notification permission not granted.');
    }

    final scheduleMode = await _resolveAndroidScheduleMode();
    var tzDate = tz.TZDateTime.from(scheduledAt, tz.local);
    final now = tz.TZDateTime.now(tz.local);
    if (tzDate.isBefore(now)) {
      tzDate = now.add(const Duration(minutes: 1));
    }

    await _plugin.zonedSchedule(
      id: 1,
      title: 'PowerLog Reminder',
      body: 'Check your token estimation and appliance usage.',
      scheduledDate: tzDate,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'custom_reminder_channel',
          'Custom Reminders',
          channelDescription: 'User scheduled reminders',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: scheduleMode,
    );
  }

  Future<AndroidScheduleMode> _resolveAndroidScheduleMode() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return AndroidScheduleMode.inexactAllowWhileIdle;

    try {
      final exactAllowed = await android.requestExactAlarmsPermission();
      if (exactAllowed == true) {
        return AndroidScheduleMode.exactAllowWhileIdle;
      }
    } catch (_) {
      // Ignore and fall back to inexact scheduling.
    }

    return AndroidScheduleMode.inexactAllowWhileIdle;
  }

  Future<bool> _ensurePermissions() async {
    var granted = true;

    final android = _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      final res = await android.requestNotificationsPermission();
      final enabled = await android.areNotificationsEnabled();
      if (res == true || enabled == true) {
        granted = true;
      } else if (res == false && enabled == false) {
        granted = false;
      }
    }

    final ios =
        _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      final res = await ios.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      granted = granted && (res ?? true);
    }

    final mac =
        _plugin.resolvePlatformSpecificImplementation<MacOSFlutterLocalNotificationsPlugin>();
    if (mac != null) {
      final res = await mac.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      granted = granted && (res ?? true);
    }

    return granted;
  }
}
