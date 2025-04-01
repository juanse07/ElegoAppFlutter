import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../models/calendar_model.dart';

class CalendarService {
  static const String baseUrl = 'http://localhost:3000/api/calendar';
  final DateFormat _apiDateFormat = DateFormat("yyyy-MM-dd'T'HH:mm:ss'Z'");

  // Helper method to convert local DateTime to UTC ISO8601 string
  String _formatDateForApi(DateTime dateTime) {
    // Convert to UTC and format as ISO8601
    final utcDateTime = dateTime.toUtc();
    return _apiDateFormat.format(utcDateTime);
  }

  // Helper method to parse UTC ISO8601 string to local DateTime
  DateTime _parseApiDate(String dateString) {
    // Parse UTC date and convert to local time
    final utcDateTime = _apiDateFormat.parse(dateString);
    return utcDateTime.toLocal();
  }

  Future<List<BusyTimeSlot>> getBusyTimeSlots() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/busy-slots'));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => BusyTimeSlot.fromJson(json)).toList()
          ..sort((a, b) => a.startTime.compareTo(b.startTime));
      } else {
        throw Exception(
          'Failed to load busy time slots: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Failed to load busy time slots: $e');
    }
  }

  Future<BusyTimeSlot> markUnavailable(
    DateTime startTime,
    DateTime endTime,
  ) async {
    try {
      // Convert local times to UTC ISO8601 strings
      final startTimeUtc = _formatDateForApi(startTime);
      final endTimeUtc = _formatDateForApi(endTime);

      final response = await http.post(
        Uri.parse('$baseUrl/busy-slots'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'startTime': startTimeUtc,
          'endTime': endTimeUtc,
          'isAllDay': false,
        }),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return BusyTimeSlot.fromJson(data);
      } else {
        throw Exception(
          'Failed to mark time as unavailable: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Failed to mark time as unavailable: $e');
    }
  }

  Future<BusyTimeSlot> markDayUnavailable(DateTime date) async {
    try {
      // Create start and end times for the entire day in UTC
      final startTime = DateTime.utc(date.year, date.month, date.day);
      final endTime = DateTime.utc(date.year, date.month, date.day, 23, 59, 59);

      final response = await http.post(
        Uri.parse('$baseUrl/busy-slots'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'startTime': _apiDateFormat.format(startTime),
          'endTime': _apiDateFormat.format(endTime),
          'isAllDay': true,
        }),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return BusyTimeSlot.fromJson(data);
      } else {
        throw Exception(
          'Failed to mark day as unavailable: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Failed to mark day as unavailable: $e');
    }
  }

  Future<void> markAvailable(String id) async {
    try {
      final response = await http.delete(Uri.parse('$baseUrl/busy-slots/$id'));

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to mark time as available: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Failed to mark time as available: $e');
    }
  }

  Future<List<BusyTimeSlot>> getBusyTimeSlotsForRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      // Convert local dates to UTC ISO8601 strings
      final startDateUtc = _formatDateForApi(startDate);
      final endDateUtc = _formatDateForApi(endDate);

      final response = await http.get(
        Uri.parse(
          '$baseUrl/busy-slots?startDate=$startDateUtc&endDate=$endDateUtc',
        ),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => BusyTimeSlot.fromJson(json)).toList()
          ..sort((a, b) => a.startTime.compareTo(b.startTime));
      } else {
        throw Exception(
          'Failed to load busy time slots: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Failed to load busy time slots: $e');
    }
  }

  Future<List<BusyTimeSlot>> getBusyTimeSlotsForDate(DateTime date) async {
    try {
      // Get the start and end of the day in UTC
      final startOfDay = DateTime.utc(date.year, date.month, date.day);
      final endOfDay = DateTime.utc(
        date.year,
        date.month,
        date.day,
        23,
        59,
        59,
      );

      return getBusyTimeSlotsForRange(startOfDay, endOfDay);
    } catch (e) {
      throw Exception('Failed to load busy time slots for date: $e');
    }
  }
}
