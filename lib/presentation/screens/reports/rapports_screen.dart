import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/services/pdf_service.dart';
import '../../../data/models/sale_model.dart';
import '../../../data/repositories/sale_repository.dart';
import '../invoice/facture_preview_screen.dart';

class RapportsScreen extends StatefulWidget {
  const RapportsScreen({super.key});

  @override
  State<RapportsScreen> createState() => _RapportsScreenState();
}

enum _Periode { jour, semaine, mois, tout }

class _RapportsScreenState extends State<RapportsScreen> {
  final _saleRepository = SaleRepository();
  final _pdfService = PdfService();

  List<SaleModel> _ventes = [];
  bool _chargement = true;
  bool _exportEnCours = false;
  _Periode _periodeSelectionnee = _Periode.jour;

  @override
  void initState() {
    super.initState();
    _chargerDonnees();
  }

  ({DateTime debut, DateTime fin}) _plageDates(_Periode periode) {
    final maintenant = DateTime.now();
    final aujourdhui = DateTime(maintenant.year, maintenant.month, maintenant.day);

    switch (periode) {
      case _Periode.jour:
        return (debut: aujourdhui, fin: aujourdhui.add(const Duration(days: 1)));
      case _Periode.semaine:
        final debutSemaine = aujourdhui.subtract(Duration(days: aujourdhui.weekday - 1));
        return (debut: debutSemaine, fin: aujourdhui.add(const Duration(days: 1)));
      case _Periode.mois:
        final debutMois = DateTime(maintenant.year, maintenant.month, 1);
        return (debut: debutMois, fin: aujourdhui.add(const Duration(days: 1)));
      case _Periode.tout:
        return (debut: DateTime(2000), fin: aujourdhui.add(const Duration(days: 1)));
    }
  }

  Future<void> _chargerDonnees() async {
    setState(() => _chargement = true);
    final plage = _plageDates(_periodeSelectionnee);
    final liste = await _saleRepository.listerVentesEntreDates(plage.debut, plage.fin);
    liste.sort((a, b) => b.dateVente.compareTo(a.dateVente));
    setState(() {
      _ventes = liste;
      _chargement = false;
    });
  }

  double get _totalVentes => _ventes.fold(0, (somme, v) => somme + v.total);

  List<MapEntry<String, int>> get _produitsPlusVendus {
    final Map<String, int> quantitesParProduit = {};
    for (final vente in _ventes) {
      for (final item in vente.articles) {
        quantitesParProduit[item.designation] =
            (quantitesParProduit[item.designation] ?? 0) + item.quantite;
      }
    }
    final liste = quantitesParProduit.entries.toList();
    liste.sort((a, b) => b.value.compareTo(a.value));
    return liste.take(5).toList();
  }

  List<MapEntry<String, double>> get _ventesParEmploye {
    final Map<String, double> totalParVendeur = {};
    for (final vente in _ventes) {
      totalParVendeur[vente.vendeurNom] = (totalParVendeur[vente.vendeurNom] ?? 0) + vente.total;
    }
    final liste = totalParVendeur.entries.toList();
    liste.sort((a, b) => b.value.compareTo(a.value));
    return liste;
  }

  String _libellePeriode(_Periode p) {
    switch (p) {
      case _Periode.jour:
        return "Aujourd'hui";
      case _Periode.semaine:
        return "Cette semaine";
      case _Periode.mois:
        return "Ce mois";
      case _Periode.tout:
        return "Tout";
    }
  }

