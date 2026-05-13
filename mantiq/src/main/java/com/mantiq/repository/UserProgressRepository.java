package com.mantiq.repository;

import com.mantiq.model.UserProgress;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

public interface UserProgressRepository extends JpaRepository<UserProgress, Integer> {

    List<UserProgress> findByUserIdAndStepTreeId(Integer userId, Integer treeId);

    boolean existsByUserIdAndStepId(Integer userId, Integer stepId);

    // Alle Fortschrittseintraege eines Nutzers loeschen (Fortschritt zuruecksetzen)
    @Modifying
    @Transactional
    @Query("DELETE FROM UserProgress p WHERE p.user.id = :userId")
    void deleteByUserId(@Param("userId") Integer userId);
}
