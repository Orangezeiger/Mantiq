package com.mantiq.model;

import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "group_trees")
public class GroupTree {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;

    @ManyToOne(optional = false)
    @JoinColumn(name = "group_id", nullable = false)
    private MantiqGroup group;

    @ManyToOne(optional = false)
    @JoinColumn(name = "tree_id", nullable = false)
    private Tree tree;

    @ManyToOne(optional = false)
    @JoinColumn(name = "shared_by", nullable = false)
    private User sharedBy;

    @Column(name = "shared_at", nullable = false, updatable = false)
    private LocalDateTime sharedAt = LocalDateTime.now();

    public Integer getId() { return id; }
    public void setId(Integer id) { this.id = id; }

    public MantiqGroup getGroup() { return group; }
    public void setGroup(MantiqGroup group) { this.group = group; }

    public Tree getTree() { return tree; }
    public void setTree(Tree tree) { this.tree = tree; }

    public User getSharedBy() { return sharedBy; }
    public void setSharedBy(User sharedBy) { this.sharedBy = sharedBy; }

    public LocalDateTime getSharedAt() { return sharedAt; }
    public void setSharedAt(LocalDateTime sharedAt) { this.sharedAt = sharedAt; }
}
