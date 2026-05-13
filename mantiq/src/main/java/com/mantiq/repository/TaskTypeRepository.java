package com.mantiq.repository;

import com.mantiq.model.TaskType;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.Optional;

public interface TaskTypeRepository extends JpaRepository<TaskType, Integer> {

    // Aufgabentyp per Name laden, z.B. "SINGLE_CHOICE"
    Optional<TaskType> findByName(String name);
}
