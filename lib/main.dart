import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'core/services/auth_service.dart';
import 'core/services/sync_service.dart';
import 'data/repositories/user_repository.dart';
import 'routes/app_routes.dart';

/// Point d'entrée de l'application KAFECS Gestion
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Sur Windows/Linux, sqflite nécessite le moteur FFI pour fonctionner
  if (Platform.isWindows || Platform.isLinux) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  SyncService.instance.demarrerEcouteAutomatique();
  runApp(const EwkefGestionApp());
}

class EwkefGestionApp extends StatelessWidget {
  const EwkefGestionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
      ],
      child: MaterialApp(
        title: 'KAFECS',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        onGenerateRoute: AppRoutes.generateRoute,
        home: const _EcranDemarrage(),
      ),
    );
  }
}

/// Détermine, au lancement, s'il faut afficher l'écran de configuration
/// initiale (aucun compte existant) ou l'écran de connexion normal.
/// Tente d'abord une synchronisation pour récupérer un compte déjà
/// créé sur un autre appareil (téléphone/PC) avant de décider.
class _EcranDemarrage extends StatefulWidget {
  const _EcranDemarrage();

  @override
  State<_EcranDemarrage> createState() => _EcranDemarrageState();
}

class _EcranDemarrageState extends State<_EcranDemarrage> {
  String? _erreur;

  @override
  void initState() {
    super.initState();
    _verifierPremierLancement();
  }

  Future<void> _verifierPremierLancement() async {
    try {
      // Tente de synchroniser avant de décider quel écran afficher, pour
      // détecter un compte déjà créé sur un autre appareil (téléphone/PC).
      await SyncService.instance.synchroniserMaintenant().timeout(
        const Duration(seconds: 10),
        onTimeout: () {},
      );

      final aUnUtilisateur = await UserRepository().existeAuMoinsUnUtilisateur();
      if (!mounted) return;

      Navigator.of(context).pushReplacementNamed(
        aUnUtilisateur ? AppRoutes.login : AppRoutes.setup,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _erreur = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_erreur != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                const Text("Erreur au démarrage", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(_erreur!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),
        ),
      );
    }
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}