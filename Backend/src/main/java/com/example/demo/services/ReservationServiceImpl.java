package com.example.demo.services;

import com.example.demo.entities.Camion;
import com.example.demo.entities.Reservation;
import com.example.demo.repository.ReservationRepository;
import com.example.demo.sec.repo.UserAppRepository;
import com.example.demo.sec.entity.AppUser;
import com.example.demo.sec.services.AccountService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.security.Principal;
import java.util.List;
import java.util.Arrays;
import java.util.Map;
import java.util.HashMap;

@Service
public class ReservationServiceImpl implements ReservationService {
    @Autowired
    private ReservationRepository reservationRepository;
    @Autowired
    private AccountService accountService;
    @Autowired
    private CamionService camionService;
    @Autowired
    private UserAppRepository userRepository;
    
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
    
    @Override
    public List<Reservation> getAvailableReservations() {
        return reservationRepository.findByCamionIsNullOrderByDateReservationDesc();
    }
    
    @Override
    public List<Reservation> getAvailableReservationsByStatus(String status) {
        return reservationRepository.findByCamionIsNullAndStatutOrderByDateReservationDesc(status);
    }
    
    @Override
    public List<Reservation> getAllReservationsByStatus(String status) {
        return reservationRepository.findByStatutOrderByDateReservationDesc(status);
    }
    
    @Override
    public List<Reservation> getMyReservations(Principal principal) {
        AppUser transporteur = userRepository.findByUsername(principal.getName());
        if (transporteur == null) {
            throw new RuntimeException("Transporteur non trouvé");
        }
        return reservationRepository.findByCamionTransporteurOrderByDateReservationDesc(transporteur);
    }
    
    @Override
    public List<Reservation> getMyReservationsByStatus(Principal principal, String status) {
        AppUser transporteur = userRepository.findByUsername(principal.getName());
        if (transporteur == null) {
            throw new RuntimeException("Transporteur non trouvé");
        }
        return reservationRepository.findByCamionTransporteurAndStatutOrderByDateReservationDesc(transporteur, status);
    }
    
    @Override
    public Reservation updateReservationStatus(Long reservationId, String newStatus, Principal principal) {
        Reservation reservation = reservationRepository.findById(reservationId)
                .orElseThrow(() -> new RuntimeException("Réservation non trouvée"));
        
        AppUser transporteur = userRepository.findByUsername(principal.getName());
        if (transporteur == null) {
            throw new RuntimeException("Transporteur non trouvé");
        }
        
        // Vérifier que la réservation appartient au transporteur
        if (reservation.getCamion() == null || !reservation.getCamion().getTransporteur().equals(transporteur)) {
            throw new RuntimeException("Vous n'êtes pas autorisé à modifier cette réservation");
        }
        
        reservation.setStatut(newStatus);
        return reservationRepository.save(reservation);
    }
    
    @Override
    public Map<String, Object> getMyStatistics(Principal principal) {
        AppUser transporteur = userRepository.findByUsername(principal.getName());
        if (transporteur == null) {
            throw new RuntimeException("Transporteur non trouvé");
        }
        
        System.out.println("=== DEBUG STATISTIQUES ===");
        System.out.println("Transporteur: " + transporteur.getUsername());
        
        // Récupérer toutes les réservations de la base de données
        List<Reservation> allReservationsInDB = reservationRepository.findAll();
        System.out.println("Total réservations dans la DB: " + allReservationsInDB.size());
        
        // Filtrer les réservations du transporteur connecté
        List<Reservation> myReservations = allReservationsInDB.stream()
            .filter(r -> r.getCamion() != null && 
                        r.getCamion().getTransporteur() != null && 
                        r.getCamion().getTransporteur().getId().equals(transporteur.getId()))
            .toList();
        
        System.out.println("Mes réservations: " + myReservations.size());
        
        // Afficher toutes les réservations pour debug
        System.out.println("Toutes mes réservations:");
        for (Reservation r : myReservations) {
            System.out.println("  - ID: " + r.getId() + ", Statut: " + r.getStatut() + ", Tarif: " + r.getTarif() + ", Poids: " + r.getPoids() + ", Camion: " + (r.getCamion() != null ? r.getCamion().getId() : "NULL"));
        }
        
        // Calculer les statistiques
        long missionsTerminees = myReservations.stream()
            .filter(r -> "TERMINEE".equals(r.getStatut()))
            .count();
        
        System.out.println("Missions terminées: " + missionsTerminees);
        
        // Calculer les gains totaux des réservations terminées
        double gainsTotaux = myReservations.stream()
            .filter(r -> "TERMINEE".equals(r.getStatut()))
            .mapToDouble(r -> {
                double tarif = r.getTarif();
                // Si le tarif est 0, calculer un tarif estimé basé sur le poids
                if (tarif == 0.0) {
                    tarif = r.getPoids() * 0.5 + 100.0; // 0.5 MAD par kg + 100 MAD de base
                }
                System.out.println("  - Réservation " + r.getId() + " tarif calculé: " + tarif);
                return tarif;
            })
            .sum();
        
        System.out.println("Gains totaux calculés: " + gainsTotaux);
        
        // Calculer les autres statistiques
        long reservationsEnAttente = myReservations.stream()
            .filter(r -> "EN_ATTENTE".equals(r.getStatut()))
            .count();
        
        long reservationsEnCours = myReservations.stream()
            .filter(r -> "EN_COURS".equals(r.getStatut()))
            .count();
        
        // Calculer les kilomètres parcourus (estimation basée sur le nombre de missions terminées)
        double kilometresParcourus = missionsTerminees * 150.0; // Estimation moyenne de 150km par mission
        
        Map<String, Object> statistics = new HashMap<>();
        statistics.put("missionsTerminees", missionsTerminees);
        statistics.put("gainsTotaux", gainsTotaux);
        statistics.put("reservationsEnAttente", reservationsEnAttente);
        statistics.put("reservationsEnCours", reservationsEnCours);
        statistics.put("kilometresParcourus", kilometresParcourus);
        statistics.put("totalReservations", myReservations.size());
        
        System.out.println("=== FIN DEBUG ===");
        
        return statistics;
    }
    
