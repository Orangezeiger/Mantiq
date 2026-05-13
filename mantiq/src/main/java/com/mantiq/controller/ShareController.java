package com.mantiq.controller;

import com.mantiq.model.*;
import com.mantiq.repository.*;
import org.springframework.http.ResponseEntity;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;

import java.security.SecureRandom;
import java.util.*;

@RestController
@RequestMapping("/api/shares")
public class ShareController {

    private static final String CODE_CHARS = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";
    private static final SecureRandom RNG   = new SecureRandom();

    private final TreeShareRepository    shareRepository;
    private final TreeRepository         treeRepository;
    private final UserRepository         userRepository;
    private final StepRepository         stepRepository;
    private final TaskRepository         taskRepository;
    private final TaskOptionRepository   optionRepository;
    private final TaskTypeRepository     taskTypeRepository;

    public ShareController(TreeShareRepository shareRepository,
                           TreeRepository treeRepository,
                           UserRepository userRepository,
                           StepRepository stepRepository,
                           TaskRepository taskRepository,
                           TaskOptionRepository optionRepository,
                           TaskTypeRepository taskTypeRepository) {
        this.shareRepository   = shareRepository;
        this.treeRepository    = treeRepository;
        this.userRepository    = userRepository;
        this.stepRepository    = stepRepository;
        this.taskRepository    = taskRepository;
        this.optionRepository  = optionRepository;
        this.taskTypeRepository = taskTypeRepository;
    }

    // ── Code generieren: POST /api/shares/generate ──────────────────
    // Body: { "treeId": X, "userId": X }
    @PostMapping("/generate")
    public ResponseEntity<?> generate(@RequestBody Map<String, Integer> body) {
        Integer treeId = body.get("treeId");
        Integer userId = body.get("userId");
        if (treeId == null || userId == null)
            return ResponseEntity.badRequest().body(Map.of("fehler", "treeId und userId erforderlich"));

        Tree baum = treeRepository.findById(treeId).orElse(null);
        if (baum == null) return ResponseEntity.notFound().build();

        // Existierenden Code wiederverwenden
        TreeShare share = shareRepository.findByTreeId(treeId).orElseGet(() -> {
            TreeShare s = new TreeShare();
            s.setTree(baum);
            s.setCode(genCode());
            s.setCreatedByUserId(userId);
            return shareRepository.save(s);
        });

        return ResponseEntity.ok(Map.of("code", share.getCode(), "title", baum.getTitle()));
    }

    // ── Vorschau per Code: GET /api/shares/{code} ───────────────────
    @GetMapping("/{code}")
    public ResponseEntity<?> vorschau(@PathVariable String code) {
        TreeShare share = shareRepository.findByCode(code.toUpperCase()).orElse(null);
        if (share == null) return ResponseEntity.notFound().build();
        Tree baum = share.getTree();
        return ResponseEntity.ok(Map.of(
            "title",     baum.getTitle(),
            "description", baum.getDescription() != null ? baum.getDescription() : "",
            "stepCount", baum.getSteps() != null ? baum.getSteps().size() : 0
        ));
    }

    // ── Per Code importieren: POST /api/shares/{code}/import ────────
    // Body: { "userId": X }
    @PostMapping("/{code}/import")
    @Transactional
    public ResponseEntity<?> importByCode(@PathVariable String code,
                                          @RequestBody Map<String, Integer> body) {
        Integer userId = body.get("userId");
        TreeShare share = shareRepository.findByCode(code.toUpperCase()).orElse(null);
        if (share == null) return ResponseEntity.notFound().build();
        User user = userRepository.findById(userId).orElse(null);
        if (user == null) return ResponseEntity.badRequest().body(Map.of("fehler", "Nutzer nicht gefunden"));

        Tree kopie = baumKopieren(share.getTree(), user);
        return ResponseEntity.ok(Map.of(
            "id",    kopie.getId(),
            "title", kopie.getTitle()
        ));
    }

    // ── Als JSON exportieren: GET /api/shares/export/{treeId} ───────
    @GetMapping("/export/{treeId}")
    @Transactional
    public ResponseEntity<?> export(@PathVariable Integer treeId) {
        Tree baum = treeRepository.findById(treeId).orElse(null);
        if (baum == null) return ResponseEntity.notFound().build();
        return ResponseEntity.ok(baumZuExportMap(baum));
    }

