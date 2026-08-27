import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/services/auth_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../routes/app_routes.dart';
import '../sales/nouvelle_vente_screen.dart';
import '../sales/historique_ventes_screen.dart';
import '../cash/gestion_caisse_screen.dart';
import '../products/liste_produits_screen.dart';
import '../clients/liste_clients_screen.dart';
import '../settings/profil_screen.dart';
import '../expenses/liste_depenses_screen.dart';
import '../sales/dettes_clients_screen.dart';


class DashboardSecretaireScreen extends StatelessWidget {
  const DashboardSecretaireScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final utilisateur = authService.utilisateurConnecte;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Tableau de bord — Secrétaire"),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            tooltip: "Mon profil",
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ProfilScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: "Déconnexion",
            onPressed: () {
              authService.deconnexion();
              Navigator.of(context).pushNamedAndRemoveUntil(
                AppRoutes.login,
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Bonjour, ${utilisateur?.nomComplet ?? ''}",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: GridView.count(
                crossAxisCount: MediaQuery.of(context).size.width > 700 ? 3 : 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                children: [
                  _CarteMenu(
                    icone: Icons.add_shopping_cart,
                    titre: "Nouvelle vente",
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const NouvelleVenteScreen()),
                    ),
                  ),
                  _CarteMenu(
                    icone: Icons.history,
                    titre: "Mes factures",
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => HistoriqueVentesScreen(
                          vendeurId: utilisateur?.id,
                          titre: "Mes factures",
                        ),
                      ),
                    ),
                  ),
                  _CarteMenu(
                    icone: Icons.point_of_sale,
                    titre: "Ma caisse",
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const GestionCaisseScreen()),
                    ),
                  ),
                  _CarteMenu(
                    icone: Icons.inventory_2,
                    titre: "Consulter stock",
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ListeProduitsScreen(lectureSeule: true)),
                    ),
                  ),
                  _CarteMenu(
                    icone: Icons.groups,
                    titre: "Clients",
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ListeClientsScreen()),
                    ),
                  ),
                  _CarteMenu(
                    icone: Icons.money_off,
                    titre: "Dépenses",
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ListeDepensesScreen()),
                    ),
                  ),
                 _CarteMenu(
                  icone: Icons.warning_amber,
                  titre: "Dettes clients",
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const DettesClientsScreen()),
                  ),
                ),
                
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CarteMenu extends StatelessWidget {
  final IconData icone;
  final String titre;
  final VoidCallback onTap;

  const _CarteMenu({required this.icone, required this.titre, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icone, size: 40, color: AppTheme.primaryColor),
            const SizedBox(height: 8),
            Text(titre, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}