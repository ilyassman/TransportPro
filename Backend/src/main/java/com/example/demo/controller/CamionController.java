package com.example.demo.controller;

import com.example.demo.entities.Camion;
import com.example.demo.services.CamionService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;
import org.springframework.http.ResponseEntity;
import java.util.Map;

import java.util.List;

@RestController
@RequestMapping("/api/camions")
public class CamionController {
    @Autowired
    private CamionService camionService;

    @PostMapping
    public Camion saveCamion(@RequestBody Camion camion) {
        return camionService.saveCamion(camion);
    }

    @GetMapping
    public List<Camion> getAllCamions() {
        return camionService.getAllCamions();
    }

    @GetMapping("/proches")
    public List<Camion> getCamionsProches(@RequestParam double latitude, @RequestParam double longitude, @RequestParam(defaultValue = "10") double rayonKm) {
        return camionService.getCamionsProches(latitude, longitude, rayonKm);
    }
    
    @GetMapping("/{id}")
    public ResponseEntity<Camion> getCamionById(@PathVariable long id) {
        try {
            Camion camion = camionService.getCamionById(id);
            if (camion != null) {
                return ResponseEntity.ok(camion);
            } else {
                return ResponseEntity.notFound().build();
            }
        } catch (Exception e) {
            return ResponseEntity.badRequest().build();
        }
    }
    
    @PutMapping("/{id}")
    public ResponseEntity<Camion> updateCamion(@PathVariable long id, @RequestBody Camion camion) {
        Camion updatedCamion = camionService.updateCamion(id, camion);
        return ResponseEntity.ok(updatedCamion);
    }
    
    // Endpoint de test pour simuler le mouvement du camion
    @PostMapping("/{id}/simulate-movement")
    public ResponseEntity<String> simulateCamionMovement(@PathVariable long id) {
        try {
            // Récupérer le camion actuel
            Camion camion = camionService.getCamionById(id);
            if (camion == null) {
                return ResponseEntity.notFound().build();
            }

            // Simuler un mouvement (exemple: de Casablanca vers Rabat)
            double startLat = 33.243454;
            double startLng = -8.498744;
            double endLat = 33.599281;
            double endLng = -7.613490;
            // Créer un thread pour envoyer des updates toutes les 2 secondes
            new Thread(() -> {
                try {
                    for (int i = 0; i <= 10; i++) {
                        // Interpolation linéaire entre start et end
                        double progress = i / 10.0;
                        double currentLat = startLat + (endLat - startLat) * progress;
                        double currentLng = startLng + (endLng - startLng) * progress;

                        // Mettre à jour la position du camion
                        camion.setLatitude(currentLat);
                        camion.setLongitude(currentLng);
                        camionService.updateCamion(id, camion);

                        // Attendre 2 secondes
                        Thread.sleep(2000);
                    }
                } catch (Exception e) {
                    e.printStackTrace();
                }
            }).start();

            return ResponseEntity.ok("Simulation de mouvement démarrée pour le camion " + id);
        } catch (Exception e) {
            return ResponseEntity.badRequest().body("Erreur: " + e.getMessage());
        }
    }
} 