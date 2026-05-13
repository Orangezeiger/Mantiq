package com.mantiq.repository;

import com.mantiq.model.TreeShare;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.Optional;

public interface TreeShareRepository extends JpaRepository<TreeShare, Integer> {
    Optional<TreeShare> findByCode(String code);
    Optional<TreeShare> findByTreeId(Integer treeId);
}
