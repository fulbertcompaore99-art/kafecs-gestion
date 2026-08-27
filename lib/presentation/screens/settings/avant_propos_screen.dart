import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Écran affichant l'avant-propos du logiciel : présentation du projet
/// et informations sur le développeur.
class AvantProposScreen extends StatelessWidget {
  const AvantProposScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("À propos du logiciel")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 650),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Bloc développeur
                Align(
                  alignment: Alignment.centerRight,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        "FCTECH",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                      ),
                      const SizedBox(height: 4),
                      const Text("Compaoré Fulbert", style: TextStyle(color: Colors.grey)),
                      const Text("Ingénieur en Systèmes d'Information et Réseaux", style: TextStyle(color: Colors.grey, fontSize: 13)),
                      const Text("Développeur d'applications — Freelance", style: TextStyle(color: Colors.grey, fontSize: 13)),
                      const Text("Tél : 66 97 15 56 / 74 98 14 99", style: TextStyle(color: Colors.grey, fontSize: 13)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(thickness: 1.5, color: AppTheme.primaryColor),
                const SizedBox(height: 24),

                const Center(
                  child: Text(
                    "AVANT-PROPOS",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.primaryColor, letterSpacing: 1),
                  ),
                ),
                const SizedBox(height: 24),

                const _Paragraphe(
                  "Le présent document accompagne la livraison du logiciel de gestion développé pour le compte de l'entreprise KAFECS (Kaf. Eugène Commerce et Service), spécialisée dans la construction, le commerce et les services, basée à Ziniaré, Burkina Faso.",
                ),
                const _Paragraphe(
                  "Ce logiciel a été conçu, développé et livré dans le cadre d'une prestation freelance, à la demande du client, avec pour objectif de répondre à un besoin concret de digitalisation de la gestion quotidienne de son activité commerciale : suivi des stocks, facturation, gestion de caisse, suivi des ventes à crédit, gestion des dépenses et des utilisateurs, ainsi que la génération de rapports d'activité.",
                ),
                const _Paragraphe(
                  "L'application a été développée avec le framework Flutter, permettant un fonctionnement natif aussi bien sur téléphone Android que sur ordinateur, avec une base de données locale garantissant un fonctionnement continu même en l'absence de connexion internet, complétée par une synchronisation automatique vers le cloud (Firebase) dès qu'une connexion est disponible.",
                ),
                const _Paragraphe(
                  "Une attention particulière a été portée à la simplicité d'utilisation, à la séparation claire des rôles entre le Propriétaire et le Secrétaire/Caissier, ainsi qu'à la fiabilité du système sur le long terme.",
                ),
                const _Paragraphe(
                  "Nous restons disponibles pour toute assistance technique, formation à l'utilisation, ou évolution future du logiciel.",
                ),

                const SizedBox(height: 32),
                Align(
                  alignment: Alignment.centerRight,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: const [
                      Text("Fait pour la remise du logiciel,", style: TextStyle(fontStyle: FontStyle.italic)),
                      SizedBox(height: 4),
                      Text("Compaoré Fulbert", style: TextStyle(fontWeight: FontWeight.bold)),
                      Text("FCTECH", style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Paragraphe extends StatelessWidget {
  final String texte;
  const _Paragraphe(this.texte);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        texte,
        textAlign: TextAlign.justify,
        style: const TextStyle(fontSize: 14, height: 1.5),
      ),
    );
  }
}