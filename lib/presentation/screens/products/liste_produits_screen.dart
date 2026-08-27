import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/product_model.dart';
import '../../../data/repositories/product_repository.dart';

class ListeProduitsScreen extends StatefulWidget {
  final bool lectureSeule;

  const ListeProduitsScreen({super.key, this.lectureSeule = false});

  @override
  State<ListeProduitsScreen> createState() => _ListeProduitsScreenState();
}

class _ListeProduitsScreenState extends State<ListeProduitsScreen> {
  final _productRepository = ProductRepository();
  List<ProductModel> _produits = [];
  bool _chargement = true;
  String _recherche = '';

  @override
  void initState() {
    super.initState();
    _chargerProduits();
  }

  Future<void> _chargerProduits() async {
    setState(() => _chargement = true);
    final liste = await _productRepository.listerTousLesProduits();
    setState(() {
      _produits = liste;
      _chargement = false;
    });
  }

  List<ProductModel> get _produitsFiltres {
    if (_recherche.isEmpty) return _produits;
    return _produits
        .where((p) => p.nom.toLowerCase().contains(_recherche.toLowerCase()))
        .toList();
  }

  void _ouvrirFormulaireCreation() {
    showDialog(
      context: context,
      builder: (_) => _FormulaireProduitDialog(onSauvegarde: _chargerProduits),
    );
  }

  void _ouvrirFormulaireModification(ProductModel produit) {
    showDialog(
      context: context,
      builder: (_) => _FormulaireProduitDialog(
        produitExistant: produit,
        onSauvegarde: _chargerProduits,
      ),
    );
  }

  Future<void> _confirmerSuppression(ProductModel produit) async {
    final confirme = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Confirmer la suppression"),
        content: Text("Supprimer définitivement « ${produit.nom} » ?"),
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
      await _productRepository.supprimerProduit(produit.id);
      _chargerProduits();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.lectureSeule ? "Consultation du stock" : "Gestion des stocks")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: const InputDecoration(
                hintText: "Rechercher un produit...",
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
                : _produitsFiltres.isEmpty
                    ? const Center(child: Text("Aucun produit trouvé"))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: _produitsFiltres.length,
                        itemBuilder: (context, index) {
                          final produit = _produitsFiltres[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: produit.stockBas
                                    ? Colors.red.shade100
                                    : AppTheme.primaryColor.withOpacity(0.1),
                                child: Icon(
                                  Icons.inventory_2,
                                  color: produit.stockBas ? Colors.red : AppTheme.primaryColor,
                                ),
                              ),
                              title: Text(produit.nom),
                              subtitle: Text(
                                "Stock: ${produit.quantiteStock} ${produit.unite} • Prix: ${produit.prixVente.toStringAsFixed(0)} FCFA"
                                "${produit.stockBas ? ' ⚠️ Stock bas' : ''}",
                                style: TextStyle(
                                  color: produit.stockBas ? Colors.red : null,
                                  fontWeight: produit.stockBas ? FontWeight.bold : null,
                                ),
                              ),
                              trailing: widget.lectureSeule
                                  ? null
                                  : Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit, color: Colors.blue),
                                          onPressed: () => _ouvrirFormulaireModification(produit),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete, color: Colors.red),
                                          onPressed: () => _confirmerSuppression(produit),
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
      floatingActionButton: widget.lectureSeule
          ? null
          : FloatingActionButton.extended(
              onPressed: _ouvrirFormulaireCreation,
              icon: const Icon(Icons.add),
              label: const Text("Nouveau produit"),
            ),
    );
  }
}

/// Boîte de dialogue pour créer ou modifier un produit
class _FormulaireProduitDialog extends StatefulWidget {
  final ProductModel? produitExistant;
  final VoidCallback onSauvegarde;

  const _FormulaireProduitDialog({this.produitExistant, required this.onSauvegarde});

  @override
  State<_FormulaireProduitDialog> createState() => _FormulaireProduitDialogState();
}

