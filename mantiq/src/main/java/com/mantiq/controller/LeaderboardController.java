package com.mantiq.controller;

import com.mantiq.model.User;
import com.mantiq.repository.UserRepository;
import org.springframework.data.domain.PageRequest;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.time.temporal.ChronoUnit;
import java.util.*;
import java.util.stream.Stream;

@RestController
@RequestMapping("/api/leaderboard")
public class LeaderboardController {

    // Liga-Definitionen: name, emoji, minXp, maxXp (-1 = unbegrenzt), Belohnung 1./2./3. Platz
    private static final int[][] LIGA_GRENZEN = {
        {0,      1_500},   // Bronze
        {1_500,  5_000},   // Silber
        {5_000, 10_000},   // Gold
        {10_000, 25_000},  // Platin
        {25_000, -1},      // Diamant
    };
    private static final String[] LIGA_NAMEN   = {"Bronze", "Silber", "Gold", "Platin", "Diamant"};
    private static final String[] LIGA_EMOJIS  = {"🥉", "🥈", "🥇", "💎", "👑"};
    private static final int[]    BELOHNUNGEN  = {100, 60, 30}; // 1./2./3. Platz (Coins)

    private final UserRepository userRepository;

    public LeaderboardController(UserRepository userRepository) {
        this.userRepository = userRepository;
    }

    // GET /api/leaderboard?userId=X
    @GetMapping
    public ResponseEntity<?> leaderboard(@RequestParam Integer userId) {
        User ich = userRepository.findById(userId).orElse(null);
        if (ich == null) return ResponseEntity.notFound().build();

        // Liga ermitteln
        int ligaIndex = ligaFuer(ich.getXp());
        int minXp = LIGA_GRENZEN[ligaIndex][0];
        int maxXp = LIGA_GRENZEN[ligaIndex][1];

        // 12 Mitglieder in dieser Liga (inkl. sich selbst)
        List<User> mitglieder = maxXp == -1
            ? userRepository.findTopLeagueMembers(minXp, PageRequest.of(0, 12))
            : userRepository.findLeagueMembers(minXp, maxXp, PageRequest.of(0, 12));

        // Eigener Rang in der Liga
        int ligaRang = 1;
        for (User u : mitglieder) {
            if (u.getId().equals(userId)) break;
            ligaRang++;
        }

        // Belohnung verfuegbar?
        boolean kannBelohnen = ligaRang <= 3 && kannBelohnungAblegen(ich);

        // Global Top-50
        List<User> global = userRepository.findTopByXp(PageRequest.of(0, 50));
        int globalRang = 1;
        for (User u : global) {
            if (u.getId().equals(userId)) break;
            globalRang++;
        }

        // Freunde (beide Richtungen zusammenfuehren, nach XP sortieren)
        List<User> freunde = Stream.concat(
                userRepository.findFriendsAsSender(userId).stream(),
                userRepository.findFriendsAsReceiver(userId).stream())
            .sorted(Comparator.comparingInt(User::getXp).reversed())
            .toList();

        Map<String, Object> liga = new HashMap<>();
        liga.put("name",            LIGA_NAMEN[ligaIndex]);
        liga.put("emoji",           LIGA_EMOJIS[ligaIndex]);
        liga.put("index",           ligaIndex);
        liga.put("members",         mitglieder.stream().map(u -> nutzerZuMap(u, userId)).toList());
        liga.put("myRank",          ligaRang);
        liga.put("kannBelohnen",    kannBelohnen);
        liga.put("belohnungCoins",  ligaRang <= 3 ? BELOHNUNGEN[ligaRang - 1] : 0);

        Map<String, Object> res = new HashMap<>();
        res.put("liga",       liga);
        res.put("global",     global.stream().map(u -> nutzerZuMap(u, userId)).toList());
        res.put("freunde",    freunde.stream().map(u -> nutzerZuMap(u, userId)).toList());
        res.put("meinRang",   globalRang);
        return ResponseEntity.ok(res);
    }

    // POST /api/leaderboard/claim-reward  { "userId": X }
    @PostMapping("/claim-reward")
    public ResponseEntity<?> belohnungAblegen(@RequestBody Map<String, Integer> body) {
        Integer userId = body.get("userId");
        User ich = userRepository.findById(userId).orElse(null);
        if (ich == null) return ResponseEntity.notFound().build();

        int ligaIndex = ligaFuer(ich.getXp());
        int minXp = LIGA_GRENZEN[ligaIndex][0];
        int maxXp = LIGA_GRENZEN[ligaIndex][1];
        List<User> mitglieder = maxXp == -1
            ? userRepository.findTopLeagueMembers(minXp, PageRequest.of(0, 3))
            : userRepository.findLeagueMembers(minXp, maxXp, PageRequest.of(0, 3));

        int rang = 1;
        boolean inTop3 = false;
        for (User u : mitglieder) {
            if (u.getId().equals(userId)) { inTop3 = true; break; }
            rang++;
        }

        if (!inTop3 || rang > 3)
            return ResponseEntity.badRequest().body(Map.of("fehler", "Nicht in Top 3"));
        if (!kannBelohnungAblegen(ich))
            return ResponseEntity.badRequest().body(Map.of("fehler", "Bereits diese Woche abgeholt"));

        int coins = BELOHNUNGEN[rang - 1];
        ich.setCoins(ich.getCoins() + coins);
        ich.setLastRewardClaimedAt(LocalDateTime.now());
        userRepository.save(ich);

        return ResponseEntity.ok(Map.of("coins", coins, "gesamtCoins", ich.getCoins()));
    }

    private boolean kannBelohnungAblegen(User u) {
        if (u.getLastRewardClaimedAt() == null) return true;
        return ChronoUnit.DAYS.between(u.getLastRewardClaimedAt(), LocalDateTime.now()) >= 7;
    }

    private int ligaFuer(int xp) {
        for (int i = LIGA_GRENZEN.length - 1; i >= 0; i--) {
            if (xp >= LIGA_GRENZEN[i][0]) return i;
        }
        return 0;
    }

    private Map<String, Object> nutzerZuMap(User u, Integer myId) {
        Map<String, Object> m = new HashMap<>();
        m.put("userId",     u.getId());
        m.put("name",       u.getDisplayName() != null ? u.getDisplayName() : "Nutzer");
        m.put("xp",         u.getXp());
        m.put("streakDays", u.getStreakDays());
        m.put("isMe",       u.getId().equals(myId));
        return m;
    }
}
