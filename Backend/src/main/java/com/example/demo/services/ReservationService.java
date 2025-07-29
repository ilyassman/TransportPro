package com.example.demo.services;

import com.example.demo.entities.Reservation;

import java.security.Principal;
import java.util.List;
import java.util.Map;

public interface ReservationService {
    Reservation createReservation(Principal principal, Reservation reservation);
    
    // Récupérer toutes les réservations d'un utilisateur
    List<Reservation> getUserReservations(Principal principal);
    
    // Récupérer les réservations par statut pour un utilisateur
    List<Reservation> getUserReservationsByStatus(Principal principal, String status);
    
    // Mettre à jour une réservation avec un camion
    Reservation updateReservationWithCamion(Long reservationId, Long camionId, Principal principal,Boolean isIgnore);
    
    // Récupérer les récapitulatifs de réservations
    List<Map<String, Object>> getReservationRecapitulatif(Principal principal);
    
    // Récupérer une réservation par ID
    Reservation getReservationById(Long reservationId);
} 