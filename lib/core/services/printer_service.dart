import 'package:printing/printing.dart';

import '../../data/models/sale_model.dart';
import 'pdf_service.dart';

/// Service d'impression universel : fonctionne avec N'IMPORTE QUELLE imprimante
/// déjà installée/appairée sur l'appareil (thermique, A4, réseau, Bluetooth, USB...).
/// Utilise le système d'impression natif d'Android/Windows plutôt qu'un protocole
/// spécifique, donc aucune configuration liée à une marque/modèle n'est nécessaire.
class PrinterService {
  final PdfService _pdfService = PdfService();

  /// Ouvre la boîte de dialogue d'impression du système avec la facture,
  /// permettant à l'utilisateur de choisir n'importe quelle imprimante disponible.
  Future<void> imprimerFacture(SaleModel vente) async {
    final bytes = await _pdfService.genererFacturePdfBytes(vente);
    await Printing.layoutPdf(
      onLayout: (format) async => bytes,
      name: 'Facture_${vente.numeroFacture}',
    );
  }
}