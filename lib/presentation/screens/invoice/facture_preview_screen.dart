import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/pdf_service.dart';
import '../../../core/services/printer_service.dart';
import '../../../data/models/sale_model.dart';

class FacturePreviewScreen extends StatefulWidget {
  final SaleModel vente;

  const FacturePreviewScreen({super.key, required this.vente});

  @override
  State<FacturePreviewScreen> createState() => _FacturePreviewScreenState();
}

class _FacturePreviewScreenState extends State<FacturePreviewScreen> {
  final _pdfService = PdfService();
  final _printerService = PrinterService();
  bool _traitementEnCours = false;

  Future<void> _exporterEtPartagerPdf() async {
    setState(() => _traitementEnCours = true);
    try {
      final chemin = await _pdfService.genererFacturePdf(widget.vente);
      if (!mounted) return;
      await Share.shareXFiles([XFile(chemin)], text: 'Facture ${widget.vente.numeroFacture}');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur PDF : $e"), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _traitementEnCours = false);
    }
  }

  Future<void> _imprimer() async {
    try {
      await _printerService.imprimerFacture(widget.vente);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur d'impression : $e"), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final vente = widget.vente;

    return Scaffold(
      appBar: AppBar(title: Text("Facture ${vente.numeroFacture}")),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Card(
              elevation: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                    child: SizedBox(
                      height: 130, // Aligné sur la hauteur du PDF
                      width: double.infinity,
                      child: Image.asset(
                        'assets/images/entete_facture.png',
                        fit: BoxFit.contain, // Aperçu complet
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(32), // Aligné sur le padding du PDF
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Divider(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("FACTURE", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            Text("N° ${vente.numeroFacture}", style: const TextStyle(fontSize: 14)),
                          ],
                        ),
                        Text(
                          "Date: ${vente.dateVente.day}/${vente.dateVente.month}/${vente.dateVente.year}",
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        const SizedBox(height: 16),
                        const Text("Doit:", style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(vente.clientNom),
                        Text(vente.clientAdresse),
                        const SizedBox(height: 16),
                        Table(
                          border: TableBorder.all(color: Colors.grey.shade300),
                          columnWidths: const {
                            0: FlexColumnWidth(3),
                            1: FlexColumnWidth(1),
                            2: FlexColumnWidth(1.5),
                            3: FlexColumnWidth(1.5),
                          },
                          children: [
                            TableRow(
                              decoration: BoxDecoration(color: Colors.grey.shade200),
                              children: const [
                                _CelluleTexte("Désignation", gras: true),
                                _CelluleTexte("Qté", gras: true),
                                _CelluleTexte("P.U", gras: true),
                                _CelluleTexte("Total", gras: true),
                              ],
                            ),
                            ...vente.articles.map((item) => TableRow(
                                  children: [
                                    _CelluleTexte(item.designation),
                                    _CelluleTexte(item.quantite.toString()),
                                    _CelluleTexte(item.prixUnitaire.toStringAsFixed(0)),
                                    _CelluleTexte(item.prixTotal.toStringAsFixed(0)),
                                  ],
                                )),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                "TOTAL: ${vente.total.toStringAsFixed(0)} FCFA",
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                              ),
                              if (vente.estACredit) ...[
                                const SizedBox(height: 4),
                                Text("Payé: ${vente.montantPaye.toStringAsFixed(0)} FCFA", style: const TextStyle(fontSize: 13)),
                                Text(
                                  "Reste dû: ${vente.montantRestant.toStringAsFixed(0)} FCFA",
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.red),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          AppConstants.mentionFacture,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, fontStyle: FontStyle.italic),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _traitementEnCours ? null : _imprimer,
                icon: const Icon(Icons.print),
                label: const Text("Imprimer"),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _traitementEnCours ? null : _exporterEtPartagerPdf,
                icon: _traitementEnCours
                    ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.share),
                label: const Text("Partager PDF"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CelluleTexte extends StatelessWidget {
  final String texte;
  final bool gras;

  const _CelluleTexte(this.texte, {this.gras = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(6),
      child: Text(
        texte,
        style: TextStyle(fontSize: 11, fontWeight: gras ? FontWeight.bold : FontWeight.normal),
      ),
    );
  }
}