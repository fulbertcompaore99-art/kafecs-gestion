import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../../core/services/auth_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/product_model.dart';
import '../../../data/models/client_model.dart';
import '../../../data/models/sale_item_model.dart';
import '../../../data/repositories/product_repository.dart';
import '../../../data/repositories/client_repository.dart';
import '../../../data/repositories/sale_repository.dart';
import '../invoice/facture_preview_screen.dart';

class NouvelleVenteScreen extends StatefulWidget {
  const NouvelleVenteScreen({super.key});

  @override
  State<NouvelleVenteScreen> createState() => _NouvelleVenteScreenState();
}

class _NouvelleVenteScreenState extends State<NouvelleVenteScreen> {
  final _productRepository = ProductRepository();
  final _clientRepository = ClientRepository();
  final _saleRepository = SaleRepository();
  final _uuid = const Uuid();

  final _clientNomController = TextEditingController();
  final _clientAdresseController = TextEditingController();
  final _montantVerseController = TextEditingController();

  List<ProductModel> _produitsDisponibles = [];
  final List<SaleItemModel> _panier = [];
  bool _chargement = true;
  bool _enregistrement = false;
  bool _paiementPartiel = false;

  double get _total => _panier.fold(0, (somme, item) => somme + item.prixTotal);

  double get _montantVerse {
    if (!_paiementPartiel) return _total;
    return double.tryParse(_montantVerseController.text) ?? 0;
  }

  double get _resteAPayer => _total - _montantVerse;

  @override
  void initState() {
    super.initState();
    _chargerProduits();
  }

  @override
  void dispose() {
    _clientNomController.dispose();
    _clientAdresseController.dispose();
    _montantVerseController.dispose();
    super.dispose();
  }

  Future<void> _chargerProduits() async {
    setState(() => _chargement = true);
    final liste = await _productRepository.listerTousLesProduits();
    setState(() {
      _produitsDisponibles = liste;
      _chargement = false;
    });
  }

  void _ajouterAuPanier(ProductModel produit) {
    showDialog(
      context: context,
      builder: (_) => _DialogueQuantite(
        produit: produit,
        onConfirmer: (quantite) {
          setState(() {
            _panier.add(SaleItemModel(
              id: _uuid.v4(),
              saleId: '',
              productId: produit.id,
              designation: produit.nom,
              quantite: quantite,
              prixUnitaire: produit.prixVente,
            ));
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("${produit.nom} ajouté au panier"), duration: const Duration(seconds: 1)),
          );
        },
      ),
    );
  }

  void _retirerDuPanier(int index) {
    setState(() => _panier.removeAt(index));
  }

  Future<void> _choisirClientFidele() async {
    final client = await showDialog<ClientModel>(
      context: context,
      builder: (_) => _DialogueChoixClientFidele(clientRepository: _clientRepository),
    );
    if (client != null) {
      setState(() {
        _clientNomController.text = client.nom;
        _clientAdresseController.text = client.adresse;
      });
    }
  }

