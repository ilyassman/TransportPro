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


} 