import 'package:back_office_tribuneo_v2/domain/models/paginated_result.dart';

// Recherche faite dans le back-office pour les listes que l'API pagine sans
// filtre (écritures comptables, documents) : on charge toute la liste une
// fois, puis on filtre localement.

const Map<String, String> _accents = {
  'à': 'a',
  'â': 'a',
  'ä': 'a',
  'á': 'a',
  'ã': 'a',
  'ç': 'c',
  'é': 'e',
  'è': 'e',
  'ê': 'e',
  'ë': 'e',
  'î': 'i',
  'ï': 'i',
  'í': 'i',
  'ì': 'i',
  'ô': 'o',
  'ö': 'o',
  'ó': 'o',
  'ò': 'o',
  'õ': 'o',
  'ù': 'u',
  'û': 'u',
  'ü': 'u',
  'ú': 'u',
  'ÿ': 'y',
  'ñ': 'n',
  'œ': 'oe',
  'æ': 'ae',
};

/// Texte comparable : minuscules, sans accents, espaces (y compris
/// insécables) réduits à un seul.
String searchKey(String? text) {
  if (text == null || text.isEmpty) return '';
  final StringBuffer buffer = StringBuffer();
  for (final String char in text.toLowerCase().split('')) {
    buffer.write(_accents[char] ?? char);
  }
  return buffer.toString().replaceAll(RegExp(r'[\s\u00A0\u202F]+'), ' ').trim();
}

/// `true` si chaque mot de [query] figure dans l'un des [fields] (ordre et
/// casse indifférents, accents ignorés). Une recherche vide correspond à tout.
bool matchesSearch(String query, Iterable<String?> fields) {
  final List<String> terms =
      searchKey(query).split(' ').where((t) => t.isNotEmpty).toList();
  if (terms.isEmpty) return true;
  final String haystack = fields.map(searchKey).join(' ');
  return terms.every(haystack.contains);
}

/// Charge toutes les pages de [fetch] ([pageSize] éléments par appel, au plus
/// [maxPages] appels) et les renvoie dans l'ordre de l'API.
Future<List<T>> fetchAllPages<T>(
  Future<PaginatedResult<T>> Function(int limit, int offset) fetch, {
  int pageSize = 200,
  int maxPages = 100,
}) async {
  final List<T> all = [];
  for (int page = 0; page < maxPages; page++) {
    final PaginatedResult<T> result = await fetch(pageSize, all.length);
    all.addAll(result.items);
    final bool lastPage = result.items.length < pageSize ||
        (result.total > 0 && all.length >= result.total);
    if (lastPage) break;
  }
  return all;
}
