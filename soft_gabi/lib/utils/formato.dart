/// Formatea un monto en pesos con separador de miles argentino: 3500 -> "$3.500".
String pesos(num valor) {
  final entero = valor.round().toString();
  final conPuntos = entero.replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => '.',
  );
  return '\$$conPuntos';
}

/// Número de turno con ceros a la izquierda: 7 -> "#007".
String turno(int numero) => '#${numero.toString().padLeft(3, '0')}';

/// "24/09/2026 13:05"
String fechaHora(DateTime f) {
  String d2(int n) => n.toString().padLeft(2, '0');
  return '${d2(f.day)}/${d2(f.month)}/${f.year} ${d2(f.hour)}:${d2(f.minute)}';
}

bool mismoDia(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
