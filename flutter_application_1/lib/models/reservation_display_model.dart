import 'package:flutter/material.dart';

class ReservationDisplay {
  final int id;
  final String status;
  final String lieuDepart;
  final String lieuArrivee;
  final String transporteurNom; // Nom du transporteur OU du client selon le contexte
  final String transporteurPhone;
  final int transporteurId; // ID du transporteur OU du client selon le contexte
  final double rating;
  final DateTime dateReservation;
  final String typeMarchandise;
  final double poids;
  final double volume;
  final int camionId;

  ReservationDisplay({
    required this.id,
    required this.status,
    required this.lieuDepart,
    required this.lieuArrivee,
    required this.transporteurNom,
    required this.transporteurPhone,
    required this.transporteurId,
    required this.rating,
    required this.dateReservation,
    required this.typeMarchandise,
    required this.poids,
    required this.volume,
    required this.camionId,
  });

  factory ReservationDisplay.fromJson(Map<String, dynamic> json) {
    return ReservationDisplay(
      id: json['id'] ?? 0,
      status: json['status'] ?? json['statut'] ?? 'EN_ATTENTE',
      lieuDepart: json['lieuDepart'] ?? '',
      lieuArrivee: json['lieuArrivee'] ?? '',
      transporteurNom: json['transporteurNom'] ?? '',
      transporteurPhone: json['camion']?['transporteur']?['phone'] ?? '',
      transporteurId: _parseTransporteurId(json['camion']?['transporteur']?['id']),
      rating: (json['rating'] ?? 0).toDouble(),
      dateReservation: DateTime.parse(json['dateReservation'] ?? DateTime.now().toIso8601String()),
      typeMarchandise: json['typeMarchandise'] ?? 'Normal',
      poids: (json['poids'] ?? 0).toDouble(),
      volume: (json['volume'] ?? 0).toDouble(),
      camionId: _parseCamionId(json['camion']?['id']),
    );
  }

  // Méthode helper pour parser l'ID du transporteur
  static int _parseTransporteurId(dynamic id) {
    if (id == null) return 0;
    if (id is int) return id;
    if (id is String) {
      try {
        return int.parse(id);
      } catch (e) {
        print('Erreur parsing transporteurId: $e');
        return 0;
      }
    }
    if (id is num) {
      return id.toInt();
    }
    return 0;
  }

  // Méthode helper pour parser l'ID du camion
  static int _parseCamionId(dynamic id) {
    if (id == null) return 0;
    if (id is int) return id;
    if (id is String) {
      try {
        return int.parse(id);
      } catch (e) {
        print('Erreur parsing camionId: $e');
        return 0;
      }
    }
    if (id is num) {
      return id.toInt();
    }
    return 0;
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