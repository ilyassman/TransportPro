package com.example.demo.controller;

import com.example.demo.entities.Reservation;
import com.example.demo.services.ReservationService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.parameters.P;
import org.springframework.web.bind.annotation.*;
import com.example.demo.sockets.SocketCamionUpdatesHandler;

import java.security.Principal;
import java.util.List;
import java.util.Map;
import java.util.HashMap;


@RestController
@RequestMapping("/api/reservations")
public class ReservationController {
    @Autowired
    private ReservationService reservationService;
    
    @Autowired
    private SocketCamionUpdatesHandler socketCamionUpdatesHandler;

    @PostMapping
    public ResponseEntity<Reservation> createReservation(Principal principal, @RequestBody Reservation reservation) {
        Reservation created = reservationService.createReservation(principal,reservation);
        return ResponseEntity.ok(created);
    }

    @GetMapping
    public ResponseEntity<List<Reservation>> getUserReservations(Principal principal) {
        List<Reservation> reservations = reservationService.getUserReservations(principal);
        return ResponseEntity.ok(reservations);
    }

    @GetMapping("/status/{status}")
    public ResponseEntity<List<Reservation>> getUserReservationsByStatus(
            Principal principal,
            @PathVariable String status) {
        List<Reservation> reservations = reservationService.getUserReservationsByStatus(principal, status);
        return ResponseEntity.ok(reservations);
    }

    @GetMapping("/recapitulatif")
    public ResponseEntity<List<Map<String, Object>>> getReservationRecapitulatif(Principal principal) {
        List<Map<String, Object>> recapitulatifs = reservationService.getReservationRecapitulatif(principal);
        return ResponseEntity.ok(recapitulatifs);
    }
    


    @PutMapping("/{reservationId}/camion/{camionId}/{isIgnore}")
    public ResponseEntity<?> updateReservationWithCamion(
            @PathVariable Long reservationId,
            @PathVariable Long camionId,@PathVariable Boolean isIgnore,
            Principal principal) {
        try {
            Reservation updated = reservationService.updateReservationWithCamion(reservationId, camionId, principal,isIgnore);
            // Notifier les clients via WebSocket
            socketCamionUpdatesHandler.notifyReservationAccepted(updated);
            return ResponseEntity.ok(updated);
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }
    
    // Endpoints pour les transporteurs
    
    @GetMapping("/available")
    public ResponseEntity<List<Reservation>> getAvailableReservations() {
        List<Reservation> reservations = reservationService.getAvailableReservations();
        return ResponseEntity.ok(reservations);
    }
    
    @GetMapping("/available/status/{status}")
    public ResponseEntity<List<Reservation>> getAvailableReservationsByStatus(@PathVariable String status) {
        List<Reservation> reservations = reservationService.getAvailableReservationsByStatus(status);
        return ResponseEntity.ok(reservations);
    }
    
    @GetMapping("/all/status/{status}")
    public ResponseEntity<List<Reservation>> getAllReservationsByStatus(@PathVariable String status) {
        List<Reservation> reservations = reservationService.getAllReservationsByStatus(status);
        return ResponseEntity.ok(reservations);
    }
    
    @PostMapping("/{reservationId}/accept")
    public ResponseEntity<?> acceptReservation(@PathVariable Long reservationId, Principal principal) {
        try {
            Reservation accepted = reservationService.acceptReservation(reservationId, principal);
            // Notifier les clients via WebSocket
            socketCamionUpdatesHandler.notifyReservationAccepted(accepted);
            return ResponseEntity.ok(accepted);
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }
    
    // Endpoints pour les réservations du transporteur connecté
    @GetMapping("/my")
    public ResponseEntity<List<Reservation>> getMyReservations(Principal principal) {
        try {
            List<Reservation> reservations = reservationService.getMyReservations(principal);
            return ResponseEntity.ok(reservations);
        } catch (Exception e) {
            return ResponseEntity.badRequest().build();
        }
    }
    
    @GetMapping("/my/status/{status}")
    public ResponseEntity<List<Reservation>> getMyReservationsByStatus(
        @PathVariable String status, 
        Principal principal
    ) {
        try {
            List<Reservation> reservations = reservationService.getMyReservationsByStatus(principal, status);
            return ResponseEntity.ok(reservations);
        } catch (Exception e) {
            return ResponseEntity.badRequest().build();
        }
    }
    
    @GetMapping("/my/{status}/with-chargeur")
    public ResponseEntity<List<Map<String, Object>>> getMyReservationsWithChargeurInfo(
            @PathVariable String status,
            Principal principal) {
        try {
            List<Map<String, Object>> reservations = reservationService.getMyReservationsWithChargeurInfo(principal, status);
            return ResponseEntity.ok(reservations);
        } catch (Exception e) {
            return ResponseEntity.badRequest().build();
        }
    }
    
    @PutMapping("/{reservationId}/status")
    public ResponseEntity<?> updateReservationStatus(
        @PathVariable Long reservationId,
        @RequestParam String status,
        Principal principal
    ) {
        try {
            Reservation updatedReservation = reservationService.updateReservationStatus(reservationId, status, principal);
            return ResponseEntity.ok(updatedReservation);
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        } catch (Exception e) {
            return ResponseEntity.badRequest().build();
        }
    }
    
    // Endpoint pour les statistiques du transporteur
    @GetMapping("/my/statistics")
    public ResponseEntity<Map<String, Object>> getMyStatistics(Principal principal) {
        try {
            Map<String, Object> statistics = reservationService.getMyStatistics(principal);
            return ResponseEntity.ok(statistics);
        } catch (Exception e) {
            return ResponseEntity.badRequest().build();
        }
    }
    
    // Endpoint de test pour vérifier les données
    @GetMapping("/my/debug")
    public ResponseEntity<Map<String, Object>> debugMyReservations(Principal principal) {
        try {
            Map<String, Object> debugInfo = reservationService.debugMyReservations(principal);
            return ResponseEntity.ok(debugInfo);
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }
} 