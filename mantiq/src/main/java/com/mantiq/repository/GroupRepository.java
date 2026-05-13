package com.mantiq.repository;

import com.mantiq.model.MantiqGroup;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;

public interface GroupRepository extends JpaRepository<MantiqGroup, Integer> {

    // Alle Gruppen eines Nutzers (als Mitglied)
    @Query("SELECT gm.group FROM GroupMember gm WHERE gm.user.id = :userId")
    List<MantiqGroup> findByMemberId(@Param("userId") Integer userId);

    Optional<MantiqGroup> findByInviteCode(String inviteCode);

    // Suche nach Name (case-insensitive)
    @Query("SELECT g FROM MantiqGroup g WHERE LOWER(g.name) LIKE LOWER(CONCAT('%', :q, '%'))")
    List<MantiqGroup> searchByName(@Param("q") String q);
}
