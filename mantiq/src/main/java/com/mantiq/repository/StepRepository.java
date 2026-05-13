package com.mantiq.repository;

import com.mantiq.model.Step;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.Optional;

public interface StepRepository extends JpaRepository<Step, Integer> {

    // Schritt mit Tasks und Optionen auf einmal laden – kein Lazy-Loading noetig
    @EntityGraph(attributePaths = {"tasks", "tasks.options", "tasks.taskType"})
    @Query("SELECT s FROM Step s WHERE s.id = :id")
    Optional<Step> findByIdWithTasks(@Param("id") Integer id);

    // Hoechste Position eines Schritts in einem Baum (fuer naechste Position)
    @Query("SELECT COALESCE(MAX(s.position), -1) FROM Step s WHERE s.tree.id = :treeId")
    Integer findMaxPositionByTreeId(@Param("treeId") Integer treeId);
}
