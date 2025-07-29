package com.example.demo.services;

import com.example.demo.entities.Camion;
import com.example.demo.entities.Reservation;
import com.example.demo.repository.ReservationRepository;
import com.example.demo.sec.entity.AppUser;
import com.example.demo.sec.services.AccountService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.security.Principal;
import java.util.List;

@Service
public class ReservationServiceImpl implements ReservationService {
    @Autowired
    private ReservationRepository reservationRepository;
    @Autowired
    private AccountService accountService;
    @Autowired
    private CamionService camionService;
    
    @Override
    public Reservation createReservation(Principal principal,Reservation reservation) {
        reservation.setStatut("EN_ATTENTE");
        reservation.setChargeur(accountService.loadUserByUsername(principal.getName()));
        return reservationRepository.save(reservation);
    }

    @Override
    public List<Reservation> getUserReservations(Principal principal) {
        AppUser user = accountService.loadUserByUsername(principal.getName());
        return reservationRepository.findByChargeurOrderByDateReservationDesc(user);
    }
    
    @Override
    public List<Reservation> getUserReservationsByStatus(Principal principal, String status) {
        AppUser user = accountService.loadUserByUsername(principal.getName());
        return reservationRepository.findByChargeurAndStatutOrderByDateReservationDesc(user, status);
    }
    
    @Override
    public Reservation updateReservationWithCamion(Long reservationId, Long camionId, Principal principal,Boolean isIgnore) {
        // Récupérer la réservation
        Reservation reservation = reservationRepository.findById(reservationId)
            .orElseThrow(() -> new RuntimeException("Réservation non trouvée"));
            
        // Vérifier que l'utilisateur est bien le propriétaire de la réservation
        AppUser user = accountService.loadUserByUsername(principal.getName());

        
        // Récupérer le camion
        Camion camion = camionService.getCamionById(camionId);
        if (camion == null) {
            throw new RuntimeException("Camion non trouvé");
        }
        
        // Vérifier que le camion est disponible
        if (!camion.getDisponible()) {
            throw new RuntimeException("Ce camion n'est plus disponible");
        }
        
        // Mettre à jour la réservation
        reservation.setCamion(camion);
        if(!isIgnore){ reservation.setStatut("EN_COURS");

            // Mettre à jour la disponibilité du camion
            camion.setDisponible(false);}

        camionService.updateCamion(camionId, camion);
        
        return reservationRepository.save(reservation);
    }
} 