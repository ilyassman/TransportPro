class AvailableReservation {
  final int id;
  final String typeMarchandise;
  final double volume;
  final double poids;
  final String lieuDepart;
  final String lieuArrivee;
  final DateTime dateReservation;
  final DateTime? dateLivraison;
  final String statut;
  final double tarif;
  final String modePaiement;
  final Map<String, dynamic> chargeur; // Informations du chargeur
  final DateTime createdAt;

  AvailableReservation({
    required this.id,
    required this.typeMarchandise,
    required this.volume,
    required this.poids,
    required this.lieuDepart,
    required this.lieuArrivee,
    required this.dateReservation,
    this.dateLivraison,
    required this.statut,
    required this.tarif,
    required this.modePaiement,
    required this.chargeur,
    required this.createdAt,
  });

  factory AvailableReservation.fromJson(Map<String, dynamic> json) {
    return AvailableReservation(
      id: json['id'],
      typeMarchandise: json['typeMarchandise'] ?? '',
      volume: (json['volume'] as num).toDouble(),
      poids: (json['poids'] as num).toDouble(),
      lieuDepart: json['lieuDepart'] ?? '',
      lieuArrivee: json['lieuArrivee'] ?? '',
      dateReservation: DateTime.parse(json['dateReservation']),
      dateLivraison: json['dateLivraison'] != null 
          ? DateTime.parse(json['dateLivraison']) 
          : null,
      statut: json['statut'] ?? 'EN_ATTENTE',
      tarif: (json['tarif'] as num).toDouble(),
      modePaiement: json['modePaiement'] ?? '',
      chargeur: json['chargeur'] ?? {},
      createdAt: DateTime.parse(json['dateReservation']),
    );
  }

  // Méthode pour obtenir le nom du chargeur
  String get chargeurNom {
    return chargeur['nom'] ?? chargeur['username'] ?? 'Chargeur';
  }

  // Méthode pour obtenir l'ID du chargeur
  int get chargeurId {
    return chargeur['id'] ?? 0;
  }

  // Méthode pour obtenir la couleur du statut
  String getStatusColor() {
    switch (statut.toUpperCase()) {
      case 'EN_ATTENTE':
        return '#6B7280'; // Gris
      case 'EN_COURS':
        return '#F59E0B'; // Orange
      case 'TERMINEE':
        return '#10B981'; // Vert
      default:
        return '#6B7280'; // Gris par défaut
    }
  }

  // Méthode pour obtenir l'icône du statut
  String getStatusIcon() {
    switch (statut.toUpperCase()) {
      case 'EN_ATTENTE':
        return '⏳';
      case 'EN_COURS':
        return '🚚';
      case 'TERMINEE':
        return '✅';
      default:
        return '📋';
    }
  }

  // Méthode pour formater la date
  String getFormattedDate() {
    final now = DateTime.now();
    final difference = now.difference(dateReservation);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}j';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else {
      return '${difference.inMinutes}min';
    }
  }

  // Méthode pour formater le tarif
  String getFormattedTarif() {
    return '${tarif.toStringAsFixed(0)} DH';
  }

  // Méthode pour formater le volume
  String getFormattedVolume() {
    return '${volume.toStringAsFixed(1)} m³';
  }

  // Méthode pour formater le poids
  String getFormattedPoids() {
    return '${poids.toStringAsFixed(0)} kg';
  }
} 