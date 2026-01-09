import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Service for managing local notifications (sync progress)
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static const String _channelId = 'sync_progress';
  static const String _channelName = 'Sync Progress';
  static const String _channelDescription = 'Shows contact sync progress';
  static const int _progressNotificationId = 1;
  static const int _completeNotificationId = 2;

  bool _isInitialized = false;

  /// Initialize notification channels (call once at app start)
  Future<void> initialize() async {
    if (_isInitialized || kIsWeb) return;

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // Create notification channel for Android
    if (Platform.isAndroid) {
      await _createAndroidChannel();
    }

    // Request permission on iOS
    if (Platform.isIOS) {
      await _notifications
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true);
    }

    _isInitialized = true;
  }

  Future<void> _createAndroidChannel() async {
    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDescription,
      importance: Importance.low, // Low to avoid sound/vibration on each update
      showBadge: false,
    );

    await _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);
  }

  void _onNotificationTap(NotificationResponse response) {
    // Handle notification tap - app is already open via this callback
    debugPrint('Notification tapped: ${response.payload}');
  }

  /// Show/update sync progress notification
  Future<void> showSyncProgress({
    required int current,
    required int total,
    required String contactName,
  }) async {
    if (kIsWeb) return;

    final androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true, // Cannot be dismissed
      autoCancel: false,
      showProgress: true,
      maxProgress: total,
      progress: current,
      onlyAlertOnce: true, // Don't make sound on updates
      category: AndroidNotificationCategory.progress,
    );

    final iosDetails = DarwinNotificationDetails(
      presentAlert: false,
      presentBadge: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      _progressNotificationId,
      'Syncing Contacts',
      'Syncing $current/$total: $contactName',
      details,
      payload: 'sync_progress',
    );
  }

  /// Show rate limit backoff notification
  Future<void> showBackoffNotification({
    required int waitSeconds,
    required String contactName,
  }) async {
    if (kIsWeb) return;

    final androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
      autoCancel: false,
      onlyAlertOnce: true,
      category: AndroidNotificationCategory.progress,
    );

    final details = NotificationDetails(android: androidDetails);

    await _notifications.show(
      _progressNotificationId,
      'Syncing Contacts',
      'Rate limited, waiting ${waitSeconds}s...',
      details,
      payload: 'sync_backoff',
    );
  }

  /// Show sync complete notification
  Future<void> showSyncComplete({
    required int pushed,
    required int failed,
    required int skipped,
  }) async {
    if (kIsWeb) return;

    // Cancel the progress notification
    await _notifications.cancel(_progressNotificationId);

    final message = failed > 0
        ? '✓ $pushed synced, $failed failed'
        : '✓ $pushed contacts synced';

    final androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      autoCancel: true,
    );

    final iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      _completeNotificationId,
      'Sync Complete',
      message,
      details,
      payload: 'sync_complete',
    );
  }

  /// Cancel all sync notifications
  Future<void> cancelSyncNotifications() async {
    if (kIsWeb) return;
    await _notifications.cancel(_progressNotificationId);
  }
}
