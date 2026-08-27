import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/services/auth_service.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/user_repository.dart';

/// Écran permettant à l'utilisateur connecté de modifier ses propres
/// informations : nom, identifiant, mot de passe.
class ProfilScreen extends StatefulWidget {
  const ProfilScreen({super.key});

  @override
  State<ProfilScreen> createState() => _ProfilScreenState();
}

class _ProfilScreenState extends State<ProfilScreen> {
  final _formKey = GlobalKey<FormState>();
  final _userRepository = UserRepository();

  late TextEditingController _nomController;
  late TextEditingController _identifiantController;
  final _nouveauMotDePasseController = TextEditingController();
  final _confirmationController = TextEditingController();

  bool _chargement = false;
  bool _modifierMotDePasse = false;

  @override
  void initState() {
    super.initState();
    final utilisateur = context.read<AuthService>().utilisateurConnecte!;
    _nomController = TextEditingController(text: utilisateur.nomComplet);
    _identifiantController = TextEditingController(text: utilisateur.identifiant);
  }

  @override
  void dispose() {
    _nomController.dispose();
    _identifiantController.dispose();
    _nouveauMotDePasseController.dispose();
    _confirmationController.dispose();
    super.dispose();
  }

  Future<void> _sauvegarder() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _chargement = true);

    try {
      final authService = context.read<AuthService>();
      final utilisateurActuel = authService.utilisateurConnecte!;

      final userModifie = UserModel(
        id: utilisateurActuel.id,
        nomComplet: _nomController.text.trim(),
        identifiant: _identifiantController.text.trim(),
        motDePasseHash: utilisateurActuel.motDePasseHash,
        role: utilisateurActuel.role,
        actif: utilisateurActuel.actif,
        dateCreation: utilisateurActuel.dateCreation,
        derniereConnexion: utilisateurActuel.derniereConnexion,
      );

      await _userRepository.modifierUtilisateur(userModifie);

      if (_modifierMotDePasse && _nouveauMotDePasseController.text.isNotEmpty) {
        await _userRepository.changerMotDePasse(
          utilisateurActuel.id,
          _nouveauMotDePasseController.text,
        );
      }

      await authService.rafraichirUtilisateurConnecte();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profil mis à jour avec succès"), backgroundColor: Colors.green),
      );
      setState(() {
        _modifierMotDePasse = false;
        _nouveauMotDePasseController.clear();
        _confirmationController.clear();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur : $e"), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _chargement = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final utilisateur = context.watch<AuthService>().utilisateurConnecte!;

    return Scaffold(
      appBar: AppBar(title: const Text("Mon profil")),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 450),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: CircleAvatar(
                      radius: 40,
                      child: Text(
                        utilisateur.nomComplet.isNotEmpty ? utilisateur.nomComplet[0].toUpperCase() : "?",
                        style: const TextStyle(fontSize: 32),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      utilisateur.estProprietaire ? "Propriétaire" : "Secrétaire",
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ),
                  const SizedBox(height: 24),

                  TextFormField(
                    controller: _nomController,
                    decoration: const InputDecoration(labelText: "Nom complet", border: OutlineInputBorder()),
                    validator: (v) => (v == null || v.trim().isEmpty) ? "Requis" : null,
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _identifiantController,
                    decoration: const InputDecoration(labelText: "Identifiant", border: OutlineInputBorder()),
                    validator: (v) => (v == null || v.trim().isEmpty) ? "Requis" : null,
                  ),
                  const SizedBox(height: 16),

                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    title: const Text("Changer mon mot de passe"),
                    value: _modifierMotDePasse,
                    onChanged: (valeur) => setState(() => _modifierMotDePasse = valeur ?? false),
                  ),

                  if (_modifierMotDePasse) ...[
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _nouveauMotDePasseController,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: "Nouveau mot de passe", border: OutlineInputBorder()),
                      validator: (v) {
                        if (_modifierMotDePasse && (v == null || v.length < 4)) {
                          return "Au moins 4 caractères";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _confirmationController,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: "Confirmer le mot de passe", border: OutlineInputBorder()),
                      validator: (v) {
                        if (_modifierMotDePasse && v != _nouveauMotDePasseController.text) {
                          return "Les mots de passe ne correspondent pas";
                        }
                        return null;
                      },
                    ),
                  ],

                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _chargement ? null : _sauvegarder,
                    child: _chargement
                        ? const SizedBox(
                            height: 20, width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text("Enregistrer les modifications"),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}