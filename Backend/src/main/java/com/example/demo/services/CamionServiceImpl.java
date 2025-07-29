package com.example.demo.services;

import com.example.demo.entities.Camion;
import com.example.demo.repository.CamionRepository;
import com.example.demo.sockets.SocketCamionUpdatesHandler;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.stream.Collectors;
import java.lang.reflect.Field;

@Service
public class CamionServiceImpl implements CamionService {
    @Autowired
    private CamionRepository camionRepository;

    @Autowired
    private SocketCamionUpdatesHandler socketCamionUpdatesHandler;

    @Override
    public Camion saveCamion(Camion camion) {
        return camionRepository.save(camion);
    }

    @Override
    public List<Camion> getAllCamions() {
        return camionRepository.findAll();
    }

    @Override
    public List<Camion> getCamionsProches(double latitude, double longitude, double rayonKm) {
        return camionRepository.findAll().stream()
                .filter(c -> c.getLatitude() != null && c.getLongitude() != null)
                .filter(c -> c.getDisponible())
                .filter(c -> distanceKm(latitude, longitude, c.getLatitude(), c.getLongitude()) <= rayonKm)
                .collect(Collectors.toList());
    }

    @Override
    public Camion getCamionById(long id) {
        return camionRepository.findById(id).orElse(null);
    }

    private double distanceKm(double lat1, double lon1, double lat2, double lon2) {
        final int R = 6371; // Rayon de la Terre en km
        double dLat = Math.toRadians(lat2 - lat1);
        double dLon = Math.toRadians(lon2 - lon1);
        double a = Math.sin(dLat/2) * Math.sin(dLat/2) +
                Math.cos(Math.toRadians(lat1)) * Math.cos(Math.toRadians(lat2)) *
                Math.sin(dLon/2) * Math.sin(dLon/2);
        double c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));
        return R * c;
    }
    @Override
    public Camion updateCamion(long id,Camion camion){
        Camion camion1 = camionRepository.findById(id).get();
        if(camion.getLatitude() != null)
            camion1.setLatitude(camion.getLatitude());
        if (camion.getLongitude() != null)
            camion1.setLongitude(camion.getLongitude());
        if (camion.getCapacite() !=null)
            camion1.setCapacite(camion.getCapacite());
        if(camion.getDisponible() != null)
            camion1.setDisponible(camion.getDisponible());
        if(camion.getMarque() != null)
            camion1.setMarque(camion.getMarque());
        if(camion.getModele() != null)
            camion1.setModele(camion.getModele());
        if(camion.getType() != null)
            camion1.setType(camion.getType());
        if(camion.getImmatriculation() != null)
            camion1.setImmatriculation(camion.getImmatriculation());
        camionRepository.save(camion1);
        // Notifier les clients WebSocket
        try {
            ObjectMapper mapper = new ObjectMapper();
            String camionJson = mapper.writeValueAsString(camion1);
            SocketCamionUpdatesHandler.notifyClients(camionJson);
            System.out.println("WebSocket notification envoyée pour le camion " + id + ": " + camionJson);

        } catch (Exception e) {
            System.err.println("Erreur lors de la notification WebSocket pour le camion " + id + ": " + e.getMessage());
            e.printStackTrace();
            // ignore
        }
        return camion;
    }
} 