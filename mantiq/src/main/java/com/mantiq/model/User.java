package com.mantiq.model;

import jakarta.persistence.*;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

@Entity
@Table(name = "users")
public class User {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;

    @Column(nullable = false, unique = true)
    private String email;

    @Column(name = "password_hash", nullable = false)
    private String passwordHash;

    @Column(name = "display_name")
    private String displayName;

    @Column(name = "first_name", length = 100)
    private String firstName;

    @Column(name = "last_name", length = 100)
    private String lastName;

    @Column(nullable = false)
    private Integer xp = 0;

    @Column(nullable = false)
    private Integer coins = 0;

    @Column(name = "streak_days", nullable = false)
    private Integer streakDays = 0;

    // Gespeicherte Streak vor dem letzten Verlust – wird durch Schild wiederhergestellt
    @Column(name = "streak_before_reset", nullable = false)
    private Integer streakBeforeReset = 0;

    @Column(name = "last_active_date")
    private LocalDate lastActiveDate;

    @Column(name = "subscription_plan", nullable = false)
    private String subscriptionPlan = "FREE";

    @Column(name = "subscription_until")
    private LocalDateTime subscriptionUntil;

    @Column(name = "display_name_changed_at")
    private LocalDateTime displayNameChangedAt;

    @Column(name = "last_reward_claimed_at")
    private LocalDateTime lastRewardClaimedAt;

    @Column(nullable = false)
    private Boolean active = true;

    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt = LocalDateTime.now();

    @OneToMany(mappedBy = "user", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<Tree> trees;

    // --- Getter & Setter ---

    public Integer getId() { return id; }
    public void setId(Integer id) { this.id = id; }

    public String getEmail() { return email; }
    public void setEmail(String email) { this.email = email; }

    public String getPasswordHash() { return passwordHash; }
    public void setPasswordHash(String passwordHash) { this.passwordHash = passwordHash; }

    public String getDisplayName() { return displayName; }
    public void setDisplayName(String displayName) { this.displayName = displayName; }

    public String getFirstName() { return firstName; }
    public void setFirstName(String firstName) { this.firstName = firstName; }

    public String getLastName() { return lastName; }
    public void setLastName(String lastName) { this.lastName = lastName; }

    public Integer getXp() { return xp; }
    public void setXp(Integer xp) { this.xp = xp; }

    public Integer getCoins() { return coins; }
    public void setCoins(Integer coins) { this.coins = coins; }

    public Integer getStreakDays() { return streakDays; }
    public void setStreakDays(Integer streakDays) { this.streakDays = streakDays; }

    public Integer getStreakBeforeReset() { return streakBeforeReset; }
    public void setStreakBeforeReset(Integer streakBeforeReset) { this.streakBeforeReset = streakBeforeReset; }

    public LocalDate getLastActiveDate() { return lastActiveDate; }
    public void setLastActiveDate(LocalDate lastActiveDate) { this.lastActiveDate = lastActiveDate; }

    public String getSubscriptionPlan() { return subscriptionPlan; }
    public void setSubscriptionPlan(String subscriptionPlan) { this.subscriptionPlan = subscriptionPlan; }

    public LocalDateTime getSubscriptionUntil() { return subscriptionUntil; }
    public void setSubscriptionUntil(LocalDateTime subscriptionUntil) { this.subscriptionUntil = subscriptionUntil; }

    public LocalDateTime getDisplayNameChangedAt() { return displayNameChangedAt; }
    public void setDisplayNameChangedAt(LocalDateTime v) { this.displayNameChangedAt = v; }

    public LocalDateTime getLastRewardClaimedAt() { return lastRewardClaimedAt; }
    public void setLastRewardClaimedAt(LocalDateTime v) { this.lastRewardClaimedAt = v; }

    public Boolean getActive() { return active; }
    public void setActive(Boolean active) { this.active = active; }

    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }

    public List<Tree> getTrees() { return trees; }
    public void setTrees(List<Tree> trees) { this.trees = trees; }
}
