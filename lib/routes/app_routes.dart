import 'package:flutter/material.dart';
import '../presentation/screens/auth/login_screen.dart';
import '../presentation/screens/auth/setup_screen.dart';
import '../presentation/screens/dashboard/dashboard_proprietaire_screen.dart';
import '../presentation/screens/dashboard/dashboard_secretaire_screen.dart';

class AppRoutes {
  static const String setup = '/setup';
  static const String login = '/login';
  static const String dashboardProprietaire = '/dashboard-proprietaire';
  static const String dashboardSecretaire = '/dashboard-secretaire';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case setup:
        return MaterialPageRoute(builder: (_) => const SetupScreen());

      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());

      case dashboardProprietaire:
        return MaterialPageRoute(builder: (_) => const DashboardProprietaireScreen());

      case dashboardSecretaire:
        return MaterialPageRoute(builder: (_) => const DashboardSecretaireScreen());

      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text("Route inconnue: ${settings.name}")),
          ),
        );
    }
  }
}