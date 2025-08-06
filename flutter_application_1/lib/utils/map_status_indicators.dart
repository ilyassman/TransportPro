import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'animated_status_badge.dart';
import 'animated_transit_indicator.dart';

class MapStatusIndicators {
  // Couleurs pour les différents états
  static const Color enCoursColor = Color(0xFFF59E0B); // Orange
  static const Color enTransitColor = Color(0xFF3B82F6); // Bleu
  static const Color termineeColor = Color(0xFF10B981); // Vert
  static const Color enAttenteColor = Color(0xFF6B7280); // Gris

  // Widget pour créer un badge d'état avec texte et icône
  static Widget createStatusBadge({
    required String status,
    required String text,
    required IconData icon,
    double size = 60,
    bool isAnimated = true,
  }) {
    return AnimatedStatusBadge(
      status: status,
      text: text,
      icon: icon,
      size: size,
      isAnimated: isAnimated,
    );
  }

  // Widget pour créer un indicateur de transit sur la route
  static Widget createTransitIndicator({
    required String status,
    double size = 50,
    bool isAnimated = true,
  }) {
    return AnimatedTransitIndicator(
      status: status,
      size: size,
      isAnimated: isAnimated,
    );
  }

  // Méthode pour obtenir le point central d'une route pour placer l'indicateur de transit
  static LatLng getRouteCenterPoint(List<LatLng> routePoints) {
    if (routePoints.isEmpty) {
      return LatLng(0, 0);
    }
    
    if (routePoints.length == 1) {
      return routePoints.first;
    }
    
    // Calculer le point central de la route
    int centerIndex = routePoints.length ~/ 2;
    return routePoints[centerIndex];
  }

  // Méthode pour obtenir la couleur de la route selon le statut
  static Color getRouteColor(String status) {
    switch (status.toUpperCase()) {
      case 'EN_COURS':
        return enCoursColor;
      case 'EN_TRANSIT':
        return enTransitColor;
      case 'TERMINEE':
        return termineeColor;
      default:
        return const Color(0xFF1E3A8A); // Bleu par défaut
    }
  }

  // Méthode pour obtenir l'icône du marqueur de départ selon le statut
  static IconData getDepartureIcon(String status) {
    switch (status.toUpperCase()) {
      case 'EN_COURS':
        return Icons.play_circle;
      case 'EN_TRANSIT':
        return Icons.local_shipping;
      case 'TERMINEE':
        return Icons.check_circle;
      default:
        return Icons.schedule;
    }
  }

  // Méthode pour obtenir l'icône du marqueur d'arrivée selon le statut
  static IconData getArrivalIcon(String status) {
    switch (status.toUpperCase()) {
      case 'EN_COURS':
        return Icons.location_on;
      case 'EN_TRANSIT':
        return Icons.location_on;
      case 'TERMINEE':
        return Icons.flag;
      default:
        return Icons.location_on;
    }
  }

  // Méthode pour obtenir la couleur du marqueur de départ selon le statut
  static Color getDepartureColor(String status) {
    switch (status.toUpperCase()) {
      case 'EN_COURS':
        return enCoursColor;
      case 'EN_TRANSIT':
        return enTransitColor;
      case 'TERMINEE':
        return termineeColor;
      default:
        return enAttenteColor;
    }
  }

  // Méthode pour obtenir la couleur du marqueur d'arrivée selon le statut
  static Color getArrivalColor(String status) {
    switch (status.toUpperCase()) {
      case 'EN_COURS':
        return enAttenteColor;
      case 'EN_TRANSIT':
        return enAttenteColor;
      case 'TERMINEE':
        return termineeColor;
      default:
        return enAttenteColor;
    }
  }
} 