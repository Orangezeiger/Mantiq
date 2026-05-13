package com.mantiq.controller;

import com.mantiq.model.User;
import com.mantiq.repository.UserRepository;
import org.springframework.data.domain.PageRequest;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/leaderboard")
public class LeaderboardController {

    private final UserRepository userRepository;

    public LeaderboardController(UserRepository userRepository) {
        this.userRepository = userRepository;
    }

    // Leaderboard: GET /api/leaderboard?userId=X
    // Gibt globale Top-50 + Freunde-Rangliste zurueck
    @GetMapping
    public ResponseEntity<?> leaderboard(@RequestParam Integer userId) {
        List<User> global  = userRepository.findTopByXp(PageRequest.of(0, 50));
        List<User> freunde = userRepository.findFriendsByXp(userId);

        // Eigenen Nutzer fuer Rang-Berechnung ermitteln
        User ich = userRepository.findById(userId).orElse(null);
        int meinRang = 1;
        if (ich != null) {
            for (User u : global) {
                if (u.getId().equals(userId)) break;
                meinRang++;
            }
        }

        final int rang = meinRang;
        return ResponseEntity.ok(Map.of(
            "global",   global.stream().map(this::nutzerZuMap).toList(),
            "freunde",  freunde.stream().map(this::nutzerZuMap).toList(),
            "meinRang", rang
        ));
    }

    private Map<String, Object> nutzerZuMap(User u) {
        return Map.of(
            "userId",     u.getId(),
            "name",       u.getDisplayName() != null ? u.getDisplayName() : u.getEmail(),
            "xp",         u.getXp(),
            "streakDays", u.getStreakDays()
        );
    }
}
