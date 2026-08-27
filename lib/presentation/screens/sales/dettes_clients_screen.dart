import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/sale_model.dart';
import '../../../data/repositories/sale_repository.dart';
import '../invoice/facture_preview_screen.dart';

/// Écran listant toutes les factures non intégralement payées (crédit client)
/// et permettant d'enregistrer un remboursement partiel ou total.
class DettesClientsScreen extends StatefulWidget {
  const DettesClientsScreen({super.key});

  @override
  State<DettesClientsScreen> createState() => _DettesClientsScreenState();
}

class _DettesClientsScreenState extends State<DettesClientsScreen> {
  final _saleRepository = SaleRepository();
  List<SaleModel> _ventesACredit = [];
  bool _chargement = true;

  @override
  void initState() {
    super.initState();
    _chargerDettes();
  }

  Future<void> _chargerDettes() async {
    setState(() => _chargement = true);
    final liste = await _saleRepository.listerVentesACredit();
    setState(() {
      _ventesACredit = liste;
      _chargement = false;
    });
  }

  double get _totalDettes => _ventesACredit.fold(0, (somme, v) => somme + v.montantRestant);

  Future<void> _enregistrerPaiement(SaleModel vente) async {
    final montant = await showDialog<double>(
      context: context,
      builder: (_) => _DialoguePaiement(vente: vente),
    );

    if (montant == null || montant <= 0) return;

    await _saleRepository.enregistrerPaiement(vente.id, montant);
    _chargerDettes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Dettes clients")),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            color: Colors.red.shade700,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Total des dettes en cours", style: TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 4),
                Text(
                  "${_totalDettes.toStringAsFixed(0)} FCFA",
                  style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  "${_ventesACredit.length} facture(s) non soldée(s)",
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          Expanded(
            child: _chargement
                ? const Center(child: CircularProgressIndicator())
                : _ventesACredit.isEmpty
                    ? const Center(child: Text("Aucune dette en cours 🎉"))
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _ventesACredit.length,
                        itemBuilder: (context, index) {
                          final vente = _ventesACredit[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: const CircleAvatar(
                                backgroundColor: Colors.orange,
                                child: Icon(Icons.warning_amber, color: Colors.white),
                              ),
                              title: Text(vente.clientNom),
                              subtitle: Text(
                                "Facture ${vente.numeroFacture} • Total: ${vente.total.toStringAsFixed(0)} FCFA\n"
                                "Payé: ${vente.montantPaye.toStringAsFixed(0)} FCFA",
                              ),
                              isThreeLine: true,
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    "${vente.montantRestant.toStringAsFixed(0)} FCFA",
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                                  ),
                                  TextButton(
                                    onPressed: () => _enregistrerPaiement(vente),
                                    child: const Text("Encaisser"),
                                  ),
                                ],
                              ),
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => FacturePreviewScreen(vente: vente)),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

/// Dialogue pour saisir le montant remboursé par le client
class _DialoguePaiement extends StatefulWidget {
  final SaleModel vente;

  const _DialoguePaiement({required this.vente});

  @override
  State<_DialoguePaiement> createState() => _DialoguePaiementState();
}

class _DialoguePaiementState extends State<_DialoguePaiement> {
  final _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Encaisser — ${widget.vente.clientNom}"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Reste dû : ${widget.vente.montantRestant.toStringAsFixed(0)} FCFA"),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            keyboardType: TextInputType.number,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: "Montant versé maintenant (FCFA)",
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text("Annuler")),
        ElevatedButton(
          onPressed: () {
            final montant = double.tryParse(_controller.text);
            if (montant != null && montant > 0) {
              Navigator.of(context).pop(montant);
            }
          },
          child: const Text("Confirmer"),
        ),
      ],
    );
  }
}