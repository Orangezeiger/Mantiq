package com.mantiq.controller;

import com.mantiq.model.User;
import com.mantiq.repository.UserProgressRepository;
import com.mantiq.repository.UserRepository;
import org.springframework.data.domain.PageRequest;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

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

        String name = body.get("displayName");
        if (name != null) u.setDisplayName(name.isBlank() ? null : name.trim());
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
            m.put("displayName", u.getDisplayName() != null ? u.getDisplayName() : "");
            m.put("email",       u.getEmail());
            m.put("name",        u.getDisplayName() != null ? u.getDisplayName() : u.getEmail());
            return m;
        }).toList();
        return ResponseEntity.ok(result);
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
        return Map.of(
            "id",               u.getId(),
            "email",            u.getEmail(),
            "displayName",      u.getDisplayName() != null ? u.getDisplayName() : "",
            "xp",               u.getXp(),
            "coins",            u.getCoins(),
            "streakDays",       u.getStreakDays(),
            "subscriptionPlan", u.getSubscriptionPlan()
        );
    }
}
