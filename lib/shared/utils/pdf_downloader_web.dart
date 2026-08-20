import 'dart:html' as html;

/// Dispara la descarga del PDF directo en el navegador (como
/// cualquier archivo descargado normal) -- de ahí se comparte
/// manualmente en WhatsApp.
void descargarPdf(List<int> bytes, String nombreArchivo) {
  final blob = html.Blob([bytes], 'application/pdf');
  final url = html.Url.createObjectUrlFromBlob(blob);
  final ancla = html.AnchorElement(href: url)
    ..setAttribute('download', nombreArchivo)
    ..click();
  html.Url.revokeObjectUrl(url);
}
