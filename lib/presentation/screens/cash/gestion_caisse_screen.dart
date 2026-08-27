import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/services/auth_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/cash_session_model.dart';
import '../../../data/repositories/cash_repository.dart';

/// Écran de gestion de la caisse pour l'utilisateur connecté
/// (Propriétaire ou Secrétaire) : ouverture, suivi, clôture
class GestionCaisseScreen extends StatefulWidget {
  const GestionCaisseScreen({super.key});

  @override
  State<GestionCaisseScreen> createState() => _GestionCaisseScreenState();
}

class _GestionCaisseScreenState extends State<GestionCaisseScreen> {
  final _cashRepository = CashRepository();

  CashSessionModel? _sessionActuelle;
  double _totalVentes = 0;
  bool _chargement = true;

  @override
  void initState() {
    super.initState();
    _chargerSession();
  }

  Future<void> _chargerSession() async {
    setState(() => _chargement = true);

    final authService = context.read<AuthService>();
    final userId = authService.utilisateurConnecte!.id;

    final session = await _cashRepository.trouverSessionOuverte(userId);
    double total = 0;

    if (session != null) {
      total = await _cashRepository.calculerVentesDepuisOuverture(userId, session.dateOuverture);
    }

    setState(() {
      _sessionActuelle = session;
      _totalVentes = total;
      _chargement = false;
    });
  }

  Future<void> _ouvrirCaisse() async {
    final montant = await showDialog<double>(
      context: context,
      builder: (_) => const _DialogueMontant(
        titre: "Ouverture de caisse",
        labelChamp: "Fond de caisse initial (FCFA)",
      ),
    );

    if (montant == null) return;

    final authService = context.read<AuthService>();
    final utilisateur = authService.utilisateurConnecte!;

    await _cashRepository.ouvrirSession(
      userId: utilisateur.id,
      userNom: utilisateur.nomComplet,
      fondOuverture: montant,
    );

    _chargerSession();
  }

  Future<void> _cloturerCaisse() async {
    final montant = await showDialog<double>(
      context: context,
      builder: (_) => const _DialogueMontant(
        titre: "Clôture de caisse",
        labelChamp: "Montant compté en caisse (FCFA)",
      ),
    );

    if (montant == null || _sessionActuelle == null) return;

    await _cashRepository.cloturerSession(_sessionActuelle!.id, montant);

    if (!mounted) return;

    final montantAttendu = _sessionActuelle!.fondOuverture + _totalVentes;
    final ecart = montant - montantAttendu;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Caisse clôturée"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Montant attendu: ${montantAttendu.toStringAsFixed(0)} FCFA"),
            Text("Montant compté: ${montant.toStringAsFixed(0)} FCFA"),
            const SizedBox(height: 8),
            Text(
              ecart == 0
                  ? "✓ Caisse juste"
                  : ecart > 0
                      ? "Excédent: +${ecart.toStringAsFixed(0)} FCFA"
                      : "Manquant: ${ecart.toStringAsFixed(0)} FCFA",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: ecart == 0 ? Colors.green : (ecart > 0 ? Colors.orange : Colors.red),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _chargerSession();
            },
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Ma caisse")),
      body: _chargement
          ? const Center(child: CircularProgressIndicator())
          : _sessionActuelle == null
              ? _buildCaisseFermee()
              : _buildCaisseOuverte(),
    );
  }

  Widget _buildCaisseFermee() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.point_of_sale, size: 80, color: Colors.grey),
            const SizedBox(height: 16),
            const Text("Aucune caisse ouverte", style: TextStyle(fontSize: 18)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _ouvrirCaisse,
              icon: const Icon(Icons.lock_open),
              label: const Text("Ouvrir la caisse"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCaisseOuverte() {
    final session = _sessionActuelle!;
    final montantTheorique = session.fondOuverture + _totalVentes;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            color: AppTheme.primaryColor,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Caisse ouverte", style: TextStyle(color: Colors.white70, fontSize: 14)),
                  Text(
                    "Ouverte le ${session.dateOuverture.day}/${session.dateOuverture.month} à ${session.dateOuverture.hour}h${session.dateOuverture.minute.toString().padLeft(2, '0')}",
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _LigneMontant(label: "Fond de caisse initial", montant: session.fondOuverture),
          _LigneMontant(label: "Total des ventes", montant: _totalVentes),
          const Divider(height: 32),
          _LigneMontant(label: "Montant théorique en caisse", montant: montantTheorique, gras: true),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: _cloturerCaisse,
            icon: const Icon(Icons.lock),
            label: const Text("Clôturer la caisse"),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700),
          ),
        ],
      ),
    );
  }
}

class _LigneMontant extends StatelessWidget {
  final String label;
  final double montant;
  final bool gras;

  const _LigneMontant({required this.label, required this.montant, this.gras = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: gras ? 16 : 14, fontWeight: gras ? FontWeight.bold : null)),
          Text(
            "${montant.toStringAsFixed(0)} FCFA",
            style: TextStyle(
              fontSize: gras ? 16 : 14,
              fontWeight: gras ? FontWeight.bold : null,
              color: gras ? AppTheme.primaryColor : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _DialogueMontant extends StatefulWidget {
  final String titre;
  final String labelChamp;

  const _DialogueMontant({required this.titre, required this.labelChamp});

  @override
  State<_DialogueMontant> createState() => _DialogueMontantState();
}

class _DialogueMontantState extends State<_DialogueMontant> {
  final _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.titre),
      content: TextField(
        controller: _controller,
        keyboardType: TextInputType.number,
        autofocus: true,
        decoration: InputDecoration(labelText: widget.labelChamp, border: const OutlineInputBorder()),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text("Annuler")),
        ElevatedButton(
          onPressed: () {
            final montant = double.tryParse(_controller.text);
            if (montant != null && montant >= 0) {
              Navigator.of(context).pop(montant);
            }
          },
          child: const Text("Confirmer"),
        ),
      ],
    );
  }
}