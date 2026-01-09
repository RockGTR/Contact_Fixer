import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../../models/push_progress_event.dart';
import '../../../widgets/neumorphic_container.dart';
import '../../../widgets/neumorphic_button.dart';
import '../../../widgets/neumorphic_progress_bar.dart';
import '../../../widgets/push_status_widgets.dart';
import '../../../widgets/push_completion_summary.dart';

/// Neumorphic progress dialog for pushing changes to Google
class PushProgressDialog extends StatefulWidget {
  final String baseUrl;
  final String idToken;
  final int totalContacts;
  final VoidCallback onComplete;
  final VoidCallback onCancel;

  const PushProgressDialog({
    super.key,
    required this.baseUrl,
    required this.idToken,
    required this.totalContacts,
    required this.onComplete,
    required this.onCancel,
  });

  @override
  State<PushProgressDialog> createState() => _PushProgressDialogState();
}

class _PushProgressDialogState extends State<PushProgressDialog>
    with SingleTickerProviderStateMixin {
  int _current = 0;
  int _total = 0;
  String _currentName = '';
  String _status = 'Connecting...';
  bool _isComplete = false;
  bool _isCancelled = false;
  bool _isBackingOff = false;

  int _pushed = 0;
  int _failed = 0;
  int _skipped = 0;

  http.Client? _client;
  StreamSubscription? _subscription;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _total = widget.totalContacts;
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _startStreaming();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _subscription?.cancel();
    _client?.close();
    super.dispose();
  }

  Future<void> _startStreaming() async {
    _client = http.Client();
    final request = http.Request(
      'GET',
      Uri.parse('${widget.baseUrl}/contacts/push_to_google/stream'),
    );
    request.headers['Authorization'] = 'Bearer ${widget.idToken}';

    try {
      final response = await _client!.send(request);
      _subscription = response.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(_handleLine, onError: _handleError, onDone: _handleDone);
    } catch (e) {
      if (mounted) {
        setState(() {
          _status = 'Failed to connect: $e';
          _isComplete = true;
        });
      }
    }
  }

  void _handleLine(String line) {
    if (_isCancelled || !line.startsWith('data: ')) return;
    try {
      final event = PushProgressEvent.fromJson(jsonDecode(line.substring(6)));
      _handleEvent(event);
    } catch (e) {
      debugPrint('Error parsing SSE: $e');
    }
  }

  void _handleError(dynamic error) {
    if (mounted && !_isCancelled) {
      setState(() {
        _status = 'Error: $error';
        _isComplete = true;
      });
    }
  }

  void _handleDone() {
    if (mounted && !_isComplete && !_isCancelled) {
      setState(() {
        _status = 'Connection closed';
        _isComplete = true;
      });
    }
  }

  void _handleEvent(PushProgressEvent event) {
    if (!mounted || _isCancelled) return;

    setState(() {
      if (event.isStart) {
        _total = event.total ?? _total;
        _status = 'Starting sync...';
        _skipped = event.skipped ?? 0;
      } else if (event.isProgress) {
        _current = event.current ?? _current;
        _total = event.total ?? _total;
        _currentName = event.name ?? '';
        _status = 'Syncing: $_currentName';
        _isBackingOff = false;
      } else if (event.isBackoff) {
        _isBackingOff = true;
        _status = 'Rate limited, waiting ${event.waitTime ?? 60}s...';
      } else if (event.isComplete) {
        _pushed = event.pushed ?? 0;
        _failed = event.failed ?? 0;
        _skipped = event.skipped ?? _skipped;
        _isComplete = true;
        _status = 'Complete!';
      }
    });
  }

  void _handleCancel() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFFE0E5EC),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Cancel Sync?'),
        content: const Text(
          'Contacts already synced will remain updated.\nPending contacts will not be changed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Continue'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFef4444),
            ),
            child: const Text('Cancel', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        _isCancelled = true;
        _status = 'Cancelled';
      });
      _subscription?.cancel();
      _client?.close();
      widget.onCancel();
    }
  }

  double get _progress => _total == 0 ? 0 : _current / _total;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: NeumorphicContainer(
        width: 340,
        padding: const EdgeInsets.all(24),
        borderRadius: BorderRadius.circular(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            if (!_isComplete) ...[
              NeumorphicProgressBar(
                progress: _progress,
                isBackingOff: _isBackingOff,
                pulseAnimation: _pulseController,
              ),
              const SizedBox(height: 16),
              PushStatusIndicator(status: _status, isBackingOff: _isBackingOff),
              const SizedBox(height: 12),
              EstimatedTimeDisplay(current: _current, total: _total),
              const SizedBox(height: 20),
              NeumorphicButton(
                onTap: _handleCancel,
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: const Text(
                  'Cancel',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ),
            ],
            if (_isComplete)
              PushCompletionSummary(
                pushed: _pushed,
                failed: _failed,
                skipped: _skipped,
                onDone: widget.onComplete,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF10b981).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Icons.cloud_upload_rounded,
            color: Color(0xFF10b981),
            size: 28,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isComplete ? 'Sync Complete' : 'Syncing to Google',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF3D4852),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _isComplete
                    ? '$_pushed synced, $_failed failed'
                    : '$_current of $_total contacts',
                style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Shows the push progress dialog
Future<void> showPushProgressDialog({
  required BuildContext context,
  required String baseUrl,
  required String idToken,
  required int totalContacts,
}) async {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => PushProgressDialog(
      baseUrl: baseUrl,
      idToken: idToken,
      totalContacts: totalContacts,
      onComplete: () => Navigator.of(ctx).pop(),
      onCancel: () => Navigator.of(ctx).pop(),
    ),
  );
}
