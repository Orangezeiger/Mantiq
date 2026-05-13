package com.mantiq.controller;

import com.mantiq.dto.response.TaskResponse;
import com.mantiq.model.Step;
import com.mantiq.model.User;
import com.mantiq.model.UserProgress;
import com.mantiq.repository.StepRepository;
import com.mantiq.repository.UserProgressRepository;
import com.mantiq.repository.UserRepository;
import com.mantiq.service.StepService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/steps")
public class StepController {

    private final StepRepository stepRepository;
    private final UserRepository userRepository;
    private final UserProgressRepository progressRepository;
    private final StepService stepService;

    public StepController(StepRepository stepRepository,
                          UserRepository userRepository,
                          UserProgressRepository progressRepository,
                          StepService stepService) {
        this.stepRepository    = stepRepository;
        this.userRepository    = userRepository;
        this.progressRepository = progressRepository;
        this.stepService       = stepService;
    }

    // Aufgaben eines Schritts: GET /api/steps/{id}/tasks
    @GetMapping("/{id}/tasks")
    public ResponseEntity<?> aufgabenDesSchritts(@PathVariable Integer id) {
        List<TaskResponse> aufgaben = stepService.getStepTasks(id);
        if (aufgaben == null) return ResponseEntity.notFound().build();
        return ResponseEntity.ok(aufgaben);
    }

    // Schritt abschliessen + XP/Coins/Streak vergeben: POST /api/steps/{id}/complete
    // Body: { "userId": X }
    @PostMapping("/{id}/complete")
    public ResponseEntity<?> schrittAbschliessen(@PathVariable Integer id,
                                                  @RequestBody Map<String, Integer> body) {
        Integer userId = body.get("userId");
        if (userId == null)
            return ResponseEntity.badRequest().body(Map.of("fehler", "userId erforderlich"));

        if (progressRepository.existsByUserIdAndStepId(userId, id))
            return ResponseEntity.ok(Map.of("nachricht", "Bereits abgeschlossen"));

        Step schritt = stepRepository.findById(id).orElse(null);
        User nutzer  = userRepository.findById(userId).orElse(null);
        if (schritt == null || nutzer == null) return ResponseEntity.notFound().build();

        // Fortschritt eintragen
        UserProgress fortschritt = new UserProgress();
        fortschritt.setUser(nutzer);
        fortschritt.setStep(schritt);
        progressRepository.save(fortschritt);

        // XP und Coins vergeben
        nutzer.setXp(nutzer.getXp() + 10);
        nutzer.setCoins(nutzer.getCoins() + 5);

        // Streak-Logik
        LocalDate heute   = LocalDate.now();
        LocalDate gestern = heute.minusDays(1);
        LocalDate letzteAktivitaet = nutzer.getLastActiveDate();

        if (letzteAktivitaet == null) {
            // Erster Abschluss ueberhaupt
            nutzer.setStreakDays(1);
        } else if (letzteAktivitaet.equals(heute)) {
            // Heute schon aktiv – Streak unveraendert
        } else if (letzteAktivitaet.equals(gestern)) {
            // Gestern aktiv – Streak erhoehen
            nutzer.setStreakDays(nutzer.getStreakDays() + 1);
            nutzer.setStreakBeforeReset(0); // alte Sicherung loeschen
        } else {
            // Luecke – Streak verloren, alte Streak fuer Schild-Wiederherstellung speichern
            nutzer.setStreakBeforeReset(nutzer.getStreakDays());
            nutzer.setStreakDays(1);
        }
        nutzer.setLastActiveDate(heute);
        userRepository.save(nutzer);

        return ResponseEntity.ok(Map.of(
            "nachricht",  "Schritt abgeschlossen",
            "xp",         nutzer.getXp(),
            "coins",      nutzer.getCoins(),
            "streakDays", nutzer.getStreakDays()
        ));
    }

    // Schritt loeschen: DELETE /api/steps/{id}
    @DeleteMapping("/{id}")
    public ResponseEntity<?> schrittLoeschen(@PathVariable Integer id) {
        if (!stepRepository.existsById(id)) return ResponseEntity.notFound().build();
        stepRepository.deleteById(id);
        return ResponseEntity.noContent().build();
    }

    // Schritt umbenennen: PUT /api/steps/{id}
    // Body: { "title": "..." }
    @PutMapping("/{id}")
    public ResponseEntity<?> schrittUmbenennen(@PathVariable Integer id,
                                               @RequestBody Map<String, String> body) {
        String titel = body.get("title");
        if (titel == null || titel.isBlank())
            return ResponseEntity.badRequest().body(Map.of("fehler", "title erforderlich"));

        Step schritt = stepRepository.findById(id).orElse(null);
        if (schritt == null) return ResponseEntity.notFound().build();

        schritt.setTitle(titel.trim());
        stepRepository.save(schritt);

        return ResponseEntity.ok(Map.of("id", schritt.getId(), "title", schritt.getTitle()));
    }
}
