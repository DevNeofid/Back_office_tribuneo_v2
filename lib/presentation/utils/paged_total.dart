import 'dart:math' as math;

/// Nombre total de lignes à annoncer à un tableau paginé
/// (`AsyncPaginatedDataTable2`) après avoir reçu [received] lignes à partir de
/// [startIndex], pour [limit] demandées.
///
/// Une page incomplète est forcément la dernière : on s'y arrête même si
/// l'API annonce davantage ([apiTotal]), sinon le tableau attend des lignes qui
/// n'arriveront jamais (chargement sans fin). Sans total de l'API, une page
/// pleine laisse supposer une page suivante.
///
/// Suppose [limit] inférieur ou égal au plafond de pagination de l'API.
int resolvePagedTotal({
  required int apiTotal,
  required int startIndex,
  required int received,
  required int limit,
}) {
  final int reached = startIndex + received;
  if (received < limit) return reached;
  if (apiTotal > 0) return math.max(apiTotal, reached);
  return reached + 1;
}
