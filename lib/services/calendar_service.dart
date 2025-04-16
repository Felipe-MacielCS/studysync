import 'dart:convert';
import 'package:http/http.dart' as http;

Future<List<Map<String, dynamic>>> fetchCalendarEvents(String accessToken) async {
  final response = await http.get(
    Uri.parse('https://www.googleapis.com/calendar/v3/calendars/primary/events'),
    headers: {
      'Authorization': 'Bearer $accessToken',
    },
  );

  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    final events = data['items'] as List;
    return events.cast<Map<String, dynamic>>();
  } else {
    throw Exception('Failed to load calendar events: ${response.statusCode}');
  }
}
