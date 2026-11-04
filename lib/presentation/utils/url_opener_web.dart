import 'package:web/web.dart' as web;

/// Ouvre [url] dans un nouvel onglet, sans lien vers le BO (`noopener`).
void openExternalUrl(String url) {
  web.window.open(url, '_blank', 'noopener,noreferrer');
}
