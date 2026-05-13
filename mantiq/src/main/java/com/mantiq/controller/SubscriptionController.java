package com.mantiq.controller;

import com.mantiq.model.User;
import com.mantiq.repository.UserRepository;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

// Platzhalter – Bezahlung wird spaeter integriert
@RestController
@RequestMapping("/api/subscription")
public class SubscriptionController {

    private final UserRepository userRepository;

    public SubscriptionController(UserRepository userRepository) {
        this.userRepository = userRepository;
    }

    // Aktueller Plan: GET /api/subscription?userId=X
    @GetMapping
    public ResponseEntity<?> plan(@RequestParam Integer userId) {
        User u = userRepository.findById(userId).orElse(null);
        if (u == null) return ResponseEntity.notFound().build();

        boolean isPro = "PRO".equals(u.getSubscriptionPlan())
                     && (u.getSubscriptionUntil() == null
                         || u.getSubscriptionUntil().isAfter(java.time.LocalDateTime.now()));

        return ResponseEntity.ok(Map.of(
            "plan",             u.getSubscriptionPlan(),
            "isPro",            isPro,
            "subscriptionUntil", u.getSubscriptionUntil() != null
                                  ? u.getSubscriptionUntil().toString() : ""
        ));
    }

    // Upgrade-Anfrage (Platzhalter): POST /api/subscription/upgrade
    @PostMapping("/upgrade")
    public ResponseEntity<?> upgrade() {
        return ResponseEntity.ok(Map.of(
            "nachricht", "Bezahlfunktion kommt bald. Danke für dein Interesse!",
            "status",    "PENDING"
        ));
    }
}
