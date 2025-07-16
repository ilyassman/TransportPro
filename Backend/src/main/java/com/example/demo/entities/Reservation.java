package com.example.demo.entities;

import com.example.demo.sec.entity.AppUser;
import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;

@Entity
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Reservation {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne
    private AppUser chargeur;

    @ManyToOne
    private Camion camion;

    private String typeMarchandise; // normale, frigorifique, etc.
    private double volume;
    private double poids;
    private String lieuDepart;
    private String lieuArrivee;
    private LocalDateTime dateReservation;
    private LocalDateTime dateLivraison;
    private String statut; // EN_ATTENTE, EN_COURS, TERMINEE, etc.
    private double tarif;
    private String modePaiement;
    private boolean factureGeneree;
} 