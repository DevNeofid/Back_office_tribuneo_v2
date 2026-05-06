import 'dart:html' as html;

void downloadCsvFromString(String csvData, String filename) {
  final blob = html.Blob(['\uFEFF', csvData], 'text/csv;charset=utf-8');

  final url = html.Url.createObjectUrlFromBlob(blob);

  final anchor = html.document.createElement('a') as html.AnchorElement
    ..href = url
    ..download = filename
    ..style.display = 'none';

  html.document.body?.append(anchor);
  anchor.click();
  anchor.remove();

  html.Url.revokeObjectUrl(url);
}
