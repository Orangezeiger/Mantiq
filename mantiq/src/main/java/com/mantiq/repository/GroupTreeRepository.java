package com.mantiq.repository;

import com.mantiq.model.GroupTree;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface GroupTreeRepository extends JpaRepository<GroupTree, Integer> {

    List<GroupTree> findByGroupId(Integer groupId);

    boolean existsByGroupIdAndTreeId(Integer groupId, Integer treeId);
}
