package com.mantiq.model;

import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "tree_shares")
public class TreeShare {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;

    @ManyToOne(optional = false)
    @JoinColumn(name = "tree_id", nullable = false)
    private Tree tree;

    @Column(nullable = false, unique = true, length = 10)
    private String code;

    @Column(name = "created_by_user_id")
    private Integer createdByUserId;

    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt = LocalDateTime.now();

    public Integer getId() { return id; }
    public Tree getTree() { return tree; }
    public void setTree(Tree tree) { this.tree = tree; }
    public String getCode() { return code; }
    public void setCode(String code) { this.code = code; }
    public Integer getCreatedByUserId() { return createdByUserId; }
    public void setCreatedByUserId(Integer v) { this.createdByUserId = v; }
    public LocalDateTime getCreatedAt() { return createdAt; }
}
