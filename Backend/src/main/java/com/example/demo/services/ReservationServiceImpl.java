package com.example.demo.services;

import com.example.demo.entities.Reservation;
import com.example.demo.repository.ReservationRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

@Service
public class ReservationServiceImpl implements ReservationService {
    @Autowired
    private ReservationRepository reservationRepository;

    @Override
    public Reservation createReservation(Reservation reservation) {
        reservation.setStatut("EN_ATTENTE");
        return reservationRepository.save(reservation);
    }
} 