  Future<void> _exporterRapportPdf() async {
    setState(() => _exportEnCours = true);
    try {
      final chemin = await _pdfService.genererRapportPdf(
        libellePeriode: _libellePeriode(_periodeSelectionnee),
        ventes: _ventes,
        totalVentes: _totalVentes,
        produitsPlusVendus: _produitsPlusVendus,
        ventesParEmploye: _ventesParEmploye,
      );
      if (!mounted) return;
      await Share.shareXFiles([XFile(chemin)], text: 'Rapport de ventes — ${_libellePeriode(_periodeSelectionnee)}');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur export PDF : $e"), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _exportEnCours = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Rapports"),
        actions: [
          IconButton(
            icon: _exportEnCours
                ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.picture_as_pdf),
            tooltip: "Exporter en PDF",
            onPressed: _exportEnCours ? null : _exporterRapportPdf,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _Periode.values.map((p) {
                  final selectionne = p == _periodeSelectionnee;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(_libellePeriode(p)),
                      selected: selectionne,
                      onSelected: (_) {
                        setState(() => _periodeSelectionnee = p);
                        _chargerDonnees();
                      },
                      selectedColor: AppTheme.primaryColor,
                      labelStyle: TextStyle(color: selectionne ? Colors.white : null),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          Expanded(
            child: _chargement
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Carte total
                        Card(
                          color: AppTheme.primaryColor,
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Total des ventes — ${_libellePeriode(_periodeSelectionnee)}",
                                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  "${_totalVentes.toStringAsFixed(0)} FCFA",
                                  style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "${_ventes.length} facture(s)",
                                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        const Text("Produits les plus vendus", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        _produitsPlusVendus.isEmpty
                            ? const Padding(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                child: Text("Aucune vente sur cette période", style: TextStyle(color: Colors.grey)),
                              )
                            : Card(
                                child: Column(
                                  children: _produitsPlusVendus.map((entry) {
                                    return ListTile(
                                      leading: const Icon(Icons.inventory_2, color: AppTheme.primaryColor),
                                      title: Text(entry.key),
                                      trailing: Text(
                                        "${entry.value} vendu(s)",
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                        const SizedBox(height: 20),

                        const Text("Ventes par employé", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        _ventesParEmploye.isEmpty
                            ? const Padding(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                child: Text("Aucune vente sur cette période", style: TextStyle(color: Colors.grey)),
                              )
                            : Card(
                                child: Column(
                                  children: _ventesParEmploye.map((entry) {
                                    return ListTile(
                                      leading: const CircleAvatar(
                                        backgroundColor: AppTheme.secondaryColor,
                                        child: Icon(Icons.person, color: Colors.white),
                                      ),
                                      title: Text(entry.key),
                                      trailing: Text(
                                        "${entry.value.toStringAsFixed(0)} FCFA",
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                        const SizedBox(height: 20),

                        // Détail de chaque vente (liste détaillée)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Détail des ventes", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            Text("${_ventes.length} vente(s)", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _ventes.isEmpty
                            ? const Padding(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                child: Text("Aucune vente sur cette période", style: TextStyle(color: Colors.grey)),
                              )
                            : Column(
                                children: _ventes.map((vente) {
                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    child: ExpansionTile(
                                      leading: const Icon(Icons.receipt, color: AppTheme.primaryColor),
                                      title: Text(
                                        "Facture ${vente.numeroFacture} — ${vente.clientNom}",
                                        style: const TextStyle(fontWeight: FontWeight.w600),
                                      ),
                                      subtitle: Text(
                                        "${vente.dateVente.hour.toString().padLeft(2, '0')}h${vente.dateVente.minute.toString().padLeft(2, '0')} "
                                        "• ${vente.vendeurNom} • ${vente.total.toStringAsFixed(0)} FCFA",
                                      ),
                                      children: [
                                        ...vente.articles.map((item) => ListTile(
                                              dense: true,
                                              title: Text(item.designation),
                                              trailing: Text(
                                                "${item.quantite} x ${item.prixUnitaire.toStringAsFixed(0)} = ${item.prixTotal.toStringAsFixed(0)} FCFA",
                                              ),
                                            )),
                                        Padding(
                                          padding: const EdgeInsets.all(8),
                                          child: TextButton.icon(
                                            onPressed: () => Navigator.of(context).push(
                                              MaterialPageRoute(builder: (_) => FacturePreviewScreen(vente: vente)),
                                            ),
                                            icon: const Icon(Icons.visibility, size: 18),
                                            label: const Text("Voir la facture complète"),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}