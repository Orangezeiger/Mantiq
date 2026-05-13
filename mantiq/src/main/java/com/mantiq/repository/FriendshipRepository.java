package com.mantiq.repository;

import com.mantiq.model.Friendship;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;

public interface FriendshipRepository extends JpaRepository<Friendship, Integer> {

    // Alle akzeptierten Freundschaften (in beide Richtungen)
    @Query("SELECT f FROM Friendship f WHERE " +
           "(f.user.id = :userId OR f.friend.id = :userId) AND f.status = 'ACCEPTED'")
    List<Friendship> findAcceptedByUserId(@Param("userId") Integer userId);

    // Offene eingehende Anfragen
    @Query("SELECT f FROM Friendship f WHERE f.friend.id = :userId AND f.status = 'PENDING'")
    List<Friendship> findPendingRequestsForUser(@Param("userId") Integer userId);

    // Pruefen ob bereits eine Verbindung existiert (in beide Richtungen)
    @Query("SELECT f FROM Friendship f WHERE " +
           "(f.user.id = :a AND f.friend.id = :b) OR (f.user.id = :b AND f.friend.id = :a)")
    Optional<Friendship> findBetween(@Param("a") Integer a, @Param("b") Integer b);
}
