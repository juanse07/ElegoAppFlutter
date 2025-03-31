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

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  List<BusyTimeSlot> _busyTimeSlots = [];
  bool _isLoading = true;

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
    _titleController.dispose();
    _descriptionController.dispose();
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
      return slot.startTime.year == day.year &&
          slot.startTime.month == day.month &&
          slot.startTime.day == day.day;
    }).toList();
  }

  Future<void> _addTimeSlot() async {
    if (_titleController.text.isEmpty) {
      _showErrorSnackBar('Please enter a title');
      return;
    }

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

    // Create a temporary ID that will be replaced by the server
    const tempId = 'temp';

    // Create a new busy time slot
    final newSlot = BusyTimeSlot(
      id: tempId,
      startTime: startDateTime,
      endTime: endDateTime,
      title: _titleController.text,
      description: _descriptionController.text,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    try {
      // Show loading indicator
      setState(() {
        _isLoading = true;
      });

      // Send request to server
      final createdSlot = await _calendarService.createBusyTimeSlot(newSlot);

      // Update state
      setState(() {
        _busyTimeSlots.add(createdSlot);
        _isLoading = false;
      });

      // Clear input fields
      _titleController.clear();
      _descriptionController.clear();

      // Close the add time slot dialog
      Navigator.of(context).pop();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      _showErrorSnackBar('Failed to create busy time slot: $e');
    }
  }

  Future<void> _deleteTimeSlot(BusyTimeSlot timeSlot) async {
    try {
      setState(() {
        _isLoading = true;
      });

      await _calendarService.deleteBusyTimeSlot(timeSlot.id);

      setState(() {
        _busyTimeSlots.removeWhere((slot) => slot.id == timeSlot.id);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      _showErrorSnackBar('Failed to delete busy time slot: $e');
    }
  }

  Future<void> _selectStartTime() async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: _startTime,
    );

    if (pickedTime != null) {
      setState(() {
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

  Future<void> _selectEndTime() async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: _endTime,
    );

    if (pickedTime != null) {
      setState(() {
        _endTime = pickedTime;
      });
    }
  }

  void _showAddTimeSlotDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Add Busy Time Slot'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Selected Date: ${DateFormat('yyyy-MM-dd').format(_selectedDay)}',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      labelText: 'Title',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _descriptionController,
                    decoration: InputDecoration(
                      labelText: 'Description (Optional)',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ListTile(
                          title: Text('Start Time'),
                          subtitle: Text(_startTime.format(context)),
                          onTap: _selectStartTime,
                        ),
                      ),
                      Expanded(
                        child: ListTile(
                          title: Text('End Time'),
                          subtitle: Text(_endTime.format(context)),
                          onTap: _selectEndTime,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Cancel'),
              ),
              ElevatedButton(onPressed: _addTimeSlot, child: Text('Add')),
            ],
          ),
    );
  }

  Widget _buildTimeSlotDetails(BusyTimeSlot timeSlot) {
    final startTimeStr = DateFormat('h:mm a').format(timeSlot.startTime);
    final endTimeStr = DateFormat('h:mm a').format(timeSlot.endTime);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: ListTile(
        title: Text(timeSlot.title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$startTimeStr - $endTimeStr'),
            if (timeSlot.description.isNotEmpty)
              Text(timeSlot.description, style: TextStyle(fontSize: 12)),
          ],
        ),
        trailing: IconButton(
          icon: Icon(Icons.delete),
          onPressed: () => _deleteTimeSlot(timeSlot),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Manage Availability')),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                child: Column(
                  children: [
                    TableCalendar(
                      firstDay: DateTime.utc(2023, 1, 1),
                      lastDay: DateTime.utc(2030, 12, 31),
                      focusedDay: _focusedDay,
                      calendarFormat: _calendarFormat,
                      selectedDayPredicate: (day) {
                        return isSameDay(_selectedDay, day);
                      },
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
                        setState(() {
                          _focusedDay = focusedDay;
                        });

                        // Reload busy time slots for the new month
                        _loadBusyTimeSlots();
                      },
                      eventLoader: _getEventsForDay,
                      calendarStyle: CalendarStyle(
                        markerDecoration: BoxDecoration(
                          color: Theme.of(context).primaryColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    const Divider(),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        'Busy Time Slots for ${DateFormat('yyyy-MM-dd').format(_selectedDay)}',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: _getEventsForDay(_selectedDay).length,
                      itemBuilder: (context, index) {
                        return _buildTimeSlotDetails(
                          _getEventsForDay(_selectedDay)[index],
                        );
                      },
                    ),
                  ],
                ),
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTimeSlotDialog,
        tooltip: 'Add Busy Time Slot',
        child: Icon(Icons.add),
      ),
    );
  }
}
