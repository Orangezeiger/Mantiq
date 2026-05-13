package com.mantiq.controller;

import com.mantiq.model.Friendship;
import com.mantiq.model.User;
import com.mantiq.repository.FriendshipRepository;
import com.mantiq.repository.UserRepository;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/friends")
public class FriendController {

    private final FriendshipRepository friendshipRepository;
    private final UserRepository userRepository;

    public FriendController(FriendshipRepository friendshipRepository,
                            UserRepository userRepository) {
        this.friendshipRepository = friendshipRepository;
        this.userRepository       = userRepository;
    }

    // Freundesliste: GET /api/friends?userId=X
    @GetMapping
    public ResponseEntity<?> freundeListe(@RequestParam Integer userId) {
        List<Friendship> liste = friendshipRepository.findAcceptedByUserId(userId);
        List<Map<String, Object>> result = liste.stream().map(f -> {
            User anderer = f.getUser().getId().equals(userId) ? f.getFriend() : f.getUser();
            return nutzerZuMap(anderer, f.getId());
        }).toList();
        return ResponseEntity.ok(result);
    }

    // Offene Anfragen: GET /api/friends/requests?userId=X
    @GetMapping("/requests")
    public ResponseEntity<?> offeneAnfragen(@RequestParam Integer userId) {
        List<Friendship> liste = friendshipRepository.findPendingRequestsForUser(userId);
        List<Map<String, Object>> result = liste.stream().map(f -> {
            Map<String, Object> m = new HashMap<>();
            m.put("requestId", f.getId());
            m.put("userId",    f.getUser().getId());
            m.put("name",      f.getUser().getDisplayName() != null
                               ? f.getUser().getDisplayName() : "Nutzer");
            return m;
        }).toList();
        return ResponseEntity.ok(result);
    }

    // Freundschaftsanfrage senden: POST /api/friends/request
    // Body: { "fromUserId": X, "toUserId": Y }
    @PostMapping("/request")
    public ResponseEntity<?> anfrageSenden(@RequestBody Map<String, Object> body) {
        Integer fromId = (Integer) body.get("fromUserId");
        Integer toId   = (Integer) body.get("toUserId");

        User sender    = userRepository.findById(fromId).orElse(null);
        User empfaenger = toId != null ? userRepository.findById(toId).orElse(null) : null;

        if (sender == null || empfaenger == null)
            return ResponseEntity.badRequest().body(Map.of("fehler", "Nutzer nicht gefunden"));
        if (sender.getId().equals(empfaenger.getId()))
            return ResponseEntity.badRequest().body(Map.of("fehler", "Kannst dir nicht selbst eine Anfrage senden"));

        if (friendshipRepository.findBetween(sender.getId(), empfaenger.getId()).isPresent())
            return ResponseEntity.badRequest().body(Map.of("fehler", "Anfrage existiert bereits"));

        Friendship f = new Friendship();
        f.setUser(sender);
        f.setFriend(empfaenger);
        friendshipRepository.save(f);

        return ResponseEntity.ok(Map.of("nachricht", "Anfrage gesendet"));
    }

    // Anfrage akzeptieren: POST /api/friends/{id}/accept
    @PostMapping("/{id}/accept")
    public ResponseEntity<?> akzeptieren(@PathVariable Integer id) {
        Friendship f = friendshipRepository.findById(id).orElse(null);
        if (f == null) return ResponseEntity.notFound().build();
        f.setStatus("ACCEPTED");
        friendshipRepository.save(f);
        return ResponseEntity.ok(Map.of("nachricht", "Freundschaft akzeptiert"));
    }

    // Freund entfernen / Anfrage ablehnen: DELETE /api/friends/{id}
    @DeleteMapping("/{id}")
    public ResponseEntity<?> entfernen(@PathVariable Integer id) {
        if (!friendshipRepository.existsById(id)) return ResponseEntity.notFound().build();
        friendshipRepository.deleteById(id);
        return ResponseEntity.noContent().build();
    }

    private Map<String, Object> nutzerZuMap(User u, Integer friendshipId) {
        Map<String, Object> m = new HashMap<>();
        m.put("friendshipId", friendshipId);
        m.put("userId",       u.getId());
        m.put("name",         u.getDisplayName() != null ? u.getDisplayName() : "Nutzer");
        m.put("xp",           u.getXp());
        m.put("streakDays",   u.getStreakDays());
        return m;
    }
}
