/// Constantes générales de l'application

class AppConstants {
  // Informations de l'entreprise (affichées sur les factures)
  static const String nomEntreprise = "ENTREPRISE WEND KONTA EUGENE ET FRERES";
  static const String sigleEntreprise = "E.W.K.E.F";
  static const String activiteEntreprise =
      "Construction, Dessin des plans Bâtiments, Vente et location des matériels et divers, Confection de bâches, Livraison d'agrégats et divers.";
  static const String telephoneEntreprise = "75 77 18 92 / 51 79 25 96 / 58 65 19 01";

  // Mention légale fixe sur chaque facture
  static const String mentionFacture =
      "NB: Toute somme versée ne peut être remboursée";

  // Base de données
  static const String dbName = "ewkef_gestion.db";
  static const int dbVersion = 2;

  // Rôles utilisateurs
  static const String rolePropretaire = "proprietaire";
  static const String roleSecretaire = "secretaire";
}