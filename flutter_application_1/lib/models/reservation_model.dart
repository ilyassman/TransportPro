class ReservationModel {
  final int? id;
  final int? camionId;
  final String typeMarchandise;
  final double? volume;
  final double? poids;
  final String lieuDepart;
  final String lieuArrivee;
  final DateTime dateReservation;

  ReservationModel({
    this.id,
    required this.camionId,
    required this.typeMarchandise,
    this.volume,
    this.poids,
    required this.lieuDepart,
    required this.lieuArrivee,
    required this.dateReservation,
  });

  // Méthode pour s'assurer que les données sont en français pour la BDD
  String _getTypeMarchandiseForDB() {
    switch (typeMarchandise.toLowerCase()) {
      case 'normal':
      case 'عادي':
        return 'Normal';
      case 'réfrigéré':
      case 'refrigerated':
      case 'مبرد':
        return 'Réfrigéré';
      default:
        return typeMarchandise;
    }
  }

  Map<String, dynamic> toJson() => {
    if (camionId != null) 'camion': {'id': camionId},
    'typeMarchandise': _getTypeMarchandiseForDB(), // Utiliser la version française
    if (volume != null) 'volume': volume,
    if (poids != null) 'poids': poids,
    'lieuDepart': lieuDepart,
    'lieuArrivee': lieuArrivee,
    'dateReservation': dateReservation.toIso8601String(),
  };
} 