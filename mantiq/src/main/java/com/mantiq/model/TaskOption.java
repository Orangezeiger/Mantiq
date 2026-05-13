package com.mantiq.model;

import jakarta.persistence.*;

// Eine Antwortoption einer Aufgabe
// Wird genutzt fuer: SINGLE_CHOICE, MULTIPLE_CHOICE, MATCHING, FILL_BLANK, SORTING, TRUE_FALSE
@Entity
@Table(name = "task_options")
public class TaskOption {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;

    // Jede Option gehoert zu einer Aufgabe
    @ManyToOne(optional = false)
    @JoinColumn(name = "task_id", nullable = false)
    private Task task;

    @Column(name = "option_text", nullable = false, columnDefinition = "TEXT")
    private String optionText;

    // Ob diese Option korrekt ist
    @Column(name = "is_correct", nullable = false)
    private Boolean isCorrect = false;

    // Korrekte Reihenfolge – nur fuer SORTING
    @Column
    private Integer position;

    // Zugehoerige Gruppe – nur fuer MATCHING (zusammengehoerige Paare haben gleichen Wert)
    @Column(name = "match_group")
    private Integer matchGroup;

    // --- Getter & Setter ---

    public Integer getId() { return id; }
    public void setId(Integer id) { this.id = id; }

    public Task getTask() { return task; }
    public void setTask(Task task) { this.task = task; }

    public String getOptionText() { return optionText; }
    public void setOptionText(String optionText) { this.optionText = optionText; }

    public Boolean getIsCorrect() { return isCorrect; }
    public void setIsCorrect(Boolean isCorrect) { this.isCorrect = isCorrect; }

    public Integer getPosition() { return position; }
    public void setPosition(Integer position) { this.position = position; }

    public Integer getMatchGroup() { return matchGroup; }
    public void setMatchGroup(Integer matchGroup) { this.matchGroup = matchGroup; }
}
