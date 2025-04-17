import 'package:flutter/material.dart';
import 'package:googleapis/calendar/v3.dart';
import 'package:study_sync/services/calendar_service.dart';
import 'package:study_sync/services/auth.dart';
import 'package:intl/intl.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  _CalendarPageState createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  List<Event> _events = [];
  List<CalendarListEntry> _calendars = [];
  String? _selectedCalendarId;
  String _selectedRange = 'Daily';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCalendars();
  }

  Future<void> _loadCalendars() async {
    final calendars = await getUserCalendars();
    setState(() {
      _calendars = calendars;
      _selectedCalendarId = calendars.isNotEmpty ? calendars.first.id : null;
    });
    _fetchEvents();
  }

  Future<void> _fetchEvents() async {
    if (_selectedCalendarId == null) return;
    setState(() => _isLoading = true);

    final events = await getEvents(_selectedCalendarId!, _selectedRange);
    setState(() {
      _events = events;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Google Calendar Events')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButton<String>(
                    value: _selectedCalendarId,
                    isExpanded: true,
                    hint: const Text('Select Calendar'),
                    items: _calendars.map((calendar) {
                      return DropdownMenuItem(
                        value: calendar.id,
                        child: Text(calendar.summary ?? 'Unnamed'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _selectedCalendarId = value);
                      _fetchEvents();
                    },
                  ),
                ),
                const SizedBox(width: 16),
                DropdownButton<String>(
                  value: _selectedRange,
                  items: ['Daily', 'Weekly', 'Monthly'].map((range) {
                    return DropdownMenuItem(
                      value: range,
                      child: Text(range),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _selectedRange = value!);
                    _fetchEvents();
                  },
                )
              ],
            ),
          ),
          Expanded(
            child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _events.isEmpty
                ? const Center(child: Text('No events found.'))
                : ListView.builder(
                    itemCount: _events.length,
                    itemBuilder: (context, index) {
                      final event = _events[index];
                      return ListTile(
                        title: Text(event.summary ?? 'No Title'),
                        subtitle: Text(
                          event.start?.dateTime != null
                              ? DateFormat('EEEE, MMM d • h:mm a')
                                  .format(event.start!.dateTime!.toLocal())
                              : 'No Date',
                        ),
                      );
                    },
                  ),
          )
        ],
      ),
    );
  }
  
  Future<List<CalendarListEntry>> getUserCalendars() async {
    final authClient = await getAuthClient();
    if (authClient == null) return [];

    final calendarApi = CalendarApi(authClient);
    final list = await calendarApi.calendarList.list();
    return list.items ?? [];
  }

  Future<List<Event>> getEvents(String calendarId, String range) async {
    final authClient = await getAuthClient();
    if (authClient == null) return [];

    final calendarApi = CalendarApi(authClient);

    final now = DateTime.now().toUtc();
    late DateTime timeMax;

    switch (range) {
      case 'Daily':
        timeMax = now.add(const Duration(days: 1));
        break;
      case 'Weekly':
        timeMax = now.add(const Duration(days: 7));
        break;
      case 'Monthly':
        timeMax = DateTime(now.year, now.month + 1, now.day);
        break;
      default:
        timeMax = now.add(const Duration(days: 1));
    }

    final events = await calendarApi.events.list(
      calendarId,
      timeMin: now,
      timeMax: timeMax,
      singleEvents: true,
      orderBy: 'startTime',
    );

    return (events.items ?? []).where((event) =>
      event.start?.dateTime != null &&
      event.status == 'confirmed'
    ).toList();
}
}