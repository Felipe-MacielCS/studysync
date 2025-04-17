import 'package:flutter/material.dart';
import 'package:googleapis/calendar/v3.dart';
import 'package:study_sync/services/calendar_service.dart';

class CalendarPage extends StatefulWidget {
  @override
  _CalendarPageState createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  final _calendarService = CalendarService();
  List<Event> _events = [];

  @override
  void initState() {
    super.initState();
    _fetchEvents();
  }

Future<void> _fetchEvents() async {
  try {
    final events = await _calendarService.getEvents();
    print('Fetched events: ${events.length}'); // Log the number of events
    for (var event in events) {
      print('Event: ${event.summary} at ${event.start?.dateTime}');
    }

    setState(() {
      _events = events;
    });
  } catch (e) {
    print('Error fetching events: $e');
    setState(() {
      _events = []; // prevent endless spinner if error happens
    });
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Google Calendar Events')),
      body: _events.isEmpty
        ? const Center(child: Text('No events found or still loading...'))
        : ListView.builder(
        itemCount: _events.length,
        itemBuilder: (context, index) {
          final event = _events[index];
          return ListTile(
            title: Text(event.summary ?? 'No Title'),
            subtitle: Text(event.start?.dateTime?.toString() ?? 'No Date'),
          );
        },
      ),
    );
  }
}
