package com.mantiq.controller;

import com.mantiq.model.User;
import com.mantiq.repository.UserRepository;
import com.mantiq.service.DemoTreeService;
import org.springframework.http.ResponseEntity;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.Map;
import java.util.Optional;

@RestController
@RequestMapping("/api/auth")
public class AuthController {

    private final UserRepository        userRepository;
    private final BCryptPasswordEncoder passwordEncoder;
    private final DemoTreeService       demoTreeService;

    public AuthController(UserRepository userRepository,
                          BCryptPasswordEncoder passwordEncoder,
                          DemoTreeService demoTreeService) {
        this.userRepository  = userRepository;
        this.passwordEncoder = passwordEncoder;
        this.demoTreeService = demoTreeService;
    }

    // Registrierung: POST /api/auth/register
    // Body: { "email": "...", "password": "...", "displayName": "..." }
    @PostMapping("/register")
    public ResponseEntity<?> registrieren(@RequestBody Map<String, String> body) {
        String email       = body.get("email");
        String passwort    = body.get("password");
        String displayName = body.get("displayName");

        if (email == null || passwort == null || email.isBlank() || passwort.isBlank()) {
            return ResponseEntity.badRequest().body(Map.of("fehler", "E-Mail und Passwort erforderlich"));
        }
        if (displayName == null || displayName.isBlank()) {
            return ResponseEntity.badRequest().body(Map.of("fehler", "Nutzername erforderlich"));
        }

        if (userRepository.findByEmail(email).isPresent()) {
            return ResponseEntity.badRequest().body(Map.of("fehler", "E-Mail bereits registriert"));
        }

        User nutzer = new User();
        nutzer.setEmail(email);
        nutzer.setPasswordHash(passwordEncoder.encode(passwort));
        nutzer.setDisplayName(displayName.trim());
        userRepository.save(nutzer);

        demoTreeService.createForUser(nutzer);

        return ResponseEntity.ok(Map.of("nachricht", "Registrierung erfolgreich"));
    }

    // Login: POST /api/auth/login
    // Body: { "email": "...", "password": "..." }
    @PostMapping("/login")
    public ResponseEntity<?> anmelden(@RequestBody Map<String, String> body) {
        String email    = body.get("email");
        String passwort = body.get("password");

        Optional<User> nutzerOpt = userRepository.findByEmail(email);

        if (nutzerOpt.isEmpty() || !passwordEncoder.matches(passwort, nutzerOpt.get().getPasswordHash())) {
            return ResponseEntity.status(401).body(Map.of("fehler", "E-Mail oder Passwort falsch"));
        }

        User nutzer = nutzerOpt.get();
        Map<String, Object> resp = new HashMap<>();
        resp.put("userId",      nutzer.getId());
        resp.put("email",       nutzer.getEmail());
        resp.put("displayName", nutzer.getDisplayName() != null ? nutzer.getDisplayName() : "");
        return ResponseEntity.ok(resp);
    }
}
