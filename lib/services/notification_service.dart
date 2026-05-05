import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'session_service.dart';

class NotificationService extends GetxService {
  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  final _session = SessionService();
  String _timezoneCode = 'WIB';

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
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<bool> _ensurePermissions() async {
    var granted = true;

    final android = _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      final res = await android.requestNotificationsPermission();
      final enabled = await android.areNotificationsEnabled();
      if (enabled != null) {
        granted = enabled;
      } else {
        granted = res ?? true;
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
