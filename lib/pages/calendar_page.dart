import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../services/calendar_service.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  List<Map<String, dynamic>> events = [];
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    loadEvents();
  }

  Future<void> loadEvents() async {
    try {
      final googleUser = await GoogleSignIn().signInSilently();
      final accessToken = (await googleUser?.authentication)?.accessToken;
      if (accessToken == null) {
        setState(() {
          error = 'Access token missing';
          isLoading = false;
        });
        return;
      }

      final fetchedEvents = await fetchCalendarEvents(accessToken);
      setState(() {
        events = fetchedEvents;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (error != null) {
      return Center(child: Text('Error: $error'));
    }

    if (events.isEmpty) {
      return const Center(child: Text('No events found.'));
    }

    return ListView.builder(
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        final summary = event['summary'] ?? 'No title';
        final start = event['start']?['dateTime'] ?? event['start']?['date'] ?? 'No start time';

        return ListTile(
          title: Text(summary),
          subtitle: Text(start),
          leading: const Icon(Icons.event),
        );
      },
    );
  }
}
