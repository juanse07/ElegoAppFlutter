import 'package:intl/intl.dart';

class BusyTimeSlot {
  final String id;
  final DateTime startTime; // Stored in UTC
  final DateTime endTime; // Stored in UTC
  final bool isAllDay;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Preset message for all busy slots
  static const String defaultMessage = 'Marked unavailable by Pro';

  BusyTimeSlot({
    required this.id,
    required this.startTime,
    required this.endTime,
    this.isAllDay = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BusyTimeSlot.fromJson(Map<String, dynamic> json) {
    // Parse the ID correctly depending on format
    String id;
    if (json['_id'] is String) {
      id = json['_id'];
    } else if (json['_id'] is Map) {
      id = json['_id']['\$oid'] ?? '';
    } else {
      id = '';
    }

    // Parse dates to UTC
    DateTime parseDate(dynamic dateValue) {
      if (dateValue == null) return DateTime.now().toUtc();

      try {
        if (dateValue is String) {
          // Parse as UTC, but keep it as UTC
          return DateTime.parse(dateValue);
        } else if (dateValue is Map && dateValue['\$date'] != null) {
          if (dateValue['\$date'] is String) {
            return DateTime.parse(dateValue['\$date']);
          } else if (dateValue['\$date'] is Map &&
              dateValue['\$date']['\$numberLong'] != null) {
            return DateTime.fromMillisecondsSinceEpoch(
              int.parse(dateValue['\$date']['\$numberLong']),
              isUtc: true,
            );
          }
        }
      } catch (e) {
        print('Error parsing date: $e');
      }
      return DateTime.now().toUtc();
    }

    return BusyTimeSlot(
      id: id,
      startTime: parseDate(json['startTime']),
      endTime: parseDate(json['endTime']),
      isAllDay: json['isAllDay'] as bool? ?? false,
      createdAt: parseDate(json['createdAt']),
      updatedAt: parseDate(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    // Send UTC ISO8601 strings to API
    return {
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'isAllDay': isAllDay,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
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
    return DateFormat('HH:mm').format(startTime.toLocal());
  }

  String get formattedEndTime {
    if (isAllDay) return 'All Day';
    return DateFormat('HH:mm').format(endTime.toLocal());
  }

  // Get a local DateTime version for UI display
  DateTime get localStartTime => startTime.toLocal();
  DateTime get localEndTime => endTime.toLocal();

  // Helper to check if a time slot is for today
  bool get isToday {
    final now = DateTime.now();
    final localStart = startTime.toLocal();
    return localStart.year == now.year &&
        localStart.month == now.month &&
        localStart.day == now.day;
  }

  // Helper to check if a time slot is in the past
  bool get isPast {
    return startTime.isBefore(DateTime.now().toUtc());
  }
}
