package com.mantiq.controller;

import com.mantiq.model.User;
import com.mantiq.repository.UserProgressRepository;
import com.mantiq.repository.UserRepository;
import org.springframework.data.domain.PageRequest;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.time.temporal.ChronoUnit;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/users")
public class UserController {

    private final UserRepository userRepository;
    private final UserProgressRepository progressRepository;

    public UserController(UserRepository userRepository,
                          UserProgressRepository progressRepository) {
        this.userRepository   = userRepository;
        this.progressRepository = progressRepository;
    }

    // Nutzerprofil laden: GET /api/users/{id}
    @GetMapping("/{id}")
    public ResponseEntity<?> profil(@PathVariable Integer id) {
        User u = userRepository.findById(id).orElse(null);
        if (u == null) return ResponseEntity.notFound().build();
        return ResponseEntity.ok(nutzerZuMap(u));
    }

    // Display-Name aendern: PUT /api/users/{id}
    // Body: { "displayName": "..." }
    @PutMapping("/{id}")
    public ResponseEntity<?> aktualisieren(@PathVariable Integer id,
                                           @RequestBody Map<String, String> body) {
        User u = userRepository.findById(id).orElse(null);
        if (u == null) return ResponseEntity.notFound().build();

        String name      = body.get("displayName");
        String firstName = body.get("firstName");
        String lastName  = body.get("lastName");

        if (name != null) {
            if (u.getDisplayNameChangedAt() != null) {
                long daysSince = ChronoUnit.DAYS.between(u.getDisplayNameChangedAt(), LocalDateTime.now());
                if (daysSince < 30) {
                    long daysLeft = 30 - daysSince;
                    Map<String, Object> err = new HashMap<>();
                    err.put("fehler", "Anzeigename kann erst in " + daysLeft + " Tagen geändert werden.");
                    err.put("daysLeft", daysLeft);
                    return ResponseEntity.status(429).body(err);
                }
            }
            u.setDisplayName(name.isBlank() ? null : name.trim());
            u.setDisplayNameChangedAt(LocalDateTime.now());
        }
        if (firstName != null) u.setFirstName(firstName.isBlank() ? null : firstName.trim());
        if (lastName  != null) u.setLastName(lastName.isBlank()   ? null : lastName.trim());

        userRepository.save(u);
        return ResponseEntity.ok(nutzerZuMap(u));
    }

    // Nutzer suchen: GET /api/users/search?q=...&userId=X
    @GetMapping("/search")
    public ResponseEntity<?> suchen(@RequestParam String q, @RequestParam Integer userId) {
        if (q.length() < 2) return ResponseEntity.ok(List.of());
        List<User> treffer = userRepository.searchByNameOrEmail(q, userId, PageRequest.of(0, 10));
        List<Map<String, Object>> result = treffer.stream().map(u -> {
            Map<String, Object> m = new HashMap<>();
            m.put("userId",      u.getId());
            m.put("displayName", u.getDisplayName() != null ? u.getDisplayName() : "Nutzer");
            m.put("name",        u.getDisplayName() != null ? u.getDisplayName() : "Nutzer");
            return m;
        }).toList();
        return ResponseEntity.ok(result);
    }

    // Konto deaktivieren (Soft-Delete): DELETE /api/users/{id}
    @DeleteMapping("/{id}")
    public ResponseEntity<?> kontoDeaktivieren(@PathVariable Integer id) {
        User u = userRepository.findById(id).orElse(null);
        if (u == null) return ResponseEntity.notFound().build();
        u.setActive(false);
        userRepository.save(u);
        return ResponseEntity.ok(Map.of("nachricht", "Konto deaktiviert"));
    }

    // Fortschritt zuruecksetzen: DELETE /api/users/{id}/progress
    @DeleteMapping("/{id}/progress")
    public ResponseEntity<?> fortschrittZuruecksetzen(@PathVariable Integer id) {
        User u = userRepository.findById(id).orElse(null);
        if (u == null) return ResponseEntity.notFound().build();

        progressRepository.deleteByUserId(id);

        // XP, Coins und Streak werden bewusst NICHT zurueckgesetzt –
        // nur der Lernfortschritt (abgeschlossene Schritte)
        return ResponseEntity.ok(Map.of("nachricht", "Fortschritt zurueckgesetzt"));
    }

    private Map<String, Object> nutzerZuMap(User u) {
        long daysUntilNameChange = 0;
        if (u.getDisplayNameChangedAt() != null) {
            long daysSince = ChronoUnit.DAYS.between(u.getDisplayNameChangedAt(), LocalDateTime.now());
            daysUntilNameChange = Math.max(0, 30 - daysSince);
        }
        Map<String, Object> m = new HashMap<>();
        m.put("id",                  u.getId());
        m.put("email",               u.getEmail());
        m.put("displayName",         u.getDisplayName() != null ? u.getDisplayName() : "");
        m.put("firstName",           u.getFirstName() != null ? u.getFirstName() : "");
        m.put("lastName",            u.getLastName() != null ? u.getLastName() : "");
        m.put("xp",                  u.getXp());
        m.put("coins",               u.getCoins());
        m.put("streakDays",          u.getStreakDays());
        m.put("subscriptionPlan",    u.getSubscriptionPlan());
        m.put("daysUntilNameChange", daysUntilNameChange);
        return m;
    }
}
