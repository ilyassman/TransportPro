package com.example.demo.repository;

import com.example.demo.entities.Reservation;
import com.example.demo.sec.entity.AppUser;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;
 
@Repository
public interface ReservationRepository extends JpaRepository<Reservation, Long> {
    // Récupérer toutes les réservations d'un chargeur
    List<Reservation> findByChargeurOrderByDateReservationDesc(AppUser chargeur);
    List<Reservation> findByChargeur(AppUser chargeur);
    
    // Récupérer les réservations par statut pour un chargeur
    List<Reservation> findByChargeurAndStatutOrderByDateReservationDesc(AppUser chargeur, String statut);
    List<Reservation> findByStatut(String statut);
} 