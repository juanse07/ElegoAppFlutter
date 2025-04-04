import 'package:intl/intl.dart';

class BusyTimeSlot {
  final String id;
  final DateTime startTime;
  final DateTime endTime;
  final bool isAllDay;
  final DateTime createdAt;
  final DateTime updatedAt;

  BusyTimeSlot({
    required this.id,
    required this.startTime,
    required this.endTime,
    required this.isAllDay,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BusyTimeSlot.fromJson(Map<String, dynamic> json) {
    // Parse UTC dates from API
    final startTimeUtc = DateTime.parse(json['startTime'] as String);
    final endTimeUtc = DateTime.parse(json['endTime'] as String);

    // Handle optional createdAt and updatedAt fields
    final createdAtUtc =
        json['createdAt'] != null
            ? DateTime.parse(json['createdAt'] as String)
            : DateTime.now();
    final updatedAtUtc =
        json['updatedAt'] != null
            ? DateTime.parse(json['updatedAt'] as String)
            : DateTime.now();

    return BusyTimeSlot(
      id: json['_id'] as String,
      // Convert UTC to local time
      startTime: startTimeUtc.toLocal(),
      endTime: endTimeUtc.toLocal(),
      isAllDay: json['isAllDay'] as bool? ?? false,
      createdAt: createdAtUtc.toLocal(),
      updatedAt: updatedAtUtc.toLocal(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      // Convert local times to UTC for API
      'startTime': startTime.toUtc().toIso8601String(),
      'endTime': endTime.toUtc().toIso8601String(),
      'isAllDay': isAllDay,
      'createdAt': createdAt.toUtc().toIso8601String(),
      'updatedAt': updatedAt.toUtc().toIso8601String(),
    };
  }

  // Helper method for formatting date and time for display in local time
  String formatStartTime(String format) {
    final formatter = DateFormat(format);
    return formatter.format(startTime.toLocal());
  }

  // Helper method for formatting date and time for display in local time
  String formatEndTime(String format) {
    final formatter = DateFormat(format);
    return formatter.format(endTime.toLocal());
  }

  // Format just the date portion in local time
  String get formattedDate {
    return DateFormat('yyyy-MM-dd').format(startTime.toLocal());
  }

  // Format just the time portion in local time
  String get formattedStartTime {
    if (isAllDay) return 'All Day';
    final formatter = DateFormat('h:mm a');
    return formatter.format(startTime);
  }

  String get formattedEndTime {
    if (isAllDay) return 'All Day';
    final formatter = DateFormat('h:mm a');
    return formatter.format(endTime);
  }

  // Get a local DateTime version for UI display
  DateTime get localStartTime => startTime.toLocal();
  DateTime get localEndTime => endTime.toLocal();

  // Helper to check if a time slot is for today
  bool get isToday {
    final now = DateTime.now();
    return startTime.year == now.year &&
        startTime.month == now.month &&
        startTime.day == now.day;
  }

  // Helper to check if a time slot is in the past
  bool get isInPast {
    return startTime.isBefore(DateTime.now());
  }
}
