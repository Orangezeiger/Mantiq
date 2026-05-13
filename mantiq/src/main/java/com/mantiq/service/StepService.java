package com.mantiq.service;

import com.mantiq.dto.response.OptionResponse;
import com.mantiq.dto.response.TaskResponse;
import com.mantiq.model.Step;
import com.mantiq.model.Task;
import com.mantiq.repository.StepRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
public class StepService {

    private final StepRepository stepRepository;

    public StepService(StepRepository stepRepository) {
        this.stepRepository = stepRepository;
    }

    // Aufgaben eines Schritts laden – innerhalb einer Transaktion damit Lazy-Loading klappt
    @Transactional(readOnly = true)
    public List<TaskResponse> getStepTasks(Integer stepId) {
        Step schritt = stepRepository.findById(stepId).orElse(null);
        if (schritt == null) return null;

        return schritt.getTasks().stream()
                .map(this::aufgabeZuResponse)
                .toList();
    }

    // Task-Entity in Response-DTO umwandeln
    private TaskResponse aufgabeZuResponse(Task aufgabe) {
        List<OptionResponse> optionen = null;
        if (aufgabe.getOptions() != null) {
            optionen = aufgabe.getOptions().stream()
                    .map(o -> new OptionResponse(
                            o.getId(),
                            o.getOptionText(),
                            o.getIsCorrect(),
                            o.getPosition(),
                            o.getMatchGroup()
                    ))
                    .toList();
        }
        return new TaskResponse(
                aufgabe.getId(),
                aufgabe.getQuestion(),
                aufgabe.getTaskType().getName(),
                optionen,
                aufgabe.getNumberMin(),
                aufgabe.getNumberMax(),
                aufgabe.getNumberCorrect()
        );
    }
}
