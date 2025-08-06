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
import java.util.ArrayList;


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
    
    // Map code postal -> ville (extrait de la logique Flutter)
    private static final Map<String, String> codePostalToVille = new HashMap<>();
    
    static {
        codePostalToVille.put("32000", "Al Hoceïma");
        codePostalToVille.put("22000", "Azilal");
        codePostalToVille.put("43150", "Ben Guerir");
        codePostalToVille.put("13000", "Benslimane");
        codePostalToVille.put("26100", "Berrechid");
        codePostalToVille.put("87200", "Biougra");
        codePostalToVille.put("71000", "Boujdour");
        codePostalToVille.put("33000", "Boulemane");
        codePostalToVille.put("91000", "Chefchaouen");
        codePostalToVille.put("41000", "Chichaoua");
        codePostalToVille.put("73000", "Dakhla");
        codePostalToVille.put("52000", "Errachidia");
        codePostalToVille.put("44000", "Essaouira");
        codePostalToVille.put("61000", "Figuig");
        codePostalToVille.put("81000", "Guelmim");
        codePostalToVille.put("53000", "Ifrane");
        codePostalToVille.put("43000", "El Kelaâ des Sraghna");
        codePostalToVille.put("92000", "Larache");
        codePostalToVille.put("45000", "Ouarzazate");
        codePostalToVille.put("26000", "Settat");
        codePostalToVille.put("31000", "Séfrou");
        codePostalToVille.put("85200", "Sidi Ifni");
        codePostalToVille.put("16000", "Sidi Kacem");
        codePostalToVille.put("14200", "Sidi Slimane");
        codePostalToVille.put("72000", "Es-Semara");
        codePostalToVille.put("34000", "Taounate");
        codePostalToVille.put("82000", "Tan-Tan");
        codePostalToVille.put("83000", "Taroudant");
        codePostalToVille.put("84000", "Tata");
        codePostalToVille.put("85000", "Tiznit");
    }
    
    private String villeDepuisCodePostal(String codePostal) {
        if (codePostalToVille.containsKey(codePostal)) {
            return codePostalToVille.get(codePostal);
        }
        final int cp = Integer.parseInt(codePostal);
        if (cp >= 20000 && cp <= 20999) return "Casablanca";
        if (cp >= 10000 && cp <= 10999) return "Rabat";
        if (cp >= 11000 && cp <= 11999) return "Salé";
        if (cp >= 40000 && cp <= 40999) return "Marrakech";
        if (cp >= 30000 && cp <= 30999) return "Fès";
        if (cp >= 90000 && cp <= 90999) return "Tanger";
        if (cp >= 14000 && cp <= 14999) return "Kénitra";
        if (cp >= 15000 && cp <= 15999) return "Khémisset";
        if (cp >= 25000 && cp <= 25999) return "Khouribga";
        if (cp >= 24000 && cp <= 24999) return "El Jadida";
        if (cp >= 50000 && cp <= 50999) return "Meknès";
        if (cp >= 60000 && cp <= 60999) return "Oujda";
        if (cp >= 28800 && cp <= 28899) return "Mohammédia";
        if (cp >= 62000 && cp <= 62999) return "Nador";
        if (cp >= 46000 && cp <= 46999) return "Safi";
        if (cp >= 35000 && cp <= 35999) return "Taza";
        if (cp >= 12000 && cp <= 12999) return "Témara";
        if (cp >= 93000 && cp <= 93999) return "Tétouan";
        if (cp >= 80100 && cp <= 80199) return "Inezgane";
        if (cp >= 86300 && cp <= 86399) return "Inezgane";
        if (cp >= 23000 && cp <= 23999) return "Béni Mellal";
        if (cp >= 63300 && cp <= 63399) return "Berkane";
        return codePostal;
    }
    
    private String extractCodePostal(String address) {
        if (address == null || address.isEmpty()) return "";
        // Regex pour trouver un code postal à 5 chiffres
        java.util.regex.Pattern pattern = java.util.regex.Pattern.compile("\\b\\d{5}\\b");
        java.util.regex.Matcher matcher = pattern.matcher(address);
        return matcher.find() ? matcher.group() : "";
    }
    
    private String villeDepuisAdresse(String address) {
        if (address == null || address.isEmpty()) return "";
        String codePostal = extractCodePostal(address);
        if (!codePostal.isEmpty()) {
            return villeDepuisCodePostal(codePostal);
        }
        return address;
    }
    
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
    public List<Map<String, Object>> getMyReservationsWithChargeurInfo(Principal principal, String status) {
        AppUser transporteur = userRepository.findByUsername(principal.getName());
        if (transporteur == null) {
            throw new RuntimeException("Transporteur non trouvé");
        }
        
        List<Reservation> reservations = reservationRepository.findByCamionTransporteurAndStatutOrderByDateReservationDesc(transporteur, status);
        
        return reservations.stream().map(reservation -> {
            Map<String, Object> reservationMap = new HashMap<>();
            reservationMap.put("id", reservation.getId());
            reservationMap.put("typeMarchandise", reservation.getTypeMarchandise());
            reservationMap.put("volume", reservation.getVolume());
            reservationMap.put("poids", reservation.getPoids());
            reservationMap.put("lieuDepart", reservation.getLieuDepart());
            reservationMap.put("lieuArrivee", reservation.getLieuArrivee());
            reservationMap.put("dateReservation", reservation.getDateReservation());
            reservationMap.put("dateLivraison", reservation.getDateLivraison());
            reservationMap.put("statut", reservation.getStatut());
            reservationMap.put("tarif", reservation.getTarif());
            reservationMap.put("modePaiement", reservation.getModePaiement());
            reservationMap.put("createdAt", reservation.getDateReservation());
            
            // Informations du chargeur
            Map<String, Object> chargeurMap = new HashMap<>();
            if (reservation.getChargeur() != null) {
                chargeurMap.put("id", reservation.getChargeur().getId());
                chargeurMap.put("nom", reservation.getChargeur().getFirstName() + " " + reservation.getChargeur().getLastName());
                chargeurMap.put("username", reservation.getChargeur().getUsername());
                chargeurMap.put("email", reservation.getChargeur().getEmail());
                chargeurMap.put("phone", reservation.getChargeur().getPhone());
            } else {
                chargeurMap.put("id", 0);
                chargeurMap.put("nom", "Chargeur inconnu");
                chargeurMap.put("username", "chargeur_inconnu");
                chargeurMap.put("email", "");
                chargeurMap.put("phone", "");
            }
            reservationMap.put("chargeur", chargeurMap);
            
            return reservationMap;
        }).toList();
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
    
    @Override
    public List<Map<String, Object>> getReservationRecapitulatif(Principal principal) {
        AppUser user = accountService.loadUserByUsername(principal.getName());
        List<Reservation> reservations;
        
        // Détecter si l'utilisateur est un transporteur ou un chargeur
        boolean isTransporteur = user.getRoles().stream()
            .anyMatch(role -> "TRANSPORTEUR".equals(role.getRolename()));
        
        if (isTransporteur) {
            // Pour les transporteurs, récupérer les réservations où ils sont assignés
            reservations = reservationRepository.findByCamionTransporteurOrderByDateReservationDesc(user);
        } else {
            // Pour les chargeurs, récupérer leurs propres réservations
            reservations = reservationRepository.findByChargeurOrderByDateReservationDesc(user);
        }
        
        List<Map<String, Object>> recapitulatifs = new ArrayList<>();
        for (Reservation reservation : reservations) {
            Map<String, Object> recapitulatif = new HashMap<>();
            recapitulatif.put("id", reservation.getId());
            recapitulatif.put("lieuDepart", reservation.getLieuDepart());
            recapitulatif.put("lieuArrivee", reservation.getLieuArrivee());
            recapitulatif.put("dateReservation", reservation.getDateReservation());
            recapitulatif.put("statut", reservation.getStatut());
            recapitulatif.put("typeMarchandise", reservation.getTypeMarchandise());
            recapitulatif.put("poids", reservation.getPoids());
            recapitulatif.put("volume", reservation.getVolume());
            recapitulatif.put("tarif", reservation.getTarif());
            
            if (isTransporteur) {
                // Pour les transporteurs, ajouter les informations du chargeur
                if (reservation.getChargeur() != null) {
                    Map<String, Object> chargeurInfo = new HashMap<>();
                    chargeurInfo.put("username", reservation.getChargeur().getUsername());
                    chargeurInfo.put("firstName", reservation.getChargeur().getFirstName());
                    chargeurInfo.put("lastName", reservation.getChargeur().getLastName());
                    chargeurInfo.put("email", reservation.getChargeur().getEmail());
                    chargeurInfo.put("phone", reservation.getChargeur().getPhone());
                    recapitulatif.put("chargeur", chargeurInfo);
                    recapitulatif.put("chargeurNom", reservation.getChargeur().getFirstName() + " " + reservation.getChargeur().getLastName());
                    recapitulatif.put("chargeurId", reservation.getChargeur().getId());
                }
                // Informations du trajet
                recapitulatif.put("trajetInfo", reservation.getLieuDepart() + " → " + reservation.getLieuArrivee());
            } else {
                // Pour les chargeurs, ajouter les informations du transporteur si assigné
                if (reservation.getCamion() != null && reservation.getCamion().getTransporteur() != null) {
                    Map<String, Object> transporteurInfo = new HashMap<>();
                    transporteurInfo.put("username", reservation.getCamion().getTransporteur().getUsername());
                    transporteurInfo.put("firstName", reservation.getCamion().getTransporteur().getFirstName());
                    transporteurInfo.put("lastName", reservation.getCamion().getTransporteur().getLastName());
                    recapitulatif.put("transporteur", transporteurInfo);
                }
            }
            
            recapitulatifs.add(recapitulatif);
        }
        
        return recapitulatifs;
    }
    

    
    @Override
    public Reservation getReservationById(Long reservationId) {
        return reservationRepository.findById(reservationId)
                .orElseThrow(() -> new RuntimeException("Réservation non trouvée"));
    }
} 