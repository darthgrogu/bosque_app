class Arvore {
  final int id; // ID único da árvore (usaremos como código)
  final String nomeCientifico;
  final String? nomePopular; // Pode ser nulo
  final double latitude;
  final double longitude;
  final List<String> fotos; // URLs das fotos (por enquanto, strings)

  Arvore({
    required this.id,
    required this.nomeCientifico,
    this.nomePopular,
    required this.latitude,
    required this.longitude,
    required this.fotos,
  });

    // Método para converter um Map (vindo de um JSON, por exemplo) para Arvore
  factory Arvore.fromMap(Map<String, dynamic> map) {
    return Arvore(
      id: map['id'] as int,
      nomeCientifico: map['nomeCientifico'] as String,
      nomePopular: map['nomePopular'] as String?, // Permite nulos
      latitude: map['latitude'] as double,
      longitude: map['longitude'] as double,
      fotos: List<String>.from(map['fotos'] as List), // Converte a lista dinâmica
    );
  }

  // Método para converter uma Arvore para um Map (para salvar em banco de dados, por exemplo)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nomeCientifico': nomeCientifico,
      'nomePopular': nomePopular,
      'latitude': latitude,
      'longitude': longitude,
      'fotos': fotos,
    };
  }
}