package com.mantiq.model;

import jakarta.persistence.*;

// Lookup-Tabelle fuer die 7 Aufgabentypen (SINGLE_CHOICE, MULTIPLE_CHOICE, ...)
@Entity
@Table(name = "task_types")
public class TaskType {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;

    @Column(nullable = false, unique = true, length = 50)
    private String name;

    // --- Getter & Setter ---

    public Integer getId() { return id; }
    public void setId(Integer id) { this.id = id; }

    public String getName() { return name; }
    public void setName(String name) { this.name = name; }
}
