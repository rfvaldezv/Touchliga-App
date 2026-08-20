/// Implementación "vacía" para plataformas que no son web (por ahora
/// solo se usa desde la versión web, vía import condicional).
void descargarPdf(List<int> bytes, String nombreArchivo) {
  throw UnsupportedError('Descargar PDF solo está disponible en la versión web por ahora.');
}
