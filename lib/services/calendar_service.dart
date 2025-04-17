import 'package:googleapis/calendar/v3.dart';
import 'package:study_sync/services/auth.dart';

class CalendarService {
  Future<List<CalendarListEntry>> getUserCalendars() async {
    final authClient = await getAuthClient();
    if (authClient == null) return [];

    final calendarApi = CalendarApi(authClient);
    final list = await calendarApi.calendarList.list();
    return list.items ?? [];
  }

  Future<List<Event>> getEvents(String calendarId) async {
    final authClient = await getAuthClient();
    if (authClient == null) return [];

    final calendarApi = CalendarApi(authClient);
    final events = await calendarApi.events.list(
      calendarId,
      timeMin: DateTime.now().toUtc(),
      singleEvents: true,
      orderBy: 'startTime',
    );

    return (events.items ?? []).where((event) =>
      event.start?.dateTime != null &&
      event.status == 'confirmed'
    ).toList();
  }
}
