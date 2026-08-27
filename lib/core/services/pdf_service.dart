import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

import '../../data/models/sale_model.dart';
import '../constants/app_constants.dart';

class PdfService {
  Uint8List? _enteteBytesCache;

  Future<Uint8List> _chargerEntete() async {
    if (_enteteBytesCache != null) return _enteteBytesCache!;
    final data = await rootBundle.load('assets/images/entete_facture.png');
    _enteteBytesCache = data.buffer.asUint8List();
    return _enteteBytesCache!;
  }

  // En-tête avec BoxFit.fill pour couvrir toute la largeur sans rognage
  pw.Widget _construireEnTete(pw.MemoryImage entete) {
    return pw.Container(
      width: double.infinity,
      height: 130, // Hauteur ajustée pour bien afficher l'image
      child: pw.Image(
        entete,
        fit: pw.BoxFit.fill, // L'image est étirée pour remplir le conteneur
      ),
    );
  }

  Future<pw.Document> _construireDocumentFacture(SaleModel vente) async {
    final pdf = pw.Document();
    final enteteBytes = await _chargerEntete();
    final entete = pw.MemoryImage(enteteBytes);
    final formatDate = DateFormat('dd/MM/yyyy');

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.zero,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _construireEnTete(entete),
              pw.Padding(
                padding: const pw.EdgeInsets.all(32),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.SizedBox(height: 12),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text("FACTURE", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                        pw.Text("N° ${vente.numeroFacture}", style: const pw.TextStyle(fontSize: 13)),
                      ],
                    ),
                    pw.Text("Date: ${formatDate.format(vente.dateVente)}", style: const pw.TextStyle(fontSize: 11)),
                    pw.SizedBox(height: 12),
                    pw.Text("Doit:", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
                    pw.Text(vente.clientNom, style: const pw.TextStyle(fontSize: 11)),
                    pw.Text(vente.clientAdresse, style: const pw.TextStyle(fontSize: 11)),
                    pw.SizedBox(height: 16),
                    pw.Table(
                      border: pw.TableBorder.all(width: 0.5),
                      columnWidths: {
                        0: const pw.FlexColumnWidth(3),
                        1: const pw.FlexColumnWidth(1),
                        2: const pw.FlexColumnWidth(1.5),
                        3: const pw.FlexColumnWidth(1.5),
                      },
                      children: [
                        pw.TableRow(
                          decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                          children: [
                            _celluleEntete("Désignation"),
                            _celluleEntete("Qté"),
                            _celluleEntete("P.U"),
                            _celluleEntete("P.Total"),
                          ],
                        ),
                        ...vente.articles.map((item) => pw.TableRow(
                              children: [
                                _cellule(item.designation),
                                _cellule(item.quantite.toString()),
                                _cellule(item.prixUnitaire.toStringAsFixed(0)),
                                _cellule(item.prixTotal.toStringAsFixed(0)),
                              ],
                            )),
                      ],
                    ),
                    pw.SizedBox(height: 12),
                    pw.Align(
                      alignment: pw.Alignment.centerRight,
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Text("TOTAL: ${vente.total.toStringAsFixed(0)} FCFA",
                              style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold)),
                          if (vente.estACredit) ...[
                            pw.SizedBox(height: 4),
                            pw.Text("Payé: ${vente.montantPaye.toStringAsFixed(0)} FCFA",
                                style: const pw.TextStyle(fontSize: 11)),
                            pw.Text("Reste dû: ${vente.montantRestant.toStringAsFixed(0)} FCFA",
                                style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold,
                                    color: PdfColors.red)),
                          ],
                        ],
                      ),
                    ),
                    pw.SizedBox(height: 20),
                    pw.Text(AppConstants.mentionFacture,
                        style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 32),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text("Vendeur: ${vente.vendeurNom}", style: const pw.TextStyle(fontSize: 10)),
                        pw.Text("Client", style: const pw.TextStyle(fontSize: 10)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf;
  }

  Future<Uint8List> genererFacturePdfBytes(SaleModel vente) async {
    final pdf = await _construireDocumentFacture(vente);
    return pdf.save();
  }

  Future<String> genererFacturePdf(SaleModel vente) async {
    final pdf = await _construireDocumentFacture(vente);
    final dossier = await getApplicationDocumentsDirectory();
    final cheminFichier = '${dossier.path}/facture_${vente.numeroFacture}.pdf';
    final fichier = File(cheminFichier);
    await fichier.writeAsBytes(await pdf.save());
    return cheminFichier;
  }

  Future<String> genererRapportPdf({
    required String libellePeriode,
    required List<SaleModel> ventes,
    required double totalVentes,
    required List<MapEntry<String, int>> produitsPlusVendus,
    required List<MapEntry<String, double>> ventesParEmploye,
  }) async {
    final pdf = pw.Document();
    final enteteBytes = await _chargerEntete();
    final entete = pw.MemoryImage(enteteBytes);
    final formatDateHeure = DateFormat('dd/MM/yyyy HH:mm');
    final formatDate = DateFormat('dd/MM/yyyy à HH:mm');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.zero,
        header: (context) =>
            context.pageNumber == 1 ? _construireEnTete(entete) : pw.SizedBox(),
        build: (context) => [
          pw.Padding(
            padding: const pw.EdgeInsets.all(32),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.SizedBox(height: 8),
                pw.Text(
                    "Rapport généré le ${formatDate.format(DateTime.now())}",
                    style: const pw.TextStyle(fontSize: 9,
                        color: PdfColors.grey700)),
                pw.Divider(),
                pw.SizedBox(height: 8),
                pw.Text("RAPPORT DE VENTES — $libellePeriode",
                    style: pw.TextStyle(fontSize: 16,
                        fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 16),
                pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                      color: PdfColors.grey200,
                      borderRadius: pw.BorderRadius.circular(6)),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text("Total des ventes",
                              style: const pw.TextStyle(fontSize: 10)),
                          pw.Text(
                              "${totalVentes.toStringAsFixed(0)} FCFA",
                              style: pw.TextStyle(fontSize: 16,
                                  fontWeight: pw.FontWeight.bold)),
                        ],
                      ),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text("Nombre de factures",
                              style: const pw.TextStyle(fontSize: 10)),
                          pw.Text("${ventes.length}",
                              style: pw.TextStyle(fontSize: 16,
                                  fontWeight: pw.FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 20),
                pw.Text("Produits les plus vendus",
                    style: pw.TextStyle(fontSize: 13,
                        fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 6),
                if (produitsPlusVendus.isEmpty)
                  pw.Text("Aucune vente sur cette période",
                      style: const pw.TextStyle(fontSize: 10,
                          color: PdfColors.grey700))
                else
                  pw.Table(
                    border: pw.TableBorder.all(width: 0.5,
                        color: PdfColors.grey400),
                    columnWidths: {
                      0: const pw.FlexColumnWidth(3),
                      1: const pw.FlexColumnWidth(1)
                    },
                    children: [
                      pw.TableRow(
                        decoration: const pw.BoxDecoration(
                            color: PdfColors.grey300),
                        children: [
                          _celluleEntete("Produit"),
                          _celluleEntete("Quantité vendue")
                        ],
                      ),
                      ...produitsPlusVendus.map((e) => pw.TableRow(
                            children: [
                              _cellule(e.key),
                              _cellule(e.value.toString())
                            ],
                          )),
                    ],
                  ),
                pw.SizedBox(height: 20),
                pw.Text("Ventes par employé",
                    style: pw.TextStyle(fontSize: 13,
                        fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 6),
                if (ventesParEmploye.isEmpty)
                  pw.Text("Aucune vente sur cette période",
                      style: const pw.TextStyle(fontSize: 10,
                          color: PdfColors.grey700))
                else
                  pw.Table(
                    border: pw.TableBorder.all(width: 0.5,
                        color: PdfColors.grey400),
                    columnWidths: {
                      0: const pw.FlexColumnWidth(3),
                      1: const pw.FlexColumnWidth(1)
                    },
                    children: [
                      pw.TableRow(
                        decoration: const pw.BoxDecoration(
                            color: PdfColors.grey300),
                        children: [
                          _celluleEntete("Employé"),
                          _celluleEntete("Total vendu")
                        ],
                      ),
                      ...ventesParEmploye.map((e) => pw.TableRow(
                            children: [
                              _cellule(e.key),
                              _cellule("${e.value.toStringAsFixed(0)} FCFA")
                            ],
                          )),
                    ],
                  ),
                pw.SizedBox(height: 20),
                pw.Text("Détail des ventes",
                    style: pw.TextStyle(fontSize: 13,
                        fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 6),
                if (ventes.isEmpty)
                  pw.Text("Aucune vente sur cette période",
                      style: const pw.TextStyle(fontSize: 10,
                          color: PdfColors.grey700))
                else
                  pw.Table(
                    border: pw.TableBorder.all(width: 0.5,
                        color: PdfColors.grey400),
                    columnWidths: {
                      0: const pw.FlexColumnWidth(1.5),
                      1: const pw.FlexColumnWidth(2),
                      2: const pw.FlexColumnWidth(2),
                      3: const pw.FlexColumnWidth(2),
                      4: const pw.FlexColumnWidth(1.5),
                    },
                    children: [
                      pw.TableRow(
                        decoration: const pw.BoxDecoration(
                            color: PdfColors.grey300),
                        children: [
                          _celluleEntete("N° Facture"),
                          _celluleEntete("Date/Heure"),
                          _celluleEntete("Client"),
                          _celluleEntete("Vendeur"),
                          _celluleEntete("Total"),
                        ],
                      ),
                      ...ventes.map((v) => pw.TableRow(
                            children: [
                              _cellule(v.numeroFacture),
                              _cellule(formatDateHeure.format(v.dateVente)),
                              _cellule(v.clientNom),
                              _cellule(v.vendeurNom),
                              _cellule("${v.total.toStringAsFixed(0)} FCFA"),
                            ],
                          )),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );

    final dossier = await getApplicationDocumentsDirectory();
    final horodatage = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final cheminFichier = '${dossier.path}/rapport_$horodatage.pdf';
    final fichier = File(cheminFichier);
    await fichier.writeAsBytes(await pdf.save());
    return cheminFichier;
  }

  pw.Widget _celluleEntete(String texte) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(4),
      child: pw.Text(texte,
          style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
    );
  }

  pw.Widget _cellule(String texte) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(4),
      child: pw.Text(texte, style: const pw.TextStyle(fontSize: 9)),
    );
  }
}