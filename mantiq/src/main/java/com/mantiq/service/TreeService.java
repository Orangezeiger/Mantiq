package com.mantiq.service;

import com.mantiq.dto.response.*;
import com.mantiq.model.*;
import com.mantiq.repository.*;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Set;
import java.util.stream.Collectors;

@Service
public class TreeService {

    private final TreeRepository treeRepository;
    private final UserProgressRepository progressRepository;

    public TreeService(TreeRepository treeRepository,
                       UserProgressRepository progressRepository) {
        this.treeRepository    = treeRepository;
        this.progressRepository = progressRepository;
    }

    // Baum-Details laden – innerhalb einer Transaktion damit Lazy-Loading funktioniert
    @Transactional(readOnly = true)
    public TreeDetailResponse getBaumDetails(Integer treeId, Integer userId) {
        Tree baum = treeRepository.findById(treeId).orElse(null);
        if (baum == null) return null;

        // Abgeschlossene Schritte des Nutzers
        Set<Integer> abgeschlossen = progressRepository
                .findByUserIdAndStepTreeId(userId, treeId)
                .stream()
                .map(p -> p.getStep().getId())
                .collect(Collectors.toSet());

        // Steps und Tasks innerhalb der Transaktion laden (kein LazyInit-Problem)
        List<StepResponse> schritte = baum.getSteps().stream()
                .map(s -> new StepResponse(
                        s.getId(),
                        s.getTitle(),
                        s.getPosition(),
                        abgeschlossen.contains(s.getId()),
                        null
                ))
                .toList();

        return new TreeDetailResponse(baum.getId(), baum.getTitle(), baum.getDescription(), schritte);
    }

    // Aufgaben eines Schritts laden
    @Transactional(readOnly = true)
    public List<TaskResponse> getStepTasks(Integer stepId) {
        Tree dummy = treeRepository.findAll().stream()
                .flatMap(t -> t.getSteps().stream())
                .filter(s -> s.getId().equals(stepId))
                .findFirst()
                .map(Step::getTree)
                .orElse(null);

        // Direkt ueber Step laden
        return null; // wird im StepController gemacht
    }
}
