package com.mantiq.model;

import jakarta.persistence.*;
import java.time.LocalDateTime;

// "Group" ist ein SQL-Keyword, deshalb MantiqGroup
@Entity
@Table(name = "mantiq_groups")
public class MantiqGroup {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;

    @Column(nullable = false)
    private String name;

    // UNIVERSITY | MODULE
    @Column(name = "group_type", nullable = false)
    private String groupType;

    @Column(columnDefinition = "TEXT")
    private String description;

    // Kurzer Code zum Beitreten (z.B. "ABC123")
    @Column(name = "invite_code", unique = true)
    private String inviteCode;

    @ManyToOne(optional = false)
    @JoinColumn(name = "created_by", nullable = false)
    private User createdBy;

    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt = LocalDateTime.now();

    public Integer getId() { return id; }
    public void setId(Integer id) { this.id = id; }

    public String getName() { return name; }
    public void setName(String name) { this.name = name; }

    public String getGroupType() { return groupType; }
    public void setGroupType(String groupType) { this.groupType = groupType; }

    public String getDescription() { return description; }
    public void setDescription(String description) { this.description = description; }

    public String getInviteCode() { return inviteCode; }
    public void setInviteCode(String inviteCode) { this.inviteCode = inviteCode; }

    public User getCreatedBy() { return createdBy; }
    public void setCreatedBy(User createdBy) { this.createdBy = createdBy; }

    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }
}
