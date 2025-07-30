import 'package:flutter/material.dart';

class ReservationDisplay {
  final int id;
  final String status;
  final String lieuDepart;
  final String lieuArrivee;
  final String transporteurNom;
  final double rating;
  final DateTime dateReservation;
  final String typeMarchandise;
  final double poids;
  final double volume;
  final int camionId; // Ajouté

  ReservationDisplay({
    required this.id,
    required this.status,
    required this.lieuDepart,
    required this.lieuArrivee,
    required this.transporteurNom,
    required this.rating,
    required this.dateReservation,
    required this.typeMarchandise,
    required this.poids,
    required this.volume,
    required this.camionId, // Ajouté
  });

  factory ReservationDisplay.fromJson(Map<String, dynamic> json) {
    return ReservationDisplay(
      id: json['id'],
      status: json['status'] ?? json['statut'],
      lieuDepart: json['lieuDepart'],
      lieuArrivee: json['lieuArrivee'],
      transporteurNom: json['transporteurNom'] ?? '',
      rating: (json['rating'] ?? 0).toDouble(),
      dateReservation: DateTime.parse(json['dateReservation']),
      typeMarchandise: json['typeMarchandise'],
      poids: (json['poids'] as num).toDouble(),
      volume: (json['volume'] as num).toDouble(),
      camionId: json['camion'] != null ? json['camion']['id'] as int : 0,
    );
  }

  // Méthode pour obtenir la couleur du statut
  Color getStatusColor() {
    switch (status.toUpperCase()) {
      case 'r':
        return const Color(0xFF10B981); // Vert
      case 'EN_COURS':
        return const Color(0xFFF59E0B); // Orange
      case 'EN_TRANSIT':
        return const Color(0xFF3B82F6); // Bleu
      case 'TERMINEE':
        return const Color(0xFF8B5CF6); // Violet
      case 'EN_ATTENTE':
        return const Color(0xFF6B7280); // Gris
      default:
        return const Color(0xFF6B7280); // Gris par défaut
    }
  }

  // Méthode pour obtenir l'icône du statut
  IconData getStatusIcon() {
    switch (status.toUpperCase()) {
      case 'CONFIRME':
        return Icons.check_circle;
      case 'EN_COURS':
        return Icons.hourglass_empty;
      case 'EN_TRANSIT':
        return Icons.local_shipping;
      case 'TERMINEE':
        return Icons.done_all;
      case 'EN_ATTENTE':
        return Icons.schedule;
      default:
        return Icons.info;
    }
  }
} 