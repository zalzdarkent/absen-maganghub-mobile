class DraftFields {
  final String aktivitas;
  final String pembelajaran;
  final String kendala;

  const DraftFields({
    this.aktivitas = '',
    this.pembelajaran = '',
    this.kendala = '',
  });

  bool get isEmpty =>
      aktivitas.trim().isEmpty &&
      pembelajaran.trim().isEmpty &&
      kendala.trim().isEmpty;

  bool get isCompliant =>
      aktivitas.trim().length >= 100 &&
      pembelajaran.trim().length >= 100 &&
      kendala.trim().length >= 100;

  factory DraftFields.fromJson(Map<String, dynamic> json) {
    return DraftFields(
      aktivitas: json['aktivitas'] as String? ?? '',
      pembelajaran: json['pembelajaran'] as String? ?? '',
      kendala: json['kendala'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'aktivitas': aktivitas,
      'pembelajaran': pembelajaran,
      'kendala': kendala,
    };
  }

  DraftFields copyWith({
    String? aktivitas,
    String? pembelajaran,
    String? kendala,
  }) {
    return DraftFields(
      aktivitas: aktivitas ?? this.aktivitas,
      pembelajaran: pembelajaran ?? this.pembelajaran,
      kendala: kendala ?? this.kendala,
    );
  }
}

class LogbookEntry extends DraftFields {
  final int no;
  final String tanggal;
  final int rowNumber;
  final int? userId;

  const LogbookEntry({
    required this.no,
    required this.tanggal,
    required this.rowNumber,
    this.userId,
    required super.aktivitas,
    required super.pembelajaran,
    required super.kendala,
  });

  @override
  LogbookEntry copyWith({
    int? no,
    String? tanggal,
    int? rowNumber,
    int? userId,
    String? aktivitas,
    String? pembelajaran,
    String? kendala,
  }) {
    return LogbookEntry(
      no: no ?? this.no,
      tanggal: tanggal ?? this.tanggal,
      rowNumber: rowNumber ?? this.rowNumber,
      userId: userId ?? this.userId,
      aktivitas: aktivitas ?? this.aktivitas,
      pembelajaran: pembelajaran ?? this.pembelajaran,
      kendala: kendala ?? this.kendala,
    );
  }

  factory LogbookEntry.fromJson(Map<String, dynamic> json) {
    return LogbookEntry(
      no: (json['no'] as num?)?.toInt() ?? 0,
      tanggal: json['tanggal'] as String? ?? '',
      rowNumber: (json['rowNumber'] as num?)?.toInt() ?? 0,
      userId: (json['userId'] ?? json['user_id'] as num?)?.toInt(),
      aktivitas: json['aktivitas'] as String? ?? '',
      pembelajaran: json['pembelajaran'] as String? ?? '',
      kendala: json['kendala'] as String? ?? '',
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'no': no,
      'tanggal': tanggal,
      'rowNumber': rowNumber,
      if (userId != null) 'userId': userId,
      'aktivitas': aktivitas,
      'pembelajaran': pembelajaran,
      'kendala': kendala,
    };
  }

  /// Parses dd/MM/yyyy to DateTime
  DateTime? parseDate() {
    try {
      final parts = tanggal.split('/');
      if (parts.length == 3) {
        final day = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        final year = int.parse(parts[2]);
        return DateTime(year, month, day);
      }
    } catch (_) {}
    return null;
  }
}
