import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../models/calendar_model.dart';
import '../services/calendar_service.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  _CalendarScreenState createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late CalendarService _calendarService;
  late CalendarFormat _calendarFormat;
  late DateTime _focusedDay;
  late DateTime _selectedDay;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;

  List<BusyTimeSlot> _busyTimeSlots = [];
  bool _isLoading = true;
  bool _isAllDay = false;

  @override
  void initState() {
    super.initState();
    _calendarService = CalendarService();
    _calendarFormat = CalendarFormat.month;
    _focusedDay = DateTime.now();
    _selectedDay = DateTime.now();
    _startTime = TimeOfDay.now();
    _endTime = TimeOfDay(hour: TimeOfDay.now().hour + 1, minute: 0);

    _loadBusyTimeSlots();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadBusyTimeSlots() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get the first and last day of the month
      final firstDay = DateTime(_focusedDay.year, _focusedDay.month, 1);
      final lastDay = DateTime(_focusedDay.year, _focusedDay.month + 1, 0);

      final timeSlots = await _calendarService.getBusyTimeSlotsForRange(
        firstDay,
        lastDay,
      );

      setState(() {
        _busyTimeSlots = timeSlots;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      _showErrorSnackBar('Failed to load busy time slots: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  List<BusyTimeSlot> _getEventsForDay(DateTime day) {
    return _busyTimeSlots.where((slot) {
      final localStart = slot.startTime.toLocal();
      return localStart.year == day.year &&
          localStart.month == day.month &&
          localStart.day == day.day;
    }).toList();
  }

  Future<void> _markTimeUnavailable() async {
    if (!_isAllDay) {
      // Create start and end DateTime objects from selected day and time
      final startDateTime = DateTime(
        _selectedDay.year,
        _selectedDay.month,
        _selectedDay.day,
        _startTime.hour,
        _startTime.minute,
      );

      final endDateTime = DateTime(
        _selectedDay.year,
        _selectedDay.month,
        _selectedDay.day,
        _endTime.hour,
        _endTime.minute,
      );

      if (endDateTime.isBefore(startDateTime)) {
        _showErrorSnackBar('End time must be after start time');
        return;
      }
    }

    try {
      // Show loading indicator
      setState(() {
        _isLoading = true;
      });

      // Send request to server
      final createdSlot =
          _isAllDay
              ? await _calendarService.markDayUnavailable(_selectedDay)
              : await _calendarService.markUnavailable(
                DateTime(
                  _selectedDay.year,
                  _selectedDay.month,
                  _selectedDay.day,
                  _startTime.hour,
                  _startTime.minute,
                ),
                DateTime(
                  _selectedDay.year,
                  _selectedDay.month,
                  _selectedDay.day,
                  _endTime.hour,
                  _endTime.minute,
                ),
              );

      // Update state
      setState(() {
        _busyTimeSlots.add(createdSlot);
        _isLoading = false;
      });

      // Close the dialog
      Navigator.of(context).pop();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      _showErrorSnackBar('Failed to mark time as unavailable: $e');
    }
  }

  Future<void> _markTimeAvailable(BusyTimeSlot timeSlot) async {
    try {
      setState(() {
        _isLoading = true;
      });

      await _calendarService.markAvailable(timeSlot.id);

      setState(() {
        _busyTimeSlots.removeWhere((slot) => slot.id == timeSlot.id);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      _showErrorSnackBar('Failed to mark time as available: $e');
    }
  }

  Future<void> _selectStartTime(
    BuildContext dialogContext,
    StateSetter dialogSetState,
  ) async {
    final pickedTime = await showTimePicker(
      context: dialogContext,
      initialTime: _startTime,
    );

    if (pickedTime != null) {
      dialogSetState(() {
        _startTime = pickedTime;

        // If end time is before start time, adjust it
        if (_endTime.hour < _startTime.hour ||
            (_endTime.hour == _startTime.hour &&
                _endTime.minute < _startTime.minute)) {
          _endTime = TimeOfDay(
            hour: _startTime.hour + 1,
            minute: _startTime.minute,
          );
        }
      });
    }
  }

  Future<void> _selectEndTime(
    BuildContext dialogContext,
    StateSetter dialogSetState,
  ) async {
    final pickedTime = await showTimePicker(
      context: dialogContext,
      initialTime: _endTime,
    );

    if (pickedTime != null) {
      dialogSetState(() {
        _endTime = pickedTime;
      });
    }
  }

  void _showMarkUnavailableDialog() {
    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, dialogSetState) => AlertDialog(
                  title: Text('Mark Time as Unavailable'),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Selected Date: ${DateFormat('yyyy-MM-dd').format(_selectedDay)}',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        SwitchListTile(
                          title: Text('All Day'),
                          value: _isAllDay,
                          onChanged: (value) {
                            dialogSetState(() {
                              _isAllDay = value;
                            });
                          },
                        ),
                        if (!_isAllDay) ...[
                          const SizedBox(height: 16),
                          ListTile(
                            title: Text(
                              'Start Time: ${_startTime.format(context)}',
                            ),
                            trailing: Icon(Icons.access_time),
                            onTap:
                                () => _selectStartTime(context, dialogSetState),
                          ),
                          ListTile(
                            title: Text(
                              'End Time: ${_endTime.format(context)}',
                            ),
                            trailing: Icon(Icons.access_time),
                            onTap:
                                () => _selectEndTime(context, dialogSetState),
                          ),
                        ],
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: _markTimeUnavailable,
                      child: Text('Mark Unavailable'),
                    ),
                  ],
                ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Calendar'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: _showMarkUnavailableDialog,
          ),
        ],
      ),
      body:
          _isLoading
              ? Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  TableCalendar(
                    firstDay: DateTime.utc(2020, 1, 1),
                    lastDay: DateTime.utc(2030, 12, 31),
                    focusedDay: _focusedDay,
                    calendarFormat: _calendarFormat,
                    selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                    onDaySelected: (selectedDay, focusedDay) {
                      setState(() {
                        _selectedDay = selectedDay;
                        _focusedDay = focusedDay;
                      });
                    },
                    onFormatChanged: (format) {
                      setState(() {
                        _calendarFormat = format;
                      });
                    },
                    onPageChanged: (focusedDay) {
                      _focusedDay = focusedDay;
                      _loadBusyTimeSlots();
                    },
                    eventLoader: _getEventsForDay,
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _getEventsForDay(_selectedDay).length,
                      itemBuilder: (context, index) {
                        final slot = _getEventsForDay(_selectedDay)[index];
                        return ListTile(
                          title: Text(BusyTimeSlot.defaultMessage),
                          subtitle: Text(
                            slot.isAllDay
                                ? 'All Day'
                                : '${slot.formattedStartTime} - ${slot.formattedEndTime}',
                          ),
                          trailing: IconButton(
                            icon: Icon(Icons.delete),
                            onPressed: () => _markTimeAvailable(slot),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
    );
  }
}
