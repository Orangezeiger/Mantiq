package com.mantiq.repository;

import com.mantiq.dto.response.TreeSummaryResponse;
import com.mantiq.model.Tree;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;
import java.util.Optional;

public interface TreeRepository extends JpaRepository<Tree, Integer> {

    // Baeume mit Schrittzahl direkt aus der DB – kein Lazy-Loading noetig
    @Query("SELECT new com.mantiq.dto.response.TreeSummaryResponse(" +
           "t.id, t.title, t.description, SIZE(t.steps)) " +
           "FROM Tree t WHERE t.user.id = :userId")
    List<TreeSummaryResponse> findSummariesByUserId(@Param("userId") Integer userId);

    // Baum mit Steps und Tasks auf einmal laden (fuer Detail-Ansicht)
    @EntityGraph(attributePaths = {"steps", "steps.tasks", "steps.tasks.options", "steps.tasks.taskType"})
    @Query("SELECT t FROM Tree t WHERE t.id = :id")
    Optional<Tree> findByIdWithSteps(@Param("id") Integer id);

    // Prueft ob ein Baum mit diesem Titel fuer den Nutzer existiert (fuer Demo-Baum)
    @Query("SELECT CASE WHEN COUNT(t) > 0 THEN TRUE ELSE FALSE END FROM Tree t WHERE t.user.id = :userId AND t.title = :title")
    boolean existsByUserIdAndTitle(@Param("userId") Integer userId, @Param("title") String title);
}
