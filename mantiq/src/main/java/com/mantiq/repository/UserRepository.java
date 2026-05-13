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

    // Liga-Mitglieder mit oberem Limit
    @Query("SELECT u FROM User u WHERE u.xp >= :minXp AND u.xp < :maxXp ORDER BY u.xp DESC")
    List<User> findLeagueMembers(@Param("minXp") int minXp, @Param("maxXp") int maxXp,
                                 org.springframework.data.domain.Pageable pageable);

    // Liga-Mitglieder ohne oberes Limit (Diamant)
    @Query("SELECT u FROM User u WHERE u.xp >= :minXp ORDER BY u.xp DESC")
    List<User> findTopLeagueMembers(@Param("minXp") int minXp,
                                    org.springframework.data.domain.Pageable pageable);

    // Freunde: beide Richtungen der Freundschaft als zwei getrennte Queries
    @Query("SELECT f.friend FROM Friendship f WHERE f.user.id = :userId AND f.status = 'ACCEPTED'")
    List<User> findFriendsAsSender(@Param("userId") Integer userId);

    @Query("SELECT f.user FROM Friendship f WHERE f.friend.id = :userId AND f.status = 'ACCEPTED'")
    List<User> findFriendsAsReceiver(@Param("userId") Integer userId);

    // Globaler Rang: Anzahl Nutzer mit mehr XP
    long countByXpGreaterThan(int xp);

    // Nachbar direkt ueber dem Nutzer (naechst hoeheres XP)
    @Query("SELECT u FROM User u WHERE u.xp > :xp AND u.id != :userId ORDER BY u.xp ASC")
    List<User> findUserAbove(@Param("xp") int xp, @Param("userId") Integer userId,
                             org.springframework.data.domain.Pageable pageable);

    // Nachbar direkt unter dem Nutzer (naechst niedrigeres XP)
    @Query("SELECT u FROM User u WHERE u.xp < :xp AND u.id != :userId ORDER BY u.xp DESC")
    List<User> findUserBelow(@Param("xp") int xp, @Param("userId") Integer userId,
                             org.springframework.data.domain.Pageable pageable);
}
