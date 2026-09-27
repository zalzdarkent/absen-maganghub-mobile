class Repository {
  final String id;
  final String label;
  final String url;

  const Repository({
    required this.id,
    required this.label,
    required this.url,
  });

  factory Repository.fromJson(Map<String, dynamic> json) {
    return Repository(
      id: json['id'] as String? ?? '',
      label: json['label'] as String? ?? '',
      url: json['url'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'url': url,
    };
  }

  Repository copyWith({String? id, String? label, String? url}) {
    return Repository(
      id: id ?? this.id,
      label: label ?? this.label,
      url: url ?? this.url,
    );
  }
}
