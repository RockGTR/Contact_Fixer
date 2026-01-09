import 'package:flutter/foundation.dart';

/// Tracks the state of background sync progress for UI updates
class SyncStateProvider extends ChangeNotifier {
  bool _isSyncing = false;
  int _current = 0;
  int _total = 0;
  String _currentContactName = '';
  bool _isBackingOff = false;
  int _backoffSeconds = 0;

  // Results
  int _pushed = 0;
  int _failed = 0;
  int _skipped = 0;
  List<String> _syncedContactNames = [];

  // Getters
  bool get isSyncing => _isSyncing;
  int get current => _current;
  int get total => _total;
  String get currentContactName => _currentContactName;
  bool get isBackingOff => _isBackingOff;
  int get backoffSeconds => _backoffSeconds;
  int get pushed => _pushed;
  int get failed => _failed;
  int get skipped => _skipped;
  List<String> get syncedContactNames => List.unmodifiable(_syncedContactNames);

  double get progress => _total == 0 ? 0 : _current / _total;
  String get statusText {
    if (_isBackingOff) return 'Rate limited, waiting ${_backoffSeconds}s...';
    if (_isSyncing) return 'Syncing: $_currentContactName';
    return '';
  }

  /// Start tracking a sync operation
  void startSync(int total) {
    _isSyncing = true;
    _current = 0;
    _total = total;
    _currentContactName = '';
    _isBackingOff = false;
    _pushed = 0;
    _failed = 0;
    _skipped = 0;
    _syncedContactNames = [];
    notifyListeners();
  }

  /// Update progress for a contact
  void updateProgress(int current, int total, String contactName) {
    _current = current;
    _total = total;
    _currentContactName = contactName;
    _isBackingOff = false;
    notifyListeners();
  }

  /// Mark a contact as synced (for removing from list)
  void markContactSynced(String contactName) {
    _syncedContactNames.add(contactName);
    _pushed++;
    notifyListeners();
  }

  /// Mark contact as failed
  void markContactFailed(String contactName) {
    _failed++;
    notifyListeners();
  }

  /// Set backoff state
  void setBackoff(int waitSeconds) {
    _isBackingOff = true;
    _backoffSeconds = waitSeconds;
    notifyListeners();
  }

  /// Complete the sync operation
  void completeSync(int pushed, int failed, int skipped) {
    _isSyncing = false;
    _pushed = pushed;
    _failed = failed;
    _skipped = skipped;
    _isBackingOff = false;
    notifyListeners();
  }

  /// Reset state
  void reset() {
    _isSyncing = false;
    _current = 0;
    _total = 0;
    _currentContactName = '';
    _isBackingOff = false;
    _pushed = 0;
    _failed = 0;
    _skipped = 0;
    _syncedContactNames = [];
    notifyListeners();
  }
}
