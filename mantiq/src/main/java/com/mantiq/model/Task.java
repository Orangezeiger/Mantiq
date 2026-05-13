package com.mantiq.model;

import jakarta.persistence.*;
import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

// Eine Aufgabe innerhalb eines Schritts
@Entity
@Table(name = "tasks")
public class Task {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;

    // Jede Aufgabe gehoert zu einem Schritt
    @ManyToOne(optional = false)
    @JoinColumn(name = "step_id", nullable = false)
    private Step step;

    // Aufgabentyp (SINGLE_CHOICE, MULTIPLE_CHOICE, ...)
    @ManyToOne(optional = false)
    @JoinColumn(name = "task_type_id", nullable = false)
    private TaskType taskType;

    @Column(nullable = false, columnDefinition = "TEXT")
    private String question;

    // Reihenfolge innerhalb des Schritts
    @Column(nullable = false)
    private Integer position;

    // Nur fuer Zahlenstrahl (NUMBER_LINE) – sonst null
    @Column(name = "number_min", precision = 19, scale = 4)
    private BigDecimal numberMin;

    @Column(name = "number_max", precision = 19, scale = 4)
    private BigDecimal numberMax;

    @Column(name = "number_correct", precision = 19, scale = 4)
    private BigDecimal numberCorrect;

    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt = LocalDateTime.now();

    // Antwortoptionen der Aufgabe
    @OneToMany(mappedBy = "task", cascade = CascadeType.ALL, orphanRemoval = true)
    @OrderBy("position ASC")
    private List<TaskOption> options;

    // --- Getter & Setter ---

    public Integer getId() { return id; }
    public void setId(Integer id) { this.id = id; }

    public Step getStep() { return step; }
    public void setStep(Step step) { this.step = step; }

    public TaskType getTaskType() { return taskType; }
    public void setTaskType(TaskType taskType) { this.taskType = taskType; }

    public String getQuestion() { return question; }
    public void setQuestion(String question) { this.question = question; }

    public Integer getPosition() { return position; }
    public void setPosition(Integer position) { this.position = position; }

    public BigDecimal getNumberMin() { return numberMin; }
    public void setNumberMin(BigDecimal numberMin) { this.numberMin = numberMin; }

    public BigDecimal getNumberMax() { return numberMax; }
    public void setNumberMax(BigDecimal numberMax) { this.numberMax = numberMax; }

    public BigDecimal getNumberCorrect() { return numberCorrect; }
    public void setNumberCorrect(BigDecimal numberCorrect) { this.numberCorrect = numberCorrect; }

    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }

    public List<TaskOption> getOptions() { return options; }
    public void setOptions(List<TaskOption> options) { this.options = options; }
}
