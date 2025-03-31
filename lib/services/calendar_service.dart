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

  // Create a new busy time slot
  Future<BusyTimeSlot> createBusyTimeSlot(BusyTimeSlot timeSlot) async {
    try {
      final url = Uri.parse('$apiFullUrl$busyTimeSlotsEndpoint');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(timeSlot.toJson()),
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
      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(timeSlot.toJson()),
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
      final startStr = start.toIso8601String();
      final endStr = end.toIso8601String();

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
}
