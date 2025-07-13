package com.example.demo.sec.controller;
import com.example.demo.sec.entity.AppUser;
import com.example.demo.sec.repo.UserAppRepository;
import com.example.demo.sec.services.AccountService;
import com.example.demo.sockets.SocketUpdatesHandler;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.security.Principal;
import java.time.Month;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

@RestController
//@CrossOrigin(origins = "http://localhost:3000")
public class AccountRestController {
    private AccountService accountService;
    @Autowired
    private UserAppRepository userAppRepository;

    public AccountRestController(AccountService accountService) {
        this.accountService = accountService;
    }
    @GetMapping("/users")
    public List<AppUser> appUsers(){
        return accountService.getUsers();
    }
    @PostMapping("/user")
    public ResponseEntity<?> addUser(@RequestBody AppUser user){
        try {
            // Vérifier si l'utilisateur existe déjà
            AppUser existingUser = accountService.loadUserByUsername(user.getUsername());
            if(existingUser != null) {
                return ResponseEntity.badRequest()
                    .body(Map.of("error", "username_already_exists", "message", "Ce nom d'utilisateur existe déjà"));
            }
            
            // Vérifier si l'email existe déjà
            AppUser existingEmail = accountService.loadUserByEmail(user.getEmail());
            if(existingEmail != null) {
                return ResponseEntity.badRequest()
                    .body(Map.of("error", "email_already_exists", "message", "Cette adresse email existe déjà"));
            }
            
            // Valider les champs requis
            if (user.getUsername() == null || user.getUsername().trim().isEmpty()) {
                return ResponseEntity.badRequest()
                    .body(Map.of("error", "invalid_data", "message", "Le nom d'utilisateur est requis"));
            }
            
            if (user.getEmail() == null || user.getEmail().trim().isEmpty()) {
                return ResponseEntity.badRequest()
                    .body(Map.of("error", "invalid_data", "message", "L'email est requis"));
            }
            
            if (user.getPassword() == null || user.getPassword().trim().isEmpty()) {
                return ResponseEntity.badRequest()
                    .body(Map.of("error", "invalid_data", "message", "Le mot de passe est requis"));
            }
            
            // Créer le nouvel utilisateur
            AppUser savedUser = accountService.addNewAccount(user);
            SocketUpdatesHandler.notifyClients(); // Notifie tous les clients WebSocket
            
            return ResponseEntity.ok(savedUser);
            
        } catch (Exception e) {
            return ResponseEntity.badRequest()
                .body(Map.of("error", "signup_error", "message", "Erreur lors de la création du compte: " + e.getMessage()));
        }
    }

    @DeleteMapping("user/{id}")
    public void deleteUser(@PathVariable Long id){
        userAppRepository.deleteById(id);
        SocketUpdatesHandler.notifyClients();
    }
    @PutMapping("/userupdate/{id}")
    public void updateUser(@PathVariable Long id,@RequestBody AppUser user){
        accountService.updateUser(id,user);

    }
    @PutMapping("/userupdatePassword")
    public AppUser updateUserPass(@RequestBody AppUser user){
        return accountService.updatePassword(user.getUsername(),user.getPassword());

    }

    @GetMapping("/profil")
    public AppUser profile(Principal principal){
        return accountService.loadUserByUsername(principal.getName());
    }

}
