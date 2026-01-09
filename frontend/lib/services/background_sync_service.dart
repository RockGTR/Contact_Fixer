import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:http/http.dart' as http;

import '../models/push_progress_event.dart';
import '../providers/sync_state_provider.dart';
import 'notification_service.dart';

/// Callback for sync completion
typedef SyncCompleteCallback =
    void Function(int pushed, int failed, int skipped);

/// Callback for each contact synced (for updating UI)
typedef ContactSyncedCallback = void Function(String contactName);

/// Service for running contact sync in background with notifications
class BackgroundSyncService {
  static final BackgroundSyncService _instance =
      BackgroundSyncService._internal();
  factory BackgroundSyncService() => _instance;
  BackgroundSyncService._internal();

  final NotificationService _notifications = NotificationService();

  bool _isRunning = false;
  http.Client? _client;
  StreamSubscription? _subscription;
  SyncCompleteCallback? _onComplete;
  ContactSyncedCallback? _onContactSynced;
  SyncStateProvider? _syncStateProvider;

  bool get isRunning => _isRunning;

  /// Initialize foreground task (call once at app start)
  Future<void> initialize() async {
    if (kIsWeb) return;

    await _notifications.initialize();

    if (Platform.isAndroid) {
      FlutterForegroundTask.init(
        androidNotificationOptions: AndroidNotificationOptions(
          channelId: 'sync_foreground',
          channelName: 'Contact Sync',
          channelDescription: 'Running contact sync in background',
          channelImportance: NotificationChannelImportance.LOW,
          priority: NotificationPriority.LOW,
          visibility: NotificationVisibility.VISIBILITY_PUBLIC,
        ),
        iosNotificationOptions: const IOSNotificationOptions(
          showNotification: true,
          playSound: false,
        ),
        foregroundTaskOptions: ForegroundTaskOptions(
          eventAction: ForegroundTaskEventAction.nothing(),
          autoRunOnBoot: false,
          autoRunOnMyPackageReplaced: false,
          allowWakeLock: true,
          allowWifiLock: true,
        ),
      );
    }
  }

  /// Start background sync
  Future<bool> startSync({
    required String baseUrl,
    required String idToken,
    required int totalContacts,
    SyncCompleteCallback? onComplete,
    ContactSyncedCallback? onContactSynced,
    SyncStateProvider? syncStateProvider,
  }) async {
    if (_isRunning || kIsWeb) return false;

    _isRunning = true;
    _onComplete = onComplete;
    _onContactSynced = onContactSynced;
    _syncStateProvider = syncStateProvider;

    // Notify state provider
    _syncStateProvider?.startSync(totalContacts);

    // Start foreground task on Android
    if (Platform.isAndroid) {
      await _startForegroundTask();
    }

    // Start streaming sync
    await _startStreaming(baseUrl, idToken, totalContacts);

    return true;
  }

  Future<void> _startForegroundTask() async {
    if (!Platform.isAndroid) return;

    final notificationPermission =
        await FlutterForegroundTask.checkNotificationPermission();
    if (notificationPermission != NotificationPermission.granted) {
      await FlutterForegroundTask.requestNotificationPermission();
    }

    await FlutterForegroundTask.startService(
      notificationTitle: 'Syncing Contacts',
      notificationText: 'Starting sync...',
      notificationIcon: null,
    );
  }

  Future<void> _startStreaming(
    String baseUrl,
    String idToken,
    int totalContacts,
  ) async {
    _client = http.Client();
    final request = http.Request(
      'GET',
      Uri.parse('$baseUrl/contacts/push_to_google/stream'),
    );
    request.headers['Authorization'] = 'Bearer $idToken';

    try {
      final response = await _client!.send(request);

      _subscription = response.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(_handleLine, onError: _handleError, onDone: _handleDone);
    } catch (e) {
      debugPrint('BackgroundSync: Failed to connect: $e');
      await _stopSync(pushed: 0, failed: 0, skipped: 0);
    }
  }

  String? _lastContactName;

  void _handleLine(String line) {
    if (!line.startsWith('data: ')) return;

    try {
      final event = PushProgressEvent.fromJson(jsonDecode(line.substring(6)));

      if (event.isStart) {
        _updateProgress(0, event.total ?? 0, 'Starting...');
      } else if (event.isProgress) {
        // If there was a previous contact, mark it as synced
        if (_lastContactName != null) {
          _syncStateProvider?.markContactSynced(_lastContactName!);
          _onContactSynced?.call(_lastContactName!);
        }
        _lastContactName = event.name;
        _updateProgress(event.current ?? 0, event.total ?? 0, event.name ?? '');
      } else if (event.isBackoff) {
        _syncStateProvider?.setBackoff(event.waitTime ?? 60);
        _notifications.showBackoffNotification(
          waitSeconds: event.waitTime ?? 60,
          contactName: event.name ?? '',
        );
        _updateForegroundText('Rate limited, waiting ${event.waitTime}s...');
      } else if (event.isComplete) {
        // Mark the last contact as synced
        if (_lastContactName != null) {
          _syncStateProvider?.markContactSynced(_lastContactName!);
          _onContactSynced?.call(_lastContactName!);
        }
        _stopSync(
          pushed: event.pushed ?? 0,
          failed: event.failed ?? 0,
          skipped: event.skipped ?? 0,
        );
      }
    } catch (e) {
      debugPrint('BackgroundSync: Error parsing SSE: $e');
    }
  }

  void _updateProgress(int current, int total, String contactName) {
    _syncStateProvider?.updateProgress(current, total, contactName);

    _notifications.showSyncProgress(
      current: current,
      total: total,
      contactName: contactName,
    );

    _updateForegroundText('$current/$total: $contactName');
  }

  void _updateForegroundText(String text) {
    if (Platform.isAndroid) {
      FlutterForegroundTask.updateService(
        notificationTitle: 'Syncing Contacts',
        notificationText: text,
      );
    }
  }

  void _handleError(dynamic error) {
    debugPrint('BackgroundSync: Stream error: $error');
    _stopSync(pushed: 0, failed: 0, skipped: 0);
  }

  void _handleDone() {
    debugPrint('BackgroundSync: Stream done');
  }

  Future<void> _stopSync({
    required int pushed,
    required int failed,
    required int skipped,
  }) async {
    _isRunning = false;
    _lastContactName = null;

    _subscription?.cancel();
    _subscription = null;
    _client?.close();
    _client = null;

    // Stop foreground service
    if (Platform.isAndroid) {
      await FlutterForegroundTask.stopService();
    }

    // Update state provider
    _syncStateProvider?.completeSync(pushed, failed, skipped);

    // Show completion notification
    await _notifications.showSyncComplete(
      pushed: pushed,
      failed: failed,
      skipped: skipped,
    );

    // Notify caller
    _onComplete?.call(pushed, failed, skipped);
    _onComplete = null;
    _onContactSynced = null;
    _syncStateProvider = null;
  }

  /// Cancel running sync
  Future<void> cancelSync() async {
    if (!_isRunning) return;

    _subscription?.cancel();
    _client?.close();

    if (Platform.isAndroid) {
      await FlutterForegroundTask.stopService();
    }

    await _notifications.cancelSyncNotifications();

    _syncStateProvider?.reset();
    _isRunning = false;
    _onComplete = null;
    _onContactSynced = null;
    _syncStateProvider = null;
    _lastContactName = null;
  }
}
