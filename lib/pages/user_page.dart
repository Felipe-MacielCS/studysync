import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:study_sync/services/google_signin_service.dart';

class UserPage extends StatelessWidget {
  const UserPage({super.key});

  Future<GoogleSignInAccount?> _getUser() async {
    // Wait for silent sign-in if user already signed in previously
    return googleSignIn.currentUser ?? await googleSignIn.signInSilently();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("User Profile")),
      body: FutureBuilder<GoogleSignInAccount?>(
        future: _getUser(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final user = snapshot.data;

          if (user == null) {
            return const Center(child: Text('Not signed in'));
          }

          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  backgroundImage: NetworkImage(user.photoUrl ?? ''),
                  radius: 50,
                ),
                const SizedBox(height: 16),
                Text(user.displayName ?? 'No Name'),
                const SizedBox(height: 8),
                Text(user.email),
              ],
            ),
          );
        },
      ),
    );
  }
}