class _FormulaireProduitDialogState extends State<_FormulaireProduitDialog> {
  final _formKey = GlobalKey<FormState>();
  final _productRepository = ProductRepository();

  late TextEditingController _nomController;
  late TextEditingController _prixAchatController;
  late TextEditingController _prixVenteController;
  late TextEditingController _quantiteController;
  late TextEditingController _uniteController;
  late TextEditingController _seuilAlerteController;

  bool _chargement = false;
  bool get _estModification => widget.produitExistant != null;

  @override
  void initState() {
    super.initState();
    final p = widget.produitExistant;
    _nomController = TextEditingController(text: p?.nom ?? '');
    _prixAchatController = TextEditingController(text: p?.prixAchat.toStringAsFixed(0) ?? '');
    _prixVenteController = TextEditingController(text: p?.prixVente.toStringAsFixed(0) ?? '');
    _quantiteController = TextEditingController(text: p?.quantiteStock.toString() ?? '');
    _uniteController = TextEditingController(text: p?.unite ?? '');
    _seuilAlerteController = TextEditingController(text: p?.seuilAlerte.toString() ?? '5');
  }

  @override
  void dispose() {
    _nomController.dispose();
    _prixAchatController.dispose();
    _prixVenteController.dispose();
    _quantiteController.dispose();
    _uniteController.dispose();
    _seuilAlerteController.dispose();
    super.dispose();
  }

  Future<void> _sauvegarder() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _chargement = true);

    try {
      if (_estModification) {
        final produitModifie = ProductModel(
          id: widget.produitExistant!.id,
          nom: _nomController.text.trim(),
          categorieId: widget.produitExistant!.categorieId,
          prixAchat: double.parse(_prixAchatController.text),
          prixVente: double.parse(_prixVenteController.text),
          quantiteStock: int.parse(_quantiteController.text),
          unite: _uniteController.text.trim(),
          reference: widget.produitExistant!.reference,
          seuilAlerte: int.parse(_seuilAlerteController.text),
          dateCreation: widget.produitExistant!.dateCreation,
        );
        await _productRepository.modifierProduit(produitModifie);
      } else {
        await _productRepository.creerProduit(
          nom: _nomController.text.trim(),
          prixAchat: double.parse(_prixAchatController.text),
          prixVente: double.parse(_prixVenteController.text),
          quantiteStock: int.parse(_quantiteController.text),
          unite: _uniteController.text.trim(),
          seuilAlerte: int.parse(_seuilAlerteController.text),
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
      title: Text(_estModification ? "Modifier le produit" : "Nouveau produit"),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nomController,
                decoration: const InputDecoration(labelText: "Nom du produit"),
                validator: (v) => (v == null || v.trim().isEmpty) ? "Requis" : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _prixAchatController,
                      decoration: const InputDecoration(labelText: "Prix d'achat"),
                      keyboardType: TextInputType.number,
                      validator: (v) => (v == null || double.tryParse(v) == null) ? "Invalide" : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _prixVenteController,
                      decoration: const InputDecoration(labelText: "Prix de vente"),
                      keyboardType: TextInputType.number,
                      validator: (v) => (v == null || double.tryParse(v) == null) ? "Invalide" : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _quantiteController,
                      decoration: const InputDecoration(labelText: "Quantité en stock"),
                      keyboardType: TextInputType.number,
                      validator: (v) => (v == null || int.tryParse(v) == null) ? "Invalide" : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _uniteController,
                      decoration: const InputDecoration(labelText: "Unité (sac, pièce...)"),
                      validator: (v) => (v == null || v.trim().isEmpty) ? "Requis" : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _seuilAlerteController,
                decoration: const InputDecoration(labelText: "Seuil d'alerte stock bas"),
                keyboardType: TextInputType.number,
                validator: (v) => (v == null || int.tryParse(v) == null) ? "Invalide" : null,
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