class RecapModel {
  final String ringkasan;
  final List<String> highlights;
  final String kendalaTeratasi;
  final String saran;
  final int totalHari;
  final String rentang;

  const RecapModel({
    this.ringkasan = '',
    this.highlights = const [],
    this.kendalaTeratasi = '',
    this.saran = '',
    this.totalHari = 0,
    this.rentang = '',
  });

  factory RecapModel.fromJson(Map<String, dynamic> json) {
    return RecapModel(
      ringkasan: json['ringkasan'] as String? ?? '',
      highlights: (json['highlights'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      kendalaTeratasi: json['kendalaTeratasi'] as String? ?? '',
      saran: json['saran'] as String? ?? '',
      totalHari: (json['totalHari'] as num?)?.toInt() ?? 0,
      rentang: json['rentang'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ringkasan': ringkasan,
      'highlights': highlights,
      'kendalaTeratasi': kendalaTeratasi,
      'saran': saran,
      'totalHari': totalHari,
      'rentang': rentang,
    };
  }

  String toFormattedText({required String period}) {
    final buffer = StringBuffer();
    buffer.writeln('REKAP ${period.toUpperCase()} ($rentang) — $totalHari hari');
    buffer.writeln();
    buffer.writeln('RINGKASAN:');
    buffer.writeln(ringkasan);
    buffer.writeln();
    buffer.writeln('HIGHLIGHTS:');
    for (int i = 0; i < highlights.length; i++) {
      buffer.writeln('${i + 1}. ${highlights[i]}');
    }
    buffer.writeln();
    buffer.writeln('KENDALA TERATASI:');
    buffer.writeln(kendalaTeratasi);
    buffer.writeln();
    buffer.writeln('SARAN UNTUK PERIODE DEPAN:');
    buffer.writeln(saran);
    return buffer.toString();
  }
}
