import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

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

  // Create a new busy time slot
  Future<BusyTimeSlot> createBusyTimeSlot(BusyTimeSlot timeSlot) async {
    try {
      final url = Uri.parse('$apiFullUrl$busyTimeSlotsEndpoint');

      // Ensure all dates are properly formatted for the API
      final jsonBody = timeSlot.toJson();

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(jsonBody),
      );

      if (response.statusCode != 201) {
        throw Exception(
          'Failed to create busy time slot: HTTP ${response.statusCode}',
        );
      }

      return BusyTimeSlot.fromJson(jsonDecode(response.body));
    } catch (e) {
      print('Exception during createBusyTimeSlot: $e');
      rethrow;
    }
  }

  // Delete a busy time slot
  Future<void> deleteBusyTimeSlot(String id) async {
    try {
      final url = Uri.parse('$apiFullUrl$busyTimeSlotsEndpoint/$id');
      final response = await http.delete(url);

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception(
          'Failed to delete busy time slot: HTTP ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Exception during deleteBusyTimeSlot: $e');
      rethrow;
    }
  }

  // Update a busy time slot
  Future<BusyTimeSlot> updateBusyTimeSlot(
    String id,
    BusyTimeSlot timeSlot,
  ) async {
    try {
      final url = Uri.parse('$apiFullUrl$busyTimeSlotsEndpoint/$id');

      // Ensure all dates are properly formatted for the API
      final jsonBody = timeSlot.toJson();

      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(jsonBody),
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to update busy time slot: HTTP ${response.statusCode}',
        );
      }

      return BusyTimeSlot.fromJson(jsonDecode(response.body));
    } catch (e) {
      print('Exception during updateBusyTimeSlot: $e');
      rethrow;
    }
  }

  // Get busy time slots for a specific date range
  Future<List<BusyTimeSlot>> getBusyTimeSlotsForRange(
    DateTime start,
    DateTime end,
  ) async {
    try {
      // Ensure dates are in UTC ISO8601 format for the API
      final startStr = start.toUtc().toIso8601String();
      final endStr = end.toUtc().toIso8601String();

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

  // Helper method to format date for API requests
  String formatDateForApi(DateTime date) {
    return date.toUtc().toIso8601String();
  }

  // Create a new busy time slot with formatted date/time strings
  Future<BusyTimeSlot> createBusyTimeSlotWithStrings(
    String date,
    String startTime,
    String endTime,
    String title,
    String description,
  ) async {
    try {
      // Parse the input strings to a DateTime
      final DateFormat dateFormat = DateFormat('yyyy-MM-dd');
      final DateFormat timeFormat = DateFormat('HH:mm');

      final DateTime parsedDate = dateFormat.parse(date);

      // Parse start time and combine with date
      final DateTime parsedStartTime = timeFormat.parse(startTime);
      final DateTime startDateTime = DateTime(
        parsedDate.year,
        parsedDate.month,
        parsedDate.day,
        parsedStartTime.hour,
        parsedStartTime.minute,
      );

      // Parse end time and combine with date
      final DateTime parsedEndTime = timeFormat.parse(endTime);
      final DateTime endDateTime = DateTime(
        parsedDate.year,
        parsedDate.month,
        parsedDate.day,
        parsedEndTime.hour,
        parsedEndTime.minute,
      );

      // Create a BusyTimeSlot with the properly parsed dates
      final timeSlot = BusyTimeSlot(
        id: '', // ID will be assigned by the server
        startTime: startDateTime,
        endTime: endDateTime,
        title: title,
        description: description,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      return await createBusyTimeSlot(timeSlot);
    } catch (e) {
      print('Exception during createBusyTimeSlotWithStrings: $e');
      rethrow;
    }
  }
}
