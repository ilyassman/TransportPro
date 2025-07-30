class Camion {
  final int? id;
  final String immatriculation;
  final String type;
  final double capacite;
  final String marque;
  final String modele;
  final bool disponible;
  final double latitude;
  final double longitude;

  Camion({
    this.id,
    required this.immatriculation,
    required this.type,
    required this.capacite,
    required this.marque,
    required this.modele,
    required this.disponible,
    required this.latitude,
    required this.longitude,
  });

  factory Camion.fromJson(Map<String, dynamic> json) {
    return Camion(
      id: json['id'],
      immatriculation: json['immatriculation'] ?? '',
      type: json['type'] ?? '',
      capacite: (json['capacite'] as num?)?.toDouble() ?? 0.0,
      marque: json['marque'] ?? '',
      modele: json['modele'] ?? '',
      disponible: json['disponible'] ?? false,
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
    );
  }
} 