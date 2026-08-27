import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/services/auth_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/expense_model.dart';
import '../../../data/repositories/expense_repository.dart';

/// Écran de gestion des dépenses diverses de l'entreprise
/// (loyer, électricité, transport, réparations, etc.)
class ListeDepensesScreen extends StatefulWidget {
  const ListeDepensesScreen({super.key});

  @override
  State<ListeDepensesScreen> createState() => _ListeDepensesScreenState();
}

class _ListeDepensesScreenState extends State<ListeDepensesScreen> {
  final _expenseRepository = ExpenseRepository();
  List<ExpenseModel> _depenses = [];
  bool _chargement = true;

  @override
  void initState() {
    super.initState();
    _chargerDepenses();
  }

  Future<void> _chargerDepenses() async {
    setState(() => _chargement = true);
    final liste = await _expenseRepository.listerToutesLesDepenses();
    setState(() {
      _depenses = liste;
      _chargement = false;
    });
  }

  double get _totalDepenses => _depenses.fold(0, (somme, d) => somme + d.montant);

  void _ouvrirFormulaireCreation() {
    showDialog(
      context: context,
      builder: (_) => _FormulaireDepenseDialog(onSauvegarde: _chargerDepenses),
    );
  }

  Future<void> _confirmerSuppression(ExpenseModel depense) async {
    final confirme = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Confirmer la suppression"),
        content: Text("Supprimer la dépense « ${depense.libelle} » ?"),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text("Annuler")),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text("Supprimer", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirme == true) {
      await _expenseRepository.supprimerDepense(depense.id);
      _chargerDepenses();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Dépenses")),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            color: AppTheme.primaryColor,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Total des dépenses", style: TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 4),
                Text(
                  "${_totalDepenses.toStringAsFixed(0)} FCFA",
                  style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Expanded(
            child: _chargement
                ? const Center(child: CircularProgressIndicator())
                : _depenses.isEmpty
                    ? const Center(child: Text("Aucune dépense enregistrée"))
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _depenses.length,
                        itemBuilder: (context, index) {
                          final depense = _depenses[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: const CircleAvatar(
                                backgroundColor: Colors.redAccent,
                                child: Icon(Icons.money_off, color: Colors.white),
                              ),
                              title: Text(depense.libelle),
                              subtitle: Text(
                                "${depense.dateDepense.day}/${depense.dateDepense.month}/${depense.dateDepense.year} • ${depense.userNom}",
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    "${depense.montant.toStringAsFixed(0)} FCFA",
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                    onPressed: () => _confirmerSuppression(depense),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _ouvrirFormulaireCreation,
        icon: const Icon(Icons.add),
        label: const Text("Nouvelle dépense"),
      ),
    );
  }
}

/// Boîte de dialogue pour enregistrer une nouvelle dépense
class _FormulaireDepenseDialog extends StatefulWidget {
  final VoidCallback onSauvegarde;

  const _FormulaireDepenseDialog({required this.onSauvegarde});

  @override
  State<_FormulaireDepenseDialog> createState() => _FormulaireDepenseDialogState();
}

class _FormulaireDepenseDialogState extends State<_FormulaireDepenseDialog> {
  final _formKey = GlobalKey<FormState>();
  final _expenseRepository = ExpenseRepository();
  final _libelleController = TextEditingController();
  final _montantController = TextEditingController();

  bool _chargement = false;

  @override
  void dispose() {
    _libelleController.dispose();
    _montantController.dispose();
    super.dispose();
  }

  Future<void> _sauvegarder() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _chargement = true);

    try {
      final authService = context.read<AuthService>();
      final utilisateur = authService.utilisateurConnecte!;

      await _expenseRepository.creerDepense(
        libelle: _libelleController.text.trim(),
        montant: double.parse(_montantController.text),
        userId: utilisateur.id,
        userNom: utilisateur.nomComplet,
      );

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
      title: const Text("Nouvelle dépense"),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _libelleController,
              decoration: const InputDecoration(labelText: "Libellé (ex: Loyer, Electricité...)"),
              validator: (v) => (v == null || v.trim().isEmpty) ? "Requis" : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _montantController,
              decoration: const InputDecoration(labelText: "Montant (FCFA)"),
              keyboardType: TextInputType.number,
              validator: (v) => (v == null || double.tryParse(v) == null) ? "Invalide" : null,
            ),
          ],
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
                  height: 16, width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text("Enregistrer"),
        ),
      ],
    );
  }
}