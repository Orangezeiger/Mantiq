package com.mantiq.repository;

import com.mantiq.model.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;

public interface UserRepository extends JpaRepository<User, Integer> {

    Optional<User> findByEmail(String email);

    // Nutzer per Anzeigename oder E-Mail suchen (fuer Freunde hinzufuegen)
    @Query("SELECT u FROM User u WHERE u.id != :excludeId AND (" +
           "LOWER(u.displayName) LIKE LOWER(CONCAT('%', :q, '%')) OR " +
           "LOWER(u.email)       LIKE LOWER(CONCAT('%', :q, '%')))")
    List<User> searchByNameOrEmail(@Param("q") String q, @Param("excludeId") Integer excludeId,
                                   org.springframework.data.domain.Pageable pageable);

    // Top-Nutzer nach XP fuer globales Leaderboard
    @Query("SELECT u FROM User u ORDER BY u.xp DESC")
    List<User> findTopByXp(org.springframework.data.domain.Pageable pageable);

    // Freunde eines Nutzers nach XP sortiert (beide Richtungen der Freundschaft)
    @Query("SELECT CASE WHEN f.user.id = :userId THEN f.friend ELSE f.user END " +
           "FROM Friendship f WHERE (f.user.id = :userId OR f.friend.id = :userId) " +
           "AND f.status = 'ACCEPTED' ORDER BY " +
           "CASE WHEN f.user.id = :userId THEN f.friend.xp ELSE f.user.xp END DESC")
    List<User> findFriendsByXp(@Param("userId") Integer userId);
}
