/// Push progress event model for SSE streaming
class PushProgressEvent {
  final String type;
  final int? current;
  final int? total;
  final String? name;
  final int? pushed;
  final int? failed;
  final int? skipped;
  final int? waitTime;
  final int? retry;
  final Map<String, dynamic>? details;

  const PushProgressEvent({
    required this.type,
    this.current,
    this.total,
    this.name,
    this.pushed,
    this.failed,
    this.skipped,
    this.waitTime,
    this.retry,
    this.details,
  });

  factory PushProgressEvent.fromJson(Map<String, dynamic> json) {
    return PushProgressEvent(
      type: json['type'] ?? 'unknown',
      current: json['current'],
      total: json['total'],
      name: json['name'],
      pushed: json['pushed'],
      failed: json['failed'],
      skipped: json['skipped'],
      waitTime: json['wait'],
      retry: json['retry'],
      details: json['details'],
    );
  }

  bool get isStart => type == 'start';
  bool get isProgress => type == 'progress';
  bool get isBackoff => type == 'backoff';
  bool get isComplete => type == 'complete';
}
