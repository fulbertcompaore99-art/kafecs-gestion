import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/sale_model.dart';
import '../../../data/repositories/sale_repository.dart';
import '../invoice/facture_preview_screen.dart';

/// Historique des ventes. [vendeurId] null = toutes les ventes (Propriétaire),
/// sinon uniquement les ventes de ce vendeur (Secrétaire).
/// [autoriserSuppression] active le bouton de suppression (réservé au Propriétaire).
class HistoriqueVentesScreen extends StatefulWidget {
  final String? vendeurId;
  final String titre;
  final bool autoriserSuppression;

  const HistoriqueVentesScreen({
    super.key,
    this.vendeurId,
    this.titre = "Historique des ventes",
    this.autoriserSuppression = false,
  });

  @override
  State<HistoriqueVentesScreen> createState() => _HistoriqueVentesScreenState();
}

class _HistoriqueVentesScreenState extends State<HistoriqueVentesScreen> {
  final _saleRepository = SaleRepository();
  List<SaleModel> _ventes = [];
  bool _chargement = true;

  @override
  void initState() {
    super.initState();
    _chargerVentes();
  }

  Future<void> _chargerVentes() async {
    setState(() => _chargement = true);
    final liste = widget.vendeurId != null
        ? await _saleRepository.listerVentesParVendeur(widget.vendeurId!)
        : await _saleRepository.listerToutesLesVentes();
    setState(() {
      _ventes = liste;
      _chargement = false;
    });
  }

  Future<void> _confirmerSuppression(SaleModel vente) async {
    final confirme = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Confirmer la suppression"),
        content: Text(
          "Supprimer définitivement la facture ${vente.numeroFacture} ?\n\n"
          "⚠️ Le stock ne sera pas restauré automatiquement.",
        ),
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
      await _saleRepository.supprimerVente(vente.id);
      _chargerVentes();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.titre)),
      body: _chargement
          ? const Center(child: CircularProgressIndicator())
          : _ventes.isEmpty
              ? const Center(child: Text("Aucune vente enregistrée"))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _ventes.length,
                  itemBuilder: (context, index) {
                    final vente = _ventes[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: AppTheme.primaryColor,
                          child: Icon(Icons.receipt, color: Colors.white),
                        ),
                        title: Text("Facture ${vente.numeroFacture}"),
                        subtitle: Text(
                          "${vente.clientNom} • ${vente.dateVente.day}/${vente.dateVente.month}/${vente.dateVente.year}"
                          "${widget.vendeurId == null ? ' • ${vente.vendeurNom}' : ''}",
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "${vente.total.toStringAsFixed(0)} FCFA",
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            if (widget.autoriserSuppression)
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                onPressed: () => _confirmerSuppression(vente),
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
    );
  }
}