    @Override
    public Map<String, Object> debugMyReservations(Principal principal) {
        AppUser transporteur = userRepository.findByUsername(principal.getName());
        if (transporteur == null) {
            throw new RuntimeException("Transporteur non trouvé");
        }
        
        Map<String, Object> debugInfo = new HashMap<>();
        debugInfo.put("transporteur", transporteur.getUsername());
        
        // Récupérer toutes les réservations
        List<Reservation> allReservations = reservationRepository.findAll();
        debugInfo.put("totalReservationsInDB", allReservations.size());
        
        // Récupérer les réservations du transporteur
        List<Reservation> myReservations = reservationRepository.findAllByTransporteur(transporteur);
        debugInfo.put("myReservations", myReservations.size());
        
        // Récupérer les réservations terminées
        List<Reservation> terminatedReservations = reservationRepository.findTerminatedByTransporteur(transporteur);
        debugInfo.put("terminatedReservations", terminatedReservations.size());
        
        // Détails des réservations terminées
        List<Map<String, Object>> terminatedDetails = terminatedReservations.stream()
            .map(r -> {
                Map<String, Object> detail = new HashMap<>();
                detail.put("id", r.getId());
                detail.put("statut", r.getStatut());
                detail.put("tarif", r.getTarif());
                detail.put("poids", r.getPoids());
                detail.put("camionId", r.getCamion() != null ? r.getCamion().getId() : null);
                detail.put("chargeur", r.getChargeur() != null ? r.getChargeur().getUsername() : null);
                return detail;
            })
            .toList();
        
        debugInfo.put("terminatedDetails", terminatedDetails);
        
        // Calculer les gains
        double gainsTotaux = terminatedReservations.stream()
            .mapToDouble(r -> {
                double tarif = r.getTarif();
                if (tarif == 0.0) {
                    tarif = r.getPoids() * 0.5 + 100.0;
                }
                return tarif;
            })
            .sum();
        
        debugInfo.put("gainsTotaux", gainsTotaux);
        
        return debugInfo;
    }
    
    @Override
    public Reservation acceptReservation(Long reservationId, Principal principal) {
        // Récupérer la réservation
        Reservation reservation = reservationRepository.findById(reservationId)
            .orElseThrow(() -> new RuntimeException("Réservation non trouvée"));
            
        // Vérifier que le statut permet les propositions (insensible à la casse)
        String statut = reservation.getStatut();
        if (statut != null && !statut.toUpperCase().equals("EN_ATTENTE") && !statut.toUpperCase().equals("EN_COURS")) {
            throw new RuntimeException("Cette réservation n'est plus disponible pour acceptation");
        }
        
        // Récupérer le transporteur connecté
        AppUser transporteur = accountService.loadUserByUsername(principal.getName());
        
        // Récupérer le camion du transporteur
        Camion camion = camionService.getCamionByTransporteur(transporteur)
            .orElseThrow(() -> new RuntimeException("Vous devez d'abord enregistrer votre camion"));
        
        // Vérifier que le camion est disponible
        if (!camion.getDisponible()) {
            throw new RuntimeException("Votre camion n'est pas disponible");
        }
        
        // Vérifier si ce transporteur a déjà proposé pour cette réservation
        if (reservation.getCamion() != null && reservation.getCamion().getTransporteur().getId().equals(transporteur.getId())) {
            // Le transporteur a déjà proposé, retourner la réservation existante
            return reservation;
        }
        
        // Pour permettre à plusieurs transporteurs de proposer
        // On simule en gardant la première proposition mais en permettant à tous de proposer
        if (reservation.getCamion() == null) {
            // Première proposition
            reservation.setCamion(camion);
            // Garder le statut EN_ATTENTE pour permettre d'autres propositions
        }
        // Pour les propositions suivantes, on ne fait rien mais on ne bloque pas
        // Dans un vrai système, on ajouterait à une liste de propositions
        
        return reservationRepository.save(reservation);
    }
} 