import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/services/auth_service.dart';
import '../../../core/services/database_service.dart';
import '../../../core/constants/app_constants.dart';
import '../../../routes/app_routes.dart';
import 'profil_screen.dart';
import '../../../core/services/sync_service.dart';
import 'avant_propos_screen.dart';

/// Écran de paramètres généraux de l'application (accessible au Propriétaire)
class ParametresScreen extends StatefulWidget {
  const ParametresScreen({super.key});

  @override
  State<ParametresScreen> createState() => _ParametresScreenState();
}

class _ParametresScreenState extends State<ParametresScreen> {
  bool _reinitialisationEnCours = false;

  Future<void> _confirmerReinitialisation() async {
    final premiereConfirmation = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("⚠️ Réinitialiser toutes les données"),
        content: const Text(
          "Cette action va supprimer DÉFINITIVEMENT :\n\n"
          "• Tous les produits et le stock\n"
          "• Toutes les ventes et factures\n"
          "• Toutes les dépenses\n"
          "• Toutes les sessions de caisse\n"
          "• Tous les clients enregistrés\n"
          "• Tous les comptes utilisateurs (y compris le tien)\n\n"
          "L'application redémarrera comme une toute nouvelle installation. "
          "Cette action est IRRÉVERSIBLE.",
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text("Annuler")),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text("Continuer", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (premiereConfirmation != true) return;
    if (!mounted) return;

    final texteConfirmation = await showDialog<String>(
      context: context,
      builder: (_) => _DialogueConfirmationTexte(),
    );

    if (texteConfirmation != 'SUPPRIMER') {
      if (texteConfirmation != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Texte incorrect, réinitialisation annulée"), backgroundColor: Colors.orange),
        );
      }
      return;
    }

        setState(() => _reinitialisationEnCours = true);

    try {
      await SyncService.instance.viderToutLeCloud();
      await DatabaseService.instance.reinitialiserToutesLesDonnees();

      if (!mounted) return;
      context.read<AuthService>().deconnexion();
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.setup,
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur : $e"), backgroundColor: Colors.red),
      );
      setState(() => _reinitialisationEnCours = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Paramètres")),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text("Compte", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          ),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text("Mon profil"),
            subtitle: const Text("Nom, identifiant, mot de passe"),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ProfilScreen()),
            ),
          ),
          const Divider(),

          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text("Entreprise", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          ),
          ListTile(
            leading: const Icon(Icons.store_outlined),
            title: Text(AppConstants.sigleEntreprise),
            subtitle: Text(AppConstants.nomEntreprise),
          ),
          ListTile(
            leading: const Icon(Icons.phone_outlined),
            title: const Text("Téléphone"),
            subtitle: Text(AppConstants.telephoneEntreprise),
          ),
          const Divider(),

                    const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text("À propos", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: const Text("Avant-propos"),
            subtitle: const Text("Présentation du logiciel et du développeur"),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AvantProposScreen()),
            ),
          ),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text("Version de l'application"),
            subtitle: Text("1.0.0"),
          ),
          const ListTile(
            leading: Icon(Icons.cloud_outlined),
            title: Text("Synchronisation"),
            subtitle: Text("Automatique dès qu'une connexion internet est disponible"),
          ),
          const Divider(),

          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text("Zone dangereuse", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
          ),
          ListTile(
            leading: _reinitialisationEnCours
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text("Réinitialiser toutes les données", style: TextStyle(color: Colors.red)),
            subtitle: const Text("Efface tout : produits, ventes, clients, comptes..."),
            onTap: _reinitialisationEnCours ? null : _confirmerReinitialisation,
          ),
        ],
      ),
    );
  }
}

/// Dialogue exigeant de taper "SUPPRIMER" pour confirmer l'action irréversible
class _DialogueConfirmationTexte extends StatefulWidget {
  @override
  State<_DialogueConfirmationTexte> createState() => _DialogueConfirmationTexteState();
}

class _DialogueConfirmationTexteState extends State<_DialogueConfirmationTexte> {
  final _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Confirmation finale"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Pour confirmer, tape le mot : SUPPRIMER"),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            autofocus: true,
            decoration: const InputDecoration(border: OutlineInputBorder()),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text("Annuler")),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () => Navigator.of(context).pop(_controller.text.trim()),
          child: const Text("Confirmer"),
        ),
      ],
    );
  }
}