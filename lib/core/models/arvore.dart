class Arvore {
  final String? id;
  final String accession;
  final String familyName;
  final String calcFullName;
  final String? vernacularName; // Pode ser nulo
  final double latitude; //Agora é String
  final double longitude; //Agora é String

  Arvore({
    this.id,
    required this.accession,
    required this.familyName,
    required this.calcFullName,
    this.vernacularName,
    required this.latitude,
    required this.longitude,
  });

  // Método para converter de Map (JSON) para Arvore
  factory Arvore.fromMap(Map<String, dynamic> map) {
    return Arvore(
      id: map['id'] as String,
      accession: map['accession'] as String,
      familyName: map['familyName'] as String,
      calcFullName: map['calcFullName'] as String,
      vernacularName: map['vernacularName'] as String?, // Pode ser nulo
      latitude: (map['latitude'] as num).toDouble(),
      longitude: map['longitude'] as double,
    );
  }

  // Método para converter de Arvore para Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'accession': accession,
      'familyName': familyName,
      'calcFullName': calcFullName,
      'vernacularName': vernacularName,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  Map<String, dynamic> toMapForCreate() {
    return {
      'accession': accession,
      'familyName': familyName,
      'calcFullName': calcFullName,
      'vernacularName': vernacularName,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}
