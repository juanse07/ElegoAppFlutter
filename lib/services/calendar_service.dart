import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/calendar_model.dart';

class CalendarService {
  static const String apiBaseUrl = 'api.elegoprime.com';
  static const String apiFullUrl = 'https://$apiBaseUrl';
  static const String busyTimeSlotsEndpoint = '/busy-time-slots';

  // Get all busy time slots for the user
  Future<List<BusyTimeSlot>> getBusyTimeSlots() async {
    try {
      final url = Uri.parse('$apiFullUrl$busyTimeSlotsEndpoint');

      final response = await http.get(url);

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to load busy time slots: HTTP ${response.statusCode}',
        );
      }

      final List<dynamic> jsonData = jsonDecode(response.body);

      // Convert each JSON object to a BusyTimeSlot
      final List<BusyTimeSlot> timeSlots =
          jsonData.map((json) => BusyTimeSlot.fromJson(json)).toList();

      // Sort by start time
      timeSlots.sort((a, b) => a.startTime.compareTo(b.startTime));

      return timeSlots;
    } catch (e) {
      print('Exception during getBusyTimeSlots: $e');
      rethrow;
    }
  }

  // Mark time slot as unavailable
  Future<BusyTimeSlot> markUnavailable(
    DateTime startTime,
    DateTime endTime, {
    bool isAllDay = false,
  }) async {
    try {
      final url = Uri.parse('$apiFullUrl$busyTimeSlotsEndpoint');

      // Convert to UTC for storage
      final startUtc = startTime.isUtc ? startTime : startTime.toUtc();
      final endUtc = endTime.isUtc ? endTime : endTime.toUtc();

      // For all-day events, set the time to start of day and end of day
      final startDateTime =
          isAllDay
              ? DateTime(startUtc.year, startUtc.month, startUtc.day).toUtc()
              : startUtc;
      final endDateTime =
          isAllDay
              ? DateTime(
                endUtc.year,
                endUtc.month,
                endUtc.day,
                23,
                59,
                59,
              ).toUtc()
              : endUtc;

      final timeSlot = BusyTimeSlot(
        id: '', // ID will be assigned by the server
        startTime: startDateTime,
        endTime: endDateTime,
        isAllDay: isAllDay,
        createdAt: DateTime.now().toUtc(),
        updatedAt: DateTime.now().toUtc(),
      );

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(timeSlot.toJson()),
      );

      if (response.statusCode != 201) {
        throw Exception(
          'Failed to mark time as unavailable: HTTP ${response.statusCode}',
        );
      }

      return BusyTimeSlot.fromJson(jsonDecode(response.body));
    } catch (e) {
      print('Exception during markUnavailable: $e');
      rethrow;
    }
  }

  // Mark entire day as unavailable
  Future<BusyTimeSlot> markDayUnavailable(DateTime date) async {
    return markUnavailable(date, date, isAllDay: true);
  }

  // Delete a busy time slot (mark as available)
  Future<void> markAvailable(String id) async {
    try {
      final url = Uri.parse('$apiFullUrl$busyTimeSlotsEndpoint/$id');
      final response = await http.delete(url);

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception(
          'Failed to mark time as available: HTTP ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Exception during markAvailable: $e');
      rethrow;
    }
  }

  // Get busy time slots for a specific date range
  Future<List<BusyTimeSlot>> getBusyTimeSlotsForRange(
    DateTime start,
    DateTime end,
  ) async {
    try {
      // Convert any local dates to UTC for API
      final startUtc = start.isUtc ? start : start.toUtc();
      final endUtc = end.isUtc ? end : end.toUtc();

      final startStr = startUtc.toIso8601String();
      final endStr = endUtc.toIso8601String();

      final url = Uri.parse(
        '$apiFullUrl$busyTimeSlotsEndpoint?startTime=$startStr&endTime=$endStr',
      );

      final response = await http.get(url);

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to load busy time slots for range: HTTP ${response.statusCode}',
        );
      }

      final List<dynamic> jsonData = jsonDecode(response.body);

      final List<BusyTimeSlot> timeSlots =
          jsonData.map((json) => BusyTimeSlot.fromJson(json)).toList();

      // Sort by start time
      timeSlots.sort((a, b) => a.startTime.compareTo(b.startTime));

      return timeSlots;
    } catch (e) {
      print('Exception during getBusyTimeSlotsForRange: $e');
      rethrow;
    }
  }

  // Get busy time slots for a specific date
  Future<List<BusyTimeSlot>> getBusyTimeSlotsForDate(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);
    return getBusyTimeSlotsForRange(startOfDay, endOfDay);
  }

  // Helper method to format date for API requests
  String formatDateForApi(DateTime date) {
    final dateUtc = date.isUtc ? date : date.toUtc();
    return dateUtc.toIso8601String();
  }
}
