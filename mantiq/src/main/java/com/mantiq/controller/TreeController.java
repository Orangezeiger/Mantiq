package com.mantiq.controller;

import com.mantiq.dto.response.*;
import com.mantiq.model.*;
import com.mantiq.repository.*;
import com.mantiq.service.TreeService;
import org.springframework.http.ResponseEntity;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/trees")
public class TreeController {

    private final TreeRepository treeRepository;
    private final UserRepository userRepository;
    private final StepRepository stepRepository;
    private final TreeService treeService;

    public TreeController(TreeRepository treeRepository,
                          UserRepository userRepository,
                          StepRepository stepRepository,
                          TreeService treeService) {
        this.treeRepository  = treeRepository;
        this.userRepository  = userRepository;
        this.stepRepository  = stepRepository;
        this.treeService     = treeService;
    }

    // Alle Baeume eines Nutzers laden: GET /api/trees?userId=X
    @GetMapping
    public ResponseEntity<?> alleBaeumeDesNutzers(@RequestParam Integer userId) {
        return ResponseEntity.ok(treeRepository.findSummariesByUserId(userId));
    }

    // Baum-Details mit Schritten: GET /api/trees/{id}?userId=X
    @GetMapping("/{id}")
    public ResponseEntity<?> baumDetails(@PathVariable Integer id, @RequestParam Integer userId) {
        TreeDetailResponse response = treeService.getBaumDetails(id, userId);
        if (response == null) return ResponseEntity.notFound().build();
        return ResponseEntity.ok(response);
    }

    // Leeren Baum anlegen: POST /api/trees
    // Body: { "userId": X, "title": "...", "description": "..." }
    @PostMapping
    public ResponseEntity<?> baumAnlegen(@RequestBody Map<String, Object> body) {
        Integer userId = (Integer) body.get("userId");
        String titel   = (String) body.get("title");

        if (userId == null || titel == null || titel.isBlank()) {
            return ResponseEntity.badRequest().body(Map.of("fehler", "userId und title erforderlich"));
        }

        User nutzer = userRepository.findById(userId).orElse(null);
        if (nutzer == null) {
            return ResponseEntity.badRequest().body(Map.of("fehler", "Nutzer nicht gefunden"));
        }

        Tree baum = new Tree();
        baum.setUser(nutzer);
        baum.setTitle(titel);
        baum.setDescription((String) body.get("description"));
        treeRepository.save(baum);

        return ResponseEntity.ok(Map.of("id", baum.getId(), "titel", baum.getTitle()));
    }

    // Baum umbenennen: PUT /api/trees/{id}
    // Body: { "title": "...", "description": "..." }
    @PutMapping("/{id}")
    public ResponseEntity<?> baumAktualisieren(@PathVariable Integer id,
                                               @RequestBody Map<String, String> body) {
        Tree baum = treeRepository.findById(id).orElse(null);
        if (baum == null) return ResponseEntity.notFound().build();

        String titel = body.get("title");
        if (titel != null && !titel.isBlank()) baum.setTitle(titel.trim());
        if (body.containsKey("description")) baum.setDescription(body.get("description"));
        treeRepository.save(baum);

        return ResponseEntity.ok(Map.of("id", baum.getId(), "title", baum.getTitle()));
    }

    // Baum loeschen: DELETE /api/trees/{id}
    @DeleteMapping("/{id}")
    public ResponseEntity<?> baumLoeschen(@PathVariable Integer id) {
        if (!treeRepository.existsById(id)) {
            return ResponseEntity.notFound().build();
        }
        treeRepository.deleteById(id);
        return ResponseEntity.noContent().build();
    }

    // Schritt hinzufuegen: POST /api/trees/{id}/steps
    // Body: { "title": "..." }
    @PostMapping("/{id}/steps")
    public ResponseEntity<?> schrittHinzufuegen(@PathVariable Integer id,
                                                 @RequestBody Map<String, String> body) {
        String titel = body.get("title");
        if (titel == null || titel.isBlank()) {
            return ResponseEntity.badRequest().body(Map.of("fehler", "title erforderlich"));
        }

        Tree baum = treeRepository.findById(id).orElse(null);
        if (baum == null) return ResponseEntity.notFound().build();

        int naechstePosition = stepRepository.findMaxPositionByTreeId(id) + 1;

        Step schritt = new Step();
        schritt.setTree(baum);
        schritt.setTitle(titel);
        schritt.setPosition(naechstePosition);
        stepRepository.save(schritt);

        return ResponseEntity.ok(Map.of(
            "id",       schritt.getId(),
            "title",    schritt.getTitle(),
            "position", schritt.getPosition()
        ));
    }

    // Schritte neu anordnen: POST /api/trees/{id}/steps/reorder
    // Body: [{"id": 1, "position": 0}, {"id": 2, "position": 1}, ...]
    @PostMapping("/{id}/steps/reorder")
    @Transactional
    public ResponseEntity<?> schritteSortieren(@PathVariable Integer id,
                                               @RequestBody List<Map<String, Integer>> reihenfolge) {
        if (!treeRepository.existsById(id)) return ResponseEntity.notFound().build();

        for (Map<String, Integer> eintrag : reihenfolge) {
            Integer stepId   = eintrag.get("id");
            Integer position = eintrag.get("position");
            if (stepId == null || position == null) continue;

            stepRepository.findById(stepId).ifPresent(s -> {
                s.setPosition(position);
                stepRepository.save(s);
            });
        }
        return ResponseEntity.ok(Map.of("nachricht", "Reihenfolge gespeichert"));
    }
}
