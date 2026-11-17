import 'package:flutter/foundation.dart';

/// Heure courante de l'application.
///
/// Tout le code passe par [Horloge.maintenant] au lieu de `DateTime.now()` : les tests peuvent ainsi
/// fixer la date et ne dépendent plus du jour où ils sont exécutés (rendez-vous à venir ou passés,
/// semaine de grossesse, nom du fichier exporté…).
abstract final class Horloge {
  static DateTime Function() _source = DateTime.now;

  static DateTime maintenant() => _source();

  /// Fixe l'heure renvoyée par [maintenant] (tests uniquement).
  @visibleForTesting
  static void fixer(DateTime instant) => _source = () => instant;

  /// Revient à l'heure réelle du téléphone.
  @visibleForTesting
  static void reinitialiser() => _source = DateTime.now;
}
