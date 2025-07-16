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
    @PutMapping("/{id}")
    public ResponseEntity<Camion> updateCamion(@PathVariable long id, @RequestBody Camion camion) {
        Camion updatedCamion = camionService.updateCamion(id, camion);
        return ResponseEntity.ok(updatedCamion);
    }
} 