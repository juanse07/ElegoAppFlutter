import 'package:intl/intl.dart';

class BusyTimeSlot {
  final String id;
  final DateTime startTime;
  final DateTime endTime;
  final String title;
  final String description;
  final DateTime createdAt;
  final DateTime updatedAt;

  BusyTimeSlot({
    required this.id,
    required this.startTime,
    required this.endTime,
    required this.title,
    this.description = '',
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

    // Parse dates correctly
    DateTime parseDate(dynamic dateValue) {
      if (dateValue == null) return DateTime.now();

      try {
        if (dateValue is String) {
          return DateTime.parse(dateValue).toLocal();
        } else if (dateValue is Map && dateValue['\$date'] != null) {
          if (dateValue['\$date'] is String) {
            return DateTime.parse(dateValue['\$date']).toLocal();
          } else if (dateValue['\$date'] is Map &&
              dateValue['\$date']['\$numberLong'] != null) {
            return DateTime.fromMillisecondsSinceEpoch(
              int.parse(dateValue['\$date']['\$numberLong']),
              isUtc: true,
            ).toLocal();
          }
        }
      } catch (e) {
        print('Error parsing date: $e');
      }
      return DateTime.now();
    }

    return BusyTimeSlot(
      id: id,
      startTime: parseDate(json['startTime']),
      endTime: parseDate(json['endTime']),
      title: json['title'] as String? ?? 'Busy',
      description: json['description'] as String? ?? '',
      createdAt: parseDate(json['createdAt']),
      updatedAt: parseDate(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    // Convert local time to UTC for consistent API communication
    return {
      'startTime': startTime.toUtc().toIso8601String(),
      'endTime': endTime.toUtc().toIso8601String(),
      'title': title,
      'description': description,
      'createdAt': createdAt.toUtc().toIso8601String(),
      'updatedAt': updatedAt.toUtc().toIso8601String(),
    };
  }

  // Helper method for formatting date and time for display
  String formatStartTime(String format) {
    final formatter = DateFormat(format);
    return formatter.format(startTime);
  }

  // Helper method for formatting date and time for display
  String formatEndTime(String format) {
    final formatter = DateFormat(format);
    return formatter.format(endTime);
  }

  // Format just the date portion
  String get formattedDate {
    return DateFormat('yyyy-MM-dd').format(startTime);
  }

  // Format just the time portion
  String get formattedStartTime {
    return DateFormat('HH:mm').format(startTime);
  }

  String get formattedEndTime {
    return DateFormat('HH:mm').format(endTime);
  }
}
