import 'package:googleapis/calendar/v3.dart';
import 'auth.dart';

class CalendarService {
  Future<List<Event>> getEvents() async {
    final authClient = await getAuthClient();
    final calendar = CalendarApi(authClient!);
    final events = await calendar.events.list('primary');
    return events.items ?? [];
  }
}
