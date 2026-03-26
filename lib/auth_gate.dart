import 'package:flutter/material.dart';

import 'core/auth_service.dart';
import 'get_started_page.dart';
import 'store_home_page.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: AuthService.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData) {
          return const StoreHomePage();
        }

        return const GetStartedPage();
      },
    );
  }
}
