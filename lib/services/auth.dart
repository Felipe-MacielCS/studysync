import 'package:googleapis_auth/auth.dart';
import 'package:googleapis/calendar/v3.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

/// Scopes for Google Calendar API
final _scopes = [
  'https://www.googleapis.com/auth/calendar',  // Full access to calendar
];

/// Returns an authenticated HTTP client
Future<AuthClient?> getAuthClient() async {
  final GoogleSignInAccount? googleUser = await GoogleSignIn(
    scopes: _scopes,
  ).signIn();

  if (googleUser == null) return null;

  final GoogleSignInAuthentication googleAuth =
      await googleUser.authentication;

  final AccessCredentials credentials = AccessCredentials(
    AccessToken(
      'Bearer',
      googleAuth.accessToken!,
      DateTime.now().toUtc().add(Duration(hours: 1)), // ✅ fixed to UTC
    ),
    null, // refresh token
    _scopes,
  );

  return authenticatedClient(http.Client(), credentials);
}
