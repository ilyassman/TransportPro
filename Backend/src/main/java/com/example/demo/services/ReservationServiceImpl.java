package com.example.demo.services;

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
} 