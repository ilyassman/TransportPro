package com.example.demo.controller;

import com.example.demo.entities.Reservation;
import com.example.demo.services.ReservationService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.security.Principal;
import java.util.List;

@RestController
@RequestMapping("/api/reservations")
public class ReservationController {
    @Autowired
    private ReservationService reservationService;

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
} 