    // ── Per Datei importieren: POST /api/shares/import-file ─────────
    // Body: { "userId": X, "tree": { title, description, steps: [...] } }
    @PostMapping("/import-file")
    @Transactional
    @SuppressWarnings("unchecked")
    public ResponseEntity<?> importFile(@RequestBody Map<String, Object> body) {
        Integer userId = (Integer) body.get("userId");
        Map<String, Object> treeData = (Map<String, Object>) body.get("tree");
        if (userId == null || treeData == null)
            return ResponseEntity.badRequest().body(Map.of("fehler", "userId und tree erforderlich"));

        User user = userRepository.findById(userId).orElse(null);
        if (user == null) return ResponseEntity.badRequest().body(Map.of("fehler", "Nutzer nicht gefunden"));

        Tree baum = new Tree();
        baum.setUser(user);
        baum.setTitle((String) treeData.getOrDefault("title", "Importierter Baum"));
        baum.setDescription((String) treeData.get("description"));
        treeRepository.save(baum);

        List<Map<String, Object>> steps = (List<Map<String, Object>>) treeData.getOrDefault("steps", List.of());
        for (int si = 0; si < steps.size(); si++) {
            Map<String, Object> stepData = steps.get(si);
            Step schritt = new Step();
            schritt.setTree(baum);
            schritt.setTitle((String) stepData.getOrDefault("title", "Schritt " + (si + 1)));
            schritt.setPosition(si);
            stepRepository.save(schritt);

            List<Map<String, Object>> tasks = (List<Map<String, Object>>) stepData.getOrDefault("tasks", List.of());
            for (int ti = 0; ti < tasks.size(); ti++) {
                Map<String, Object> taskData = tasks.get(ti);
                String typName = (String) taskData.getOrDefault("type", "SINGLE_CHOICE");
                TaskType typ = taskTypeRepository.findByName(typName)
                        .orElse(taskTypeRepository.findByName("SINGLE_CHOICE").orElseThrow());

                Task aufgabe = new Task();
                aufgabe.setStep(schritt);
                aufgabe.setTaskType(typ);
                aufgabe.setQuestion((String) taskData.getOrDefault("question", ""));
                aufgabe.setPosition(ti);
                taskRepository.save(aufgabe);

                List<Map<String, Object>> opts = (List<Map<String, Object>>) taskData.getOrDefault("options", List.of());
                for (int oi = 0; oi < opts.size(); oi++) {
                    Map<String, Object> optData = opts.get(oi);
                    TaskOption opt = new TaskOption();
                    opt.setTask(aufgabe);
                    opt.setOptionText((String) optData.getOrDefault("text", ""));
                    opt.setIsCorrect((Boolean) optData.getOrDefault("correct", false));
                    opt.setPosition(oi);
                    if (optData.get("matchGroup") instanceof Integer mg) opt.setMatchGroup(mg);
                    optionRepository.save(opt);
                }
            }
        }

        return ResponseEntity.ok(Map.of("id", baum.getId(), "title", baum.getTitle()));
    }

    // ── Hilfsmethoden ────────────────────────────────────────────────

    @Transactional
    Tree baumKopieren(Tree quelle, User zielNutzer) {
        Tree kopie = new Tree();
        kopie.setUser(zielNutzer);
        kopie.setTitle(quelle.getTitle());
        kopie.setDescription(quelle.getDescription());
        treeRepository.save(kopie);

        if (quelle.getSteps() == null) return kopie;
        for (Step qs : quelle.getSteps()) {
            Step ns = new Step();
            ns.setTree(kopie);
            ns.setTitle(qs.getTitle());
            ns.setPosition(qs.getPosition());
            stepRepository.save(ns);

            if (qs.getTasks() == null) continue;
            for (Task qt : qs.getTasks()) {
                Task nt = new Task();
                nt.setStep(ns);
                nt.setTaskType(qt.getTaskType());
                nt.setQuestion(qt.getQuestion());
                nt.setPosition(qt.getPosition());
                nt.setNumberMin(qt.getNumberMin());
                nt.setNumberMax(qt.getNumberMax());
                nt.setNumberCorrect(qt.getNumberCorrect());
                taskRepository.save(nt);

                if (qt.getOptions() == null) continue;
                for (TaskOption qo : qt.getOptions()) {
                    TaskOption no = new TaskOption();
                    no.setTask(nt);
                    no.setOptionText(qo.getOptionText());
                    no.setIsCorrect(qo.getIsCorrect());
                    no.setPosition(qo.getPosition());
                    no.setMatchGroup(qo.getMatchGroup());
                    optionRepository.save(no);
                }
            }
        }
        return kopie;
    }

    private Map<String, Object> baumZuExportMap(Tree baum) {
        List<Map<String, Object>> steps = new ArrayList<>();
        if (baum.getSteps() != null) {
            for (Step s : baum.getSteps()) {
                List<Map<String, Object>> tasks = new ArrayList<>();
                if (s.getTasks() != null) {
                    for (Task t : s.getTasks()) {
                        List<Map<String, Object>> opts = new ArrayList<>();
                        if (t.getOptions() != null) {
                            for (TaskOption o : t.getOptions()) {
                                Map<String, Object> om = new HashMap<>();
                                om.put("text",    o.getOptionText());
                                om.put("correct", o.getIsCorrect());
                                om.put("position", o.getPosition());
                                if (o.getMatchGroup() != null) om.put("matchGroup", o.getMatchGroup());
                                opts.add(om);
                            }
                        }
                        Map<String, Object> tm = new HashMap<>();
                        tm.put("type",     t.getTaskType().getName());
                        tm.put("question", t.getQuestion());
                        tm.put("position", t.getPosition());
                        tm.put("options",  opts);
                        tasks.add(tm);
                    }
                }
                Map<String, Object> sm = new HashMap<>();
                sm.put("title",    s.getTitle());
                sm.put("position", s.getPosition());
                sm.put("tasks",    tasks);
                steps.add(sm);
            }
        }
        Map<String, Object> m = new HashMap<>();
        m.put("title",       baum.getTitle());
        m.put("description", baum.getDescription() != null ? baum.getDescription() : "");
        m.put("steps",       steps);
        return m;
    }

    private String genCode() {
        StringBuilder sb = new StringBuilder(6);
        for (int i = 0; i < 6; i++) sb.append(CODE_CHARS.charAt(RNG.nextInt(CODE_CHARS.length())));
        return sb.toString();
    }
}
