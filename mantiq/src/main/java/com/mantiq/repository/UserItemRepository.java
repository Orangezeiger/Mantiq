package com.mantiq.repository;

import com.mantiq.model.UserItem;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface UserItemRepository extends JpaRepository<UserItem, Integer> {

    List<UserItem> findByUserId(Integer userId);

    Optional<UserItem> findByUserIdAndItemId(Integer userId, Integer itemId);
}
