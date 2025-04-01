import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../models/calendar_model.dart';

class CalendarService {
  static String get baseUrl =>
      dotenv.env['API_URL'] ?? 'https://api.elegoprime.com';

  final DateFormat _apiDateFormat = DateFormat("yyyy-MM-dd'T'HH:mm:ss'Z'");

  // Helper method to convert local DateTime to UTC ISO8601 string
  String _formatDateForApi(DateTime dateTime) {
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
      print('Fetching busy time slots from: $baseUrl/busy-time-slots');
      final response = await http.get(Uri.parse('$baseUrl/busy-time-slots'));
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => BusyTimeSlot.fromJson(json)).toList()
          ..sort((a, b) => a.startTime.compareTo(b.startTime));
      } else {
        throw Exception(
          'Failed to load busy time slots: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('Error in getBusyTimeSlots: $e');
      rethrow;
    }
  }

  Future<BusyTimeSlot> markUnavailable(
    DateTime startTime,
    DateTime endTime,
  ) async {
    try {
      print('Marking time as unavailable...');
      print('Start time: $startTime');
      print('End time: $endTime');

      final startTimeUtc = _formatDateForApi(startTime);
      final endTimeUtc = _formatDateForApi(endTime);

      print('Formatted start time: $startTimeUtc');
      print('Formatted end time: $endTimeUtc');
      print('Sending request to: $baseUrl/busy-time-slots');

      final response = await http.post(
        Uri.parse('$baseUrl/busy-time-slots'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'startTime': startTimeUtc,
          'endTime': endTimeUtc,
          'isAllDay': false,
          'title': 'Unavailable',
        }),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return BusyTimeSlot.fromJson(data);
      } else {
        throw Exception(
          'Failed to mark time as unavailable: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('Error in markUnavailable: $e');
      rethrow;
    }
  }

  Future<BusyTimeSlot> markDayUnavailable(DateTime date) async {
    try {
      print('Marking day as unavailable: $date');
      final startTime = DateTime.utc(date.year, date.month, date.day);
      final endTime = DateTime.utc(date.year, date.month, date.day, 23, 59, 59);

      print('Start time UTC: $startTime');
      print('End time UTC: $endTime');

      final response = await http.post(
        Uri.parse('$baseUrl/busy-time-slots'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'startTime': _apiDateFormat.format(startTime),
          'endTime': _apiDateFormat.format(endTime),
          'isAllDay': true,
          'title': 'Unavailable',
        }),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return BusyTimeSlot.fromJson(data);
      } else {
        throw Exception(
          'Failed to mark day as unavailable: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('Error in markDayUnavailable: $e');
      rethrow;
    }
  }

  Future<void> markAvailable(String id) async {
    try {
      print('Marking time slot available: $id');
      final response = await http.delete(
        Uri.parse('$baseUrl/busy-time-slots/$id'),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to mark time as available: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('Error in markAvailable: $e');
      rethrow;
    }
  }

  Future<List<BusyTimeSlot>> getBusyTimeSlotsForRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      print('Fetching busy time slots for range:');
      print('Start date: $startDate');
      print('End date: $endDate');

      final startTimeUtc = _formatDateForApi(startDate);
      final endTimeUtc = _formatDateForApi(endDate);

      print('Formatted start time: $startTimeUtc');
      print('Formatted end time: $endTimeUtc');

      final url =
          '$baseUrl/busy-time-slots?startTime=$startTimeUtc&endTime=$endTimeUtc';
      print('Request URL: $url');

      final response = await http.get(Uri.parse(url));

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => BusyTimeSlot.fromJson(json)).toList()
          ..sort((a, b) => a.startTime.compareTo(b.startTime));
      } else {
        throw Exception(
          'Failed to load busy time slots: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('Error in getBusyTimeSlotsForRange: $e');
      rethrow;
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
