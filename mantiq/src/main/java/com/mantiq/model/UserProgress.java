package com.mantiq.model;

import jakarta.persistence.*;
import java.time.LocalDateTime;

// Speichert welche Schritte ein Nutzer abgeschlossen hat
@Entity
@Table(name = "user_progress",
       uniqueConstraints = @UniqueConstraint(columnNames = {"user_id", "step_id"}))
public class UserProgress {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;

    @ManyToOne(optional = false)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @ManyToOne(optional = false)
    @JoinColumn(name = "step_id", nullable = false)
    private Step step;

    @Column(name = "completed_at", nullable = false, updatable = false)
    private LocalDateTime completedAt = LocalDateTime.now();

    // --- Getter & Setter ---

    public Integer getId() { return id; }
    public void setId(Integer id) { this.id = id; }

    public User getUser() { return user; }
    public void setUser(User user) { this.user = user; }

    public Step getStep() { return step; }
    public void setStep(Step step) { this.step = step; }

    public LocalDateTime getCompletedAt() { return completedAt; }
    public void setCompletedAt(LocalDateTime completedAt) { this.completedAt = completedAt; }
}
