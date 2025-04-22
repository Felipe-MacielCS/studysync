import 'package:flutter/material.dart';
import 'package:googleapis/calendar/v3.dart' as calendar;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth.dart';

class TodoPage extends StatefulWidget {
  const TodoPage({super.key});

  @override
  _TodoPageState createState() => _TodoPageState();
}

class _TodoPageState extends State<TodoPage> {
  bool _hideCompletedTasks = false;
  List<calendar.Event> _tasks = [];
  List<calendar.CalendarListEntry> _calendars = [];
  String? _selectedCalendarId;
  String _selectedRange = 'Daily';
  bool _isLoading = true;
  Map<String, bool> _completedTasks = {};

  @override
  void initState() {
    super.initState();
    _loadCalendars();
    _loadCompletedTasks();
  }

  Future<void> _loadCompletedTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final completedTaskIds = prefs.getStringList('completed_tasks') ?? [];
    setState(() {
      for (var id in completedTaskIds) {
        _completedTasks[id] = true;
      }
    });
  }

  Future<void> _saveCompletedTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final completedTaskIds = _completedTasks.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();
    await prefs.setStringList('completed_tasks', completedTaskIds);
  }

  Future<void> _loadCalendars() async {
    print('Loading calendars...');
    final calendars = await getUserCalendars();
    print('Found ${calendars.length} calendars');
    
    // Debug: Print all available calendars
    for (var cal in calendars) {
      print('Calendar: ${cal.summary} (ID: ${cal.id})');
    }

    setState(() {
      _calendars = calendars;
      
      // First try to find the OCU calendar
      var selectedCalendar = calendars.firstWhere(
        (calendar) => calendar.summary?.contains('Oklahoma Christian University') ?? false,
        orElse: () => calendars.firstWhere(
          (calendar) => calendar.primary ?? false,  // Then try to find primary calendar
          orElse: () => calendars.isNotEmpty ? calendars.first : calendar.CalendarListEntry(),
        ),
      );

      _selectedCalendarId = selectedCalendar.id;
      print('Selected calendar: ${selectedCalendar.summary} (ID: ${_selectedCalendarId})');
    });
    
    await _fetchTasks();
  }

  Future<void> _fetchTasks() async {
    if (_selectedCalendarId == null) return;
    setState(() => _isLoading = true);

    final tasks = await getEvents(_selectedCalendarId!, _selectedRange);
    setState(() {
      _tasks = tasks;
      _isLoading = false;
    });
  }

  void _toggleTaskCompletion(String taskId) async {
    print('Toggling completion for task: $taskId');
    try {
      final task = _tasks.firstWhere(
        (t) => t.id == taskId,
        orElse: () => throw Exception('Task not found'),
      );

      final currentStatus = _completedTasks[taskId] ?? false;
      final newStatus = !currentStatus;

      setState(() {
        _completedTasks[taskId] = newStatus;
      });

      await _saveCompletedTasks();
    } catch (e) {
      print('Error: Task not found in _tasks list');
    }
  }

  Future<bool> _deleteEventFromCalendar(String eventId) async {
    print('Attempting to delete event: $eventId');
    
    if (_selectedCalendarId == null) {
      print('No calendar selected');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No calendar selected')),
      );
      return false;
    }
    print('Using calendar ID: $_selectedCalendarId');

    final authClient = await getAuthClient();
    if (authClient == null) {
      print('Failed to get auth client');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Not signed in to Google Calendar')),
      );
      return false;
    }
    print('Successfully obtained auth client');

    try {
      print('Creating Calendar API instance...');
      final calendarApi = calendar.CalendarApi(authClient);
      
      // First verify the event exists
      try {
        print('Verifying event exists...');
        final event = await calendarApi.events.get(_selectedCalendarId!, eventId);
        print('Found event: ${event.summary} (ID: ${event.id})');
      } catch (e) {
        print('Event not found: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Event not found in calendar')),
        );
        return false;
      }
      
      print('Attempting to delete event from calendar...');
      await calendarApi.events.delete(_selectedCalendarId!, eventId);
      print('Successfully deleted event from calendar');
      return true;
    } catch (e, stackTrace) {
      print('Error deleting event: $e');
      print('Stack trace: $stackTrace');
      
      String errorMessage = 'Failed to delete task';
      
      if (e.toString().contains('404')) {
        errorMessage = 'Event not found in calendar';
        print('Event not found in calendar. It may have been already deleted.');
      } else if (e.toString().contains('403')) {
        errorMessage = 'Permission denied - Cannot delete this event';
        print('Permission denied. You may not have rights to delete this event.');
      } else {
        print('Unknown error occurred while deleting event');
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Filter tasks if hide completed is enabled
    final displayedTasks = _hideCompletedTasks
        ? _tasks.where((task) => !(_completedTasks[task.id] ?? false)).toList()
        : _tasks;

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'To-Do Tasks',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                // Hide completed tasks toggle
                IconButton(
                  icon: Icon(
                    _hideCompletedTasks ? Icons.visibility_off : Icons.visibility,
                    color: Colors.grey,
                  ),
                  onPressed: () {
                    setState(() {
                      _hideCompletedTasks = !_hideCompletedTasks;
                    });
                  },
                  tooltip: _hideCompletedTasks
                      ? 'Show completed tasks'
                      : 'Hide completed tasks',
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                      _fetchTasks();
                    },
                  ),
                ),
                const SizedBox(width: 16),
                DropdownButton<String>(
                  value: _selectedRange,
                  items: ['Daily', 'Weekly', 'All'].map((range) {
                    return DropdownMenuItem(
                      value: range,
                      child: Text(range),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _selectedRange = value!);
                    _fetchTasks();
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _tasks.isEmpty
                    ? const Center(child: Text('No tasks found.'))
                    : ListView.builder(
                      shrinkWrap: true,
                      itemCount: displayedTasks.length,
                      itemBuilder: (context, index) {
                        final task = displayedTasks[index];
                        final taskId = task.id ?? '';
                        final isCompleted = _completedTasks[taskId] ?? false;

                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                          child: CheckboxListTile(
                            title: Text(
                              task.summary ?? 'No Title',
                              style: TextStyle(
                                decoration: isCompleted ? TextDecoration.lineThrough : null,
                                color: isCompleted ? Colors.grey : Colors.black,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  task.start?.dateTime != null
                                      ? 'Due: ${DateFormat('EEE, MMM d • h:mm a').format(task.start!.dateTime!.toLocal())}'
                                      : 'No due date',
                                ),
                                if (task.description != null && task.description!.isNotEmpty)
                                  Text(
                                    task.description!,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                              ],
                            ),
                            value: isCompleted,
                            onChanged: (_) => _toggleTaskCompletion(taskId),
                            activeColor: Colors.black,
                            checkColor: Colors.white,
                            controlAffinity: ListTileControlAffinity.leading,
                            secondary: Icon(
                              _getIconForTask(task),
                              color: _completedTasks[taskId] ?? false ? Colors.grey : Colors.black,
                            ),
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }

  IconData _getIconForTask(calendar.Event task) {
    final title = task.summary?.toLowerCase() ?? '';
    if (title.contains('homework') || title.contains('hw')) {
      return Icons.assignment;
    } else if (title.contains('project')) {
      return Icons.engineering;
    } else if (title.contains('exam') || title.contains('quiz') || title.contains('test')) {
      return Icons.school;
    } else if (title.contains('meeting')) {
      return Icons.people;
    } else {
      return Icons.event_note;
    }
  }

  Future<List<calendar.CalendarListEntry>> getUserCalendars() async {
    final authClient = await getAuthClient();
    if (authClient == null) return [];

    final calendarApi = calendar.CalendarApi(authClient);
    final list = await calendarApi.calendarList.list();
    return list.items ?? [];
  }

  Future<List<calendar.Event>> getEvents(String calendarId, String range) async {
    final authClient = await getAuthClient();
    if (authClient == null) return [];

    final calendarApi = calendar.CalendarApi(authClient);
    final now = DateTime.now().toUtc();
    late DateTime? timeMax;

    switch (range) {
      case 'Daily':
        timeMax = now.add(const Duration(days: 1));
        break;
      case 'Weekly':
        timeMax = now.add(const Duration(days: 7));
        break;
      case 'All':
        timeMax = null;
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
      maxResults: 100,
    );

    return (events.items ?? []).where((event) => event.status == 'confirmed').toList();
  }
}
