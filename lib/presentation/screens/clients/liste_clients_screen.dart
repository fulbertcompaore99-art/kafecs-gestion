import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/client_model.dart';
import '../../../data/repositories/client_repository.dart';

class ListeClientsScreen extends StatefulWidget {
  const ListeClientsScreen({super.key});

  @override
  State<ListeClientsScreen> createState() => _ListeClientsScreenState();
}

class _ListeClientsScreenState extends State<ListeClientsScreen> {
  final _clientRepository = ClientRepository();
  List<ClientModel> _clients = [];
  bool _chargement = true;
  String _recherche = '';

  @override
  void initState() {
    super.initState();
    _chargerClients();
  }

  Future<void> _chargerClients() async {
    setState(() => _chargement = true);
    final liste = await _clientRepository.listerTousLesClients();
    setState(() {
      _clients = liste;
      _chargement = false;
    });
  }

  List<ClientModel> get _clientsFiltres {
    if (_recherche.isEmpty) return _clients;
    return _clients
        .where((c) => c.nom.toLowerCase().contains(_recherche.toLowerCase()))
        .toList();
  }

  void _ouvrirFormulaireCreation() {
    showDialog(
      context: context,
      builder: (_) => _FormulaireClientDialog(onSauvegarde: _chargerClients),
    );
  }

  void _ouvrirFormulaireModification(ClientModel client) {
    showDialog(
      context: context,
      builder: (_) => _FormulaireClientDialog(
        clientExistant: client,
        onSauvegarde: _chargerClients,
      ),
    );
  }

  Future<void> _confirmerSuppression(ClientModel client) async {
    final confirme = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Confirmer la suppression"),
        content: Text("Supprimer définitivement le client « ${client.nom} » ?"),
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
      await _clientRepository.supprimerClient(client.id);
      _chargerClients();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Clients")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: const InputDecoration(
                hintText: "Rechercher un client...",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (value) => setState(() => _recherche = value),
            ),
          ),
          Expanded(
            child: _chargement
                ? const Center(child: CircularProgressIndicator())
                : _clientsFiltres.isEmpty
                    ? const Center(child: Text("Aucun client enregistré"))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: _clientsFiltres.length,
                        itemBuilder: (context, index) {
                          final client = _clientsFiltres[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: const CircleAvatar(
                                backgroundColor: AppTheme.primaryColor,
                                child: Icon(Icons.person, color: Colors.white),
                              ),
                              title: Text(client.nom),
                              subtitle: Text(
                                "${client.adresse}"
                                "${client.telephone != null ? ' • ${client.telephone}' : ''}"
                                "${client.solde != 0 ? ' • Solde: ${client.solde.toStringAsFixed(0)} FCFA' : ''}",
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.blue),
                                    onPressed: () => _ouvrirFormulaireModification(client),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => _confirmerSuppression(client),
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
        label: const Text("Nouveau client"),
      ),
    );
  }
}

/// Boîte de dialogue pour créer ou modifier un client
class _FormulaireClientDialog extends StatefulWidget {
  final ClientModel? clientExistant;
  final VoidCallback onSauvegarde;

  const _FormulaireClientDialog({this.clientExistant, required this.onSauvegarde});

  @override
  State<_FormulaireClientDialog> createState() => _FormulaireClientDialogState();
}

class _FormulaireClientDialogState extends State<_FormulaireClientDialog> {
  final _formKey = GlobalKey<FormState>();
  final _clientRepository = ClientRepository();

  late TextEditingController _nomController;
  late TextEditingController _adresseController;
  late TextEditingController _telephoneController;

  bool _chargement = false;
  bool get _estModification => widget.clientExistant != null;

  @override
  void initState() {
    super.initState();
    final c = widget.clientExistant;
    _nomController = TextEditingController(text: c?.nom ?? '');
    _adresseController = TextEditingController(text: c?.adresse ?? '');
    _telephoneController = TextEditingController(text: c?.telephone ?? '');
  }

  @override
  void dispose() {
    _nomController.dispose();
    _adresseController.dispose();
    _telephoneController.dispose();
    super.dispose();
  }

  Future<void> _sauvegarder() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _chargement = true);

    try {
      if (_estModification) {
        final clientModifie = ClientModel(
          id: widget.clientExistant!.id,
          nom: _nomController.text.trim(),
          adresse: _adresseController.text.trim(),
          telephone: _telephoneController.text.trim().isEmpty ? null : _telephoneController.text.trim(),
          solde: widget.clientExistant!.solde,
          dateCreation: widget.clientExistant!.dateCreation,
        );
        await _clientRepository.modifierClient(clientModifie);
      } else {
        await _clientRepository.creerClient(
          nom: _nomController.text.trim(),
          adresse: _adresseController.text.trim(),
          telephone: _telephoneController.text.trim().isEmpty ? null : _telephoneController.text.trim(),
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
      title: Text(_estModification ? "Modifier le client" : "Nouveau client"),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nomController,
                decoration: const InputDecoration(labelText: "Nom du client"),
                validator: (v) => (v == null || v.trim().isEmpty) ? "Requis" : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _adresseController,
                decoration: const InputDecoration(labelText: "Adresse"),
                validator: (v) => (v == null || v.trim().isEmpty) ? "Requis" : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _telephoneController,
                decoration: const InputDecoration(labelText: "Téléphone (optionnel)"),
                keyboardType: TextInputType.phone,
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
                  height: 16, width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text("Enregistrer"),
        ),
      ],
    );
  }
}