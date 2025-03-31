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
          return DateTime.parse(dateValue);
        } else if (dateValue is Map && dateValue['\$date'] != null) {
          if (dateValue['\$date'] is String) {
            return DateTime.parse(dateValue['\$date']);
          } else if (dateValue['\$date'] is Map &&
              dateValue['\$date']['\$numberLong'] != null) {
            return DateTime.fromMillisecondsSinceEpoch(
              int.parse(dateValue['\$date']['\$numberLong']),
            );
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
    return {
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'title': title,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
