import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/user_repository.dart';

/// Écran de gestion des comptes utilisateurs (accessible au Propriétaire uniquement)
class GestionUtilisateursScreen extends StatefulWidget {
  const GestionUtilisateursScreen({super.key});

  @override
  State<GestionUtilisateursScreen> createState() => _GestionUtilisateursScreenState();
}

class _GestionUtilisateursScreenState extends State<GestionUtilisateursScreen> {
  final _userRepository = UserRepository();
  List<UserModel> _utilisateurs = [];
  bool _chargement = true;

  @override
  void initState() {
    super.initState();
    _chargerUtilisateurs();
  }

  Future<void> _chargerUtilisateurs() async {
    setState(() => _chargement = true);
    final liste = await _userRepository.listerTousLesUtilisateurs();
    setState(() {
      _utilisateurs = liste;
      _chargement = false;
    });
  }

  void _ouvrirFormulaireCreation() {
    showDialog(
      context: context,
      builder: (_) => _FormulaireUtilisateurDialog(
        onSauvegarde: _chargerUtilisateurs,
      ),
    );
  }

  void _ouvrirFormulaireModification(UserModel user) {
    showDialog(
      context: context,
      builder: (_) => _FormulaireUtilisateurDialog(
        utilisateurExistant: user,
        onSauvegarde: _chargerUtilisateurs,
      ),
    );
  }

  Future<void> _changerStatut(UserModel user) async {
    await _userRepository.changerStatutActif(user.id, !user.actif);
    _chargerUtilisateurs();
  }

  Future<void> _confirmerSuppression(UserModel user) async {
    final confirme = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Confirmer la suppression"),
        content: Text("Supprimer définitivement le compte de ${user.nomComplet} ?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text("Annuler"),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text("Supprimer", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirme == true) {
      await _userRepository.supprimerUtilisateur(user.id);
      _chargerUtilisateurs();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Gestion des utilisateurs")),
      body: _chargement
          ? const Center(child: CircularProgressIndicator())
          : _utilisateurs.isEmpty
              ? const Center(child: Text("Aucun secrétaire créé pour le moment"))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _utilisateurs.length,
                  itemBuilder: (context, index) {
                    final user = _utilisateurs[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: user.estProprietaire
                              ? AppTheme.primaryColor
                              : AppTheme.secondaryColor,
                          child: Icon(
                            user.estProprietaire ? Icons.star : Icons.person,
                            color: Colors.white,
                          ),
                        ),
                        title: Text(user.nomComplet),
                        subtitle: Text(
                          "${user.identifiant} • ${user.estProprietaire ? 'Propriétaire' : 'Secrétaire'} • ${user.actif ? 'Actif' : 'Désactivé'}",
                        ),
                        trailing: user.estProprietaire
                            ? null // le propriétaire ne peut pas se gérer lui-même ici
                            : Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.blue),
                                    onPressed: () => _ouvrirFormulaireModification(user),
                                    tooltip: "Modifier",
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      user.actif ? Icons.block : Icons.check_circle,
                                      color: user.actif ? Colors.orange : Colors.green,
                                    ),
                                    onPressed: () => _changerStatut(user),
                                    tooltip: user.actif ? "Désactiver" : "Activer",
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => _confirmerSuppression(user),
                                    tooltip: "Supprimer",
                                  ),
                                ],
                              ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _ouvrirFormulaireCreation,
        icon: const Icon(Icons.add),
        label: const Text("Nouveau secrétaire"),
      ),
    );
  }
}

/// Boîte de dialogue pour créer ou modifier un utilisateur secrétaire
class _FormulaireUtilisateurDialog extends StatefulWidget {
  final UserModel? utilisateurExistant;
  final VoidCallback onSauvegarde;

  const _FormulaireUtilisateurDialog({
    this.utilisateurExistant,
    required this.onSauvegarde,
  });

  @override
  State<_FormulaireUtilisateurDialog> createState() => _FormulaireUtilisateurDialogState();
}

class _FormulaireUtilisateurDialogState extends State<_FormulaireUtilisateurDialog> {
  final _formKey = GlobalKey<FormState>();
  final _userRepository = UserRepository();

  late TextEditingController _nomController;
  late TextEditingController _identifiantController;
  final _motDePasseController = TextEditingController();

  bool _chargement = false;
  bool get _estModification => widget.utilisateurExistant != null;

  @override
  void initState() {
    super.initState();
    _nomController = TextEditingController(text: widget.utilisateurExistant?.nomComplet ?? '');
    _identifiantController = TextEditingController(text: widget.utilisateurExistant?.identifiant ?? '');
  }

  @override
  void dispose() {
    _nomController.dispose();
    _identifiantController.dispose();
    _motDePasseController.dispose();
    super.dispose();
  }

  Future<void> _sauvegarder() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _chargement = true);

    try {
      if (_estModification) {
        final userModifie = UserModel(
          id: widget.utilisateurExistant!.id,
          nomComplet: _nomController.text.trim(),
          identifiant: _identifiantController.text.trim(),
          motDePasseHash: widget.utilisateurExistant!.motDePasseHash,
          role: widget.utilisateurExistant!.role,
          actif: widget.utilisateurExistant!.actif,
          dateCreation: widget.utilisateurExistant!.dateCreation,
        );
        await _userRepository.modifierUtilisateur(userModifie);

        if (_motDePasseController.text.isNotEmpty) {
          await _userRepository.changerMotDePasse(
            widget.utilisateurExistant!.id,
            _motDePasseController.text,
          );
        }
      } else {
        await _userRepository.creerSecretaire(
          nomComplet: _nomController.text.trim(),
          identifiant: _identifiantController.text.trim(),
          motDePasse: _motDePasseController.text,
        );
      }

      if (!mounted) return;
      widget.onSauvegarde();
      Navigator.of(context).pop();
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
    return AlertDialog(
      title: Text(_estModification ? "Modifier le secrétaire" : "Nouveau secrétaire"),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nomController,
                decoration: const InputDecoration(labelText: "Nom complet"),
                validator: (v) => (v == null || v.trim().isEmpty) ? "Requis" : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _identifiantController,
                decoration: const InputDecoration(labelText: "Identifiant"),
                validator: (v) => (v == null || v.trim().isEmpty) ? "Requis" : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _motDePasseController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: _estModification
                      ? "Nouveau mot de passe (laisser vide pour ne pas changer)"
                      : "Mot de passe",
                ),
                validator: (v) {
                  if (!_estModification && (v == null || v.isEmpty)) {
                    return "Requis";
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _chargement ? null : () => Navigator.of(context).pop(),
          child: const Text("Annuler"),
        ),
        ElevatedButton(
          onPressed: _chargement ? null : _sauvegarder,
          child: _chargement
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text("Enregistrer"),
        ),
      ],
    );
  }
}