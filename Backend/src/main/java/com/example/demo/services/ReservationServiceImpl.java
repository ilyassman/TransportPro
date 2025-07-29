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
    public List<Map<String, Object>> getReservationRecapitulatif(Principal principal) {
        AppUser currentUser = accountService.loadUserByUsername(principal.getName());
        List<Reservation> reservations = reservationRepository.findByChargeur(currentUser);
        
        List<Map<String, Object>> recapitulatifs = new ArrayList<>();
        
        for (Reservation reservation : reservations) {
            Map<String, Object> recapitulatif = new HashMap<>();
            
            // Informations de base de la réservation
            recapitulatif.put("id", reservation.getId());
            recapitulatif.put("typeMarchandise", reservation.getTypeMarchandise());
            recapitulatif.put("volume", reservation.getVolume());
            recapitulatif.put("poids", reservation.getPoids());
            recapitulatif.put("lieuDepart", villeDepuisAdresse(reservation.getLieuDepart()));
            recapitulatif.put("lieuArrivee", villeDepuisAdresse(reservation.getLieuArrivee()));
            recapitulatif.put("dateReservation", reservation.getDateReservation());
            recapitulatif.put("dateLivraison", reservation.getDateLivraison());
            recapitulatif.put("statut", reservation.getStatut());
            recapitulatif.put("tarif", reservation.getTarif());
            recapitulatif.put("modePaiement", reservation.getModePaiement());
            recapitulatif.put("factureGeneree", reservation.isFactureGeneree());
            
            // Informations du camion et transporteur
            if (reservation.getCamion() != null) {
                Camion camion = reservation.getCamion();
                recapitulatif.put("camionId", camion.getId());
                recapitulatif.put("immatriculation", camion.getImmatriculation());
                recapitulatif.put("type", camion.getType());
                recapitulatif.put("capacite", camion.getCapacite());
                recapitulatif.put("marque", camion.getMarque());
                recapitulatif.put("modele", camion.getModele());
                
                if (camion.getTransporteur() != null) {
                    AppUser transporteur = camion.getTransporteur();
                    recapitulatif.put("transporteurId", transporteur.getId());
                    recapitulatif.put("transporteurNom", transporteur.getUsername());
                    recapitulatif.put("transporteurPhone", transporteur.getPhone());
                    recapitulatif.put("transporteurEmail", transporteur.getEmail());
                    recapitulatif.put("transporteurCompany", transporteur.getCompanyName());
                }
            }
            
            // Informations du trajet
            String trajetInfo = "De " + villeDepuisAdresse(reservation.getLieuDepart()) + 
                               " à " + villeDepuisAdresse(reservation.getLieuArrivee());
            recapitulatif.put("trajetInfo", trajetInfo);
            
            recapitulatifs.add(recapitulatif);
        }
        
        return recapitulatifs;
    }
    
    @Override
    public Reservation getReservationById(Long reservationId) {
        return reservationRepository.findById(reservationId).orElse(null);
    }
} 