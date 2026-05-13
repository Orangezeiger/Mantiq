package com.mantiq.service;

import com.mantiq.model.*;
import com.mantiq.repository.*;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Service
public class DemoTreeService {

    private final TreeRepository     treeRepo;
    private final StepRepository     stepRepo;
    private final TaskTypeRepository taskTypeRepo;

    public DemoTreeService(TreeRepository treeRepo, StepRepository stepRepo,
                           TaskTypeRepository taskTypeRepo) {
        this.treeRepo     = treeRepo;
        this.stepRepo     = stepRepo;
        this.taskTypeRepo = taskTypeRepo;
    }

    @Transactional
    public void createForUser(User user) {
        if (treeRepo.existsByUserIdAndTitle(user.getId(), "Grundlagen der Mathematik")) return;

        Map<String, TaskType> tt = new HashMap<>();
        taskTypeRepo.findAll().forEach(t -> tt.put(t.getName(), t));

        Tree tree = new Tree();
        tree.setUser(user);
        tree.setTitle("Grundlagen der Mathematik");
        tree.setDescription("Grundrechenarten, Potenzen, Wurzeln, Brüche & mehr");
        treeRepo.save(tree);

        // ── Schritt 0: Grundrechenarten ──────────────────────
        Step s0 = step(tree, "Grundrechenarten", 0);
        List<Task> t0 = new ArrayList<>();
        t0.add(task(s0, tt.get("SINGLE_CHOICE"), "Was ist 12 × 7?", 0,
            opt("84", true, null), opt("74", false, null),
            opt("82", false, null), opt("94", false, null)));
        t0.add(task(s0, tt.get("TRUE_FALSE"), "15 ÷ 3 = 5", 1,
            opt("Wahr", true, null), opt("Falsch", false, null)));
        t0.add(task(s0, tt.get("FILL_BLANK"), "8 × 9 = ___", 2,
            opt("72", true, null), opt("63", false, null),
            opt("81", false, null), opt("54", false, null)));
        t0.add(task(s0, tt.get("SINGLE_CHOICE"), "144 ÷ 12 = ?", 3,
            opt("12", true, null), opt("11", false, null),
            opt("13", false, null), opt("14", false, null)));
        s0.setTasks(t0);
        stepRepo.save(s0);

        // ── Schritt 1: Potenzgesetze ─────────────────────────
        Step s1 = step(tree, "Potenzgesetze", 1);
        List<Task> t1 = new ArrayList<>();
        t1.add(task(s1, tt.get("SINGLE_CHOICE"), "Was ist 2¹⁰?", 0,
            opt("1024", true, null), opt("512", false, null),
            opt("2048", false, null), opt("256", false, null)));
        t1.add(task(s1, tt.get("TRUE_FALSE"), "aᵐ · aⁿ = aᵐ⁺ⁿ", 1,
            opt("Wahr", true, null), opt("Falsch", false, null)));
        t1.add(task(s1, tt.get("SORTING"), "Sortiere aufsteigend nach Wert:", 2,
            opt("2¹ = 2", true, 0), opt("2³ = 8", true, 1),
            opt("2⁴ = 16", true, 2), opt("2⁵ = 32", true, 3)));
        t1.add(task(s1, tt.get("FILL_BLANK"), "3⁴ = ___", 3,
            opt("81", true, null), opt("27", false, null),
            opt("64", false, null), opt("36", false, null)));
        t1.add(task(s1, tt.get("SINGLE_CHOICE"), "Welches Gesetz gilt? (a²)³ = ?", 4,
            opt("a⁶", true, null), opt("a⁵", false, null),
            opt("a⁸", false, null), opt("a²/³", false, null)));
        s1.setTasks(t1);
        stepRepo.save(s1);

        // ── Schritt 2: Wurzeln ───────────────────────────────
        Step s2 = step(tree, "Wurzeln", 2);
        List<Task> t2 = new ArrayList<>();
        t2.add(task(s2, tt.get("SINGLE_CHOICE"), "√144 = ?", 0,
            opt("12", true, null), opt("11", false, null),
            opt("13", false, null), opt("14", false, null)));
        t2.add(task(s2, tt.get("TRUE_FALSE"), "√(a²) = |a| für alle reellen Zahlen", 1,
            opt("Wahr", true, null), opt("Falsch", false, null)));
        t2.add(task(s2, tt.get("SINGLE_CHOICE"), "³√27 = ?", 2,
            opt("3", true, null), opt("9", false, null),
            opt("6", false, null), opt("27", false, null)));
        t2.add(task(s2, tt.get("SORTING"), "Sortiere aufsteigend nach Wert:", 3,
            opt("√4 = 2", true, 0), opt("√9 = 3", true, 1),
            opt("√16 = 4", true, 2), opt("√25 = 5", true, 3)));
        t2.add(task(s2, tt.get("FILL_BLANK"), "√(9 · 16) = ___", 4,
            opt("12", true, null), opt("25", false, null),
            opt("144", false, null), opt("6", false, null)));
        s2.setTasks(t2);
        stepRepo.save(s2);

        // ── Schritt 3: Bruchrechnung ─────────────────────────
        Step s3 = step(tree, "Bruchrechnung", 3);
        List<Task> t3 = new ArrayList<>();
        t3.add(task(s3, tt.get("SINGLE_CHOICE"), "½ + ⅓ = ?", 0,
            opt("5/6", true, null), opt("2/5", false, null),
            opt("2/6", false, null), opt("3/5", false, null)));
        t3.add(task(s3, tt.get("TRUE_FALSE"), "¾ × 4/3 = 1", 1,
            opt("Wahr", true, null), opt("Falsch", false, null)));
        t3.add(task(s3, tt.get("FILL_BLANK"), "2/3 + 1/6 = ___", 2,
            opt("5/6", true, null), opt("3/9", false, null),
            opt("1/2", false, null), opt("7/9", false, null)));
        t3.add(task(s3, tt.get("SINGLE_CHOICE"), "Welcher Bruch ist am größten?", 3,
            opt("3/4", true, null), opt("2/3", false, null),
            opt("5/8", false, null), opt("7/12", false, null)));
        t3.add(task(s3, tt.get("TRUE_FALSE"), "3/5 > 5/8", 4,
            opt("Wahr", false, null), opt("Falsch", true, null)));
        s3.setTasks(t3);
        stepRepo.save(s3);

        // ── Schritt 4: Klammern & Vorrang ────────────────────
        Step s4 = step(tree, "Klammern & Vorrang", 4);
        List<Task> t4 = new ArrayList<>();
        t4.add(task(s4, tt.get("SINGLE_CHOICE"), "Was ergibt 2 + 3 × 4?", 0,
            opt("14", true, null), opt("20", false, null),
            opt("10", false, null), opt("18", false, null)));
        t4.add(task(s4, tt.get("SORTING"), "Rechenreihenfolge (zuerst → zuletzt):", 1,
            opt("Klammern",       true, 0), opt("Potenzen",       true, 1),
            opt("Punktrechnung",  true, 2), opt("Strichrechnung",  true, 3)));
        t4.add(task(s4, tt.get("TRUE_FALSE"), "(a+b)² = a² + 2ab + b²", 2,
            opt("Wahr", true, null), opt("Falsch", false, null)));
        t4.add(task(s4, tt.get("FILL_BLANK"), "3 × (4 + 2) = ___", 3,
            opt("18", true, null), opt("14", false, null),
            opt("21", false, null), opt("24", false, null)));
        t4.add(task(s4, tt.get("SINGLE_CHOICE"), "Was ergibt 4² − (3 + 1) × 2?", 4,
            opt("8", true, null), opt("6", false, null),
            opt("24", false, null), opt("12", false, null)));
        s4.setTasks(t4);
        stepRepo.save(s4);
    }

    private Step step(Tree tree, String title, int pos) {
        Step s = new Step();
        s.setTree(tree);
        s.setTitle(title);
        s.setPosition(pos);
        return s;
    }

    private Task task(Step step, TaskType type, String question, int pos, TaskOption... opts) {
        Task t = new Task();
        t.setStep(step);
        t.setTaskType(type);
        t.setQuestion(question);
        t.setPosition(pos);
        List<TaskOption> list = new ArrayList<>();
        for (TaskOption o : opts) { o.setTask(t); list.add(o); }
        t.setOptions(list);
        return t;
    }

    private TaskOption opt(String text, boolean correct, Integer position) {
        TaskOption o = new TaskOption();
        o.setOptionText(text);
        o.setIsCorrect(correct);
        o.setPosition(position);
        return o;
    }
}