  Future<void> _validerVente() async {
    if (_panier.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Ajoutez au moins un produit"), backgroundColor: Colors.orange),
      );
      return;
    }
    if (_clientNomController.text.trim().isEmpty || _clientAdresseController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Renseignez le nom et l'adresse du client"), backgroundColor: Colors.orange),
      );
      return;
    }
    if (_paiementPartiel && (_montantVerseController.text.isEmpty || double.tryParse(_montantVerseController.text) == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Indiquez le montant versé"), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _enregistrement = true);

    try {
      final authService = context.read<AuthService>();
      final vendeur = authService.utilisateurConnecte!;

      final vente = await _saleRepository.creerVente(
        clientId: '',
        clientNom: _clientNomController.text.trim(),
        clientAdresse: _clientAdresseController.text.trim(),
        vendeurId: vendeur.id,
        vendeurNom: vendeur.nomComplet,
        articles: _panier,
        montantPaye: _montantVerse,
      );

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => FacturePreviewScreen(vente: vente)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur : $e"), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _enregistrement = false);
    }
  }

  Widget _listeProduits() {
    if (_chargement) return const Center(child: CircularProgressIndicator());
    if (_produitsDisponibles.isEmpty) {
      return const Center(child: Text("Aucun produit en stock"));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _produitsDisponibles.length,
      itemBuilder: (context, index) {
        final produit = _produitsDisponibles[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            title: Text(produit.nom),
            subtitle: Text(
              "${produit.prixVente.toStringAsFixed(0)} FCFA • Stock: ${produit.quantiteStock} ${produit.unite}",
            ),
            trailing: IconButton(
              icon: const Icon(Icons.add_circle, color: AppTheme.primaryColor),
              onPressed: produit.quantiteStock > 0 ? () => _ajouterAuPanier(produit) : null,
            ),
          ),
        );
      },
    );
  }

  Widget _panierEtClient() {
    return SingleChildScrollView(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Informations client", style: TextStyle(fontWeight: FontWeight.bold)),
                        TextButton.icon(
                          onPressed: _choisirClientFidele,
                          icon: const Icon(Icons.star, size: 16),
                          label: const Text("Client fidèle"),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: _clientNomController,
                      decoration: const InputDecoration(
                        labelText: "Nom du client *",
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _clientAdresseController,
                      decoration: const InputDecoration(
                        labelText: "Adresse *",
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          _panier.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: Text("Panier vide")),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: _panier.length,
                  itemBuilder: (context, index) {
                    final item = _panier[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 6),
                      child: ListTile(
                        dense: true,
                        title: Text(item.designation),
                        subtitle: Text(
                          "${item.quantite} x ${item.prixUnitaire.toStringAsFixed(0)} = ${item.prixTotal.toStringAsFixed(0)} FCFA",
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                          onPressed: () => _retirerDuPanier(index),
                        ),
                      ),
                    );
                  },
                ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text("Paiement partiel / à crédit"),
                  value: _paiementPartiel,
                  onChanged: (valeur) => setState(() => _paiementPartiel = valeur),
                ),
                if (_paiementPartiel) ...[
                  TextField(
                    controller: _montantVerseController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Montant versé maintenant (FCFA)",
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 8),
                  if (_resteAPayer > 0)
                    Text(
                      "Reste à payer : ${_resteAPayer.toStringAsFixed(0)} FCFA",
                      style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                    ),
                  const SizedBox(height: 8),
                ],
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("TOTAL", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text(
                      "${_total.toStringAsFixed(0)} FCFA",
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _enregistrement ? null : _validerVente,
                    child: _enregistrement
                        ? const SizedBox(
                            height: 20, width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text("Valider la vente"),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final largeurEcran = MediaQuery.of(context).size.width;
    final estMobile = largeurEcran < 700;

    if (estMobile) {
      return DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            title: const Text("Nouvelle vente"),
            bottom: TabBar(
              tabs: [
                const Tab(icon: Icon(Icons.inventory_2), text: "Produits"),
                Tab(
                  icon: Badge(
                    label: Text(_panier.length.toString()),
                    isLabelVisible: _panier.isNotEmpty,
                    child: const Icon(Icons.shopping_cart),
                  ),
                  text: "Panier",
                ),
              ],
            ),
          ),
          body: TabBarView(
            children: [
              _listeProduits(),
              _panierEtClient(),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Nouvelle vente")),
      body: Row(
        children: [
          Expanded(flex: 3, child: _listeProduits()),
          const VerticalDivider(width: 1),
          Expanded(
            flex: 2,
            child: Container(color: AppTheme.backgroundColor, child: _panierEtClient()),
          ),
        ],
      ),
    );
  }
}

class _DialogueQuantite extends StatefulWidget {
  final ProductModel produit;
  final Function(int) onConfirmer;

  const _DialogueQuantite({required this.produit, required this.onConfirmer});

  @override
  State<_DialogueQuantite> createState() => _DialogueQuantiteState();
}

class _DialogueQuantiteState extends State<_DialogueQuantite> {
  final _controller = TextEditingController(text: '1');

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.produit.nom),
      content: TextField(
        controller: _controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: "Quantité (${widget.produit.unite})",
          border: const OutlineInputBorder(),
        ),
        autofocus: true,
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text("Annuler")),
        ElevatedButton(
          onPressed: () {
            final quantite = int.tryParse(_controller.text) ?? 0;
            if (quantite > 0) {
              widget.onConfirmer(quantite);
              Navigator.of(context).pop();
            }
          },
          child: const Text("Ajouter"),
        ),
      ],
    );
  }
}

class _DialogueChoixClientFidele extends StatefulWidget {
  final ClientRepository clientRepository;

  const _DialogueChoixClientFidele({required this.clientRepository});

  @override
  State<_DialogueChoixClientFidele> createState() => _DialogueChoixClientFideleState();
}

class _DialogueChoixClientFideleState extends State<_DialogueChoixClientFidele> {
  List<ClientModel> _clients = [];
  bool _chargement = true;

  @override
  void initState() {
    super.initState();
    _chargerClients();
  }

  Future<void> _chargerClients() async {
    final liste = await widget.clientRepository.listerTousLesClients();
    setState(() {
      _clients = liste;
      _chargement = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Choisir un client fidèle"),
      content: SizedBox(
        width: 350,
        height: 300,
        child: _chargement
            ? const Center(child: CircularProgressIndicator())
            : _clients.isEmpty
                ? const Center(child: Text("Aucun client fidèle enregistré"))
                : ListView.builder(
                    itemCount: _clients.length,
                    itemBuilder: (context, index) {
                      final client = _clients[index];
                      return ListTile(
                        title: Text(client.nom),
                        subtitle: Text(client.adresse),
                        onTap: () => Navigator.of(context).pop(client),
                      );
                    },
                  ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text("Annuler")),
      ],
    );
  }
}