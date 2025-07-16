class Camion {
  final int id;
  final String immatriculation;
  final String type;
  final double capacite;
  final String marque;
  final String modele;
  final bool disponible;
  final double latitude;
  final double longitude;

  Camion({
    required this.id,
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
      immatriculation: json['immatriculation'],
      type: json['type'],
      capacite: (json['capacite'] as num).toDouble(),
      marque: json['marque'],
      modele: json['modele'],
      disponible: json['disponible'],
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
    );
  }
} 