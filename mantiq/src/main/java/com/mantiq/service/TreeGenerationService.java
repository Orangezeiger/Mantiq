package com.mantiq.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.mantiq.dto.GeneratedTreeDto;
import com.mantiq.model.*;
import com.mantiq.repository.TaskTypeRepository;
import com.mantiq.repository.TreeRepository;
import com.mantiq.repository.UserRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.util.ArrayList;

// Orchestriert den gesamten PDF -> Aufgaben -> Datenbank Prozess
@Service
public class TreeGenerationService {

    private final PdfService pdfService;
    private final AnthropicService anthropicService;
    private final UserRepository userRepository;
    private final TreeRepository treeRepository;
    private final TaskTypeRepository taskTypeRepository;
    private final ObjectMapper mapper = new ObjectMapper();

    public TreeGenerationService(PdfService pdfService,
                                 AnthropicService anthropicService,
                                 UserRepository userRepository,
                                 TreeRepository treeRepository,
                                 TaskTypeRepository taskTypeRepository) {
        this.pdfService        = pdfService;
        this.anthropicService  = anthropicService;
        this.userRepository    = userRepository;
        this.treeRepository    = treeRepository;
        this.taskTypeRepository = taskTypeRepository;
    }

    // Hauptmethode: PDF hochladen -> KI -> in DB speichern -> Tree zurueckgeben
    @Transactional
    public Tree baumAusPdfErstellen(MultipartFile pdf, Integer userId, String titel) throws Exception {

        // 1. Nutzer laden
        User nutzer = userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("Nutzer nicht gefunden: " + userId));

        // 2. Text aus PDF extrahieren
        String pdfText = pdfService.textAusPdfExtrahieren(pdf);

        // 3. Aufgaben von Claude generieren lassen (Titel optional)
        String jsonAntwort = anthropicService.aufgabenGenerieren(pdfText, titel);

        // 4. JSON in Java-Objekte umwandeln
        GeneratedTreeDto generiert = mapper.readValue(jsonAntwort, GeneratedTreeDto.class);

        // 5. Baum in der Datenbank anlegen
        // Titel: vorgegeben > von Claude generiert > Fallback
        String finalerTitel = (titel != null && !titel.isBlank()) ? titel
                : (generiert.treeTitle != null && !generiert.treeTitle.isBlank()) ? generiert.treeTitle
                : "Lernbaum";

        Tree baum = new Tree();
        baum.setUser(nutzer);
        baum.setTitle(finalerTitel);
        baum.setSteps(new ArrayList<>());

        int schrittPosition = 0;
        for (GeneratedTreeDto.StepDto schrittDto : generiert.steps) {

            Step schritt = new Step();
            schritt.setTree(baum);
            schritt.setTitle(schrittDto.title);
            schritt.setPosition(schrittPosition++);
            schritt.setTasks(new ArrayList<>());

            int aufgabePosition = 0;
            for (GeneratedTreeDto.TaskDto aufgabeDto : schrittDto.tasks) {

                // Aufgabentyp aus DB laden
                TaskType typ = taskTypeRepository.findByName(aufgabeDto.type)
                        .orElseThrow(() -> new IllegalArgumentException("Unbekannter Aufgabentyp: " + aufgabeDto.type));

                Task aufgabe = new Task();
                aufgabe.setStep(schritt);
                aufgabe.setTaskType(typ);
                aufgabe.setQuestion(aufgabeDto.question);
                aufgabe.setPosition(aufgabePosition++);
                aufgabe.setNumberMin(aufgabeDto.numberMin);
                aufgabe.setNumberMax(aufgabeDto.numberMax);
                aufgabe.setNumberCorrect(aufgabeDto.numberCorrect);
                aufgabe.setOptions(new ArrayList<>());

                // Antwortoptionen hinzufuegen (falls vorhanden)
                if (aufgabeDto.options != null) {
                    for (GeneratedTreeDto.OptionDto optionDto : aufgabeDto.options) {
                        TaskOption option = new TaskOption();
                        option.setTask(aufgabe);
                        option.setOptionText(optionDto.text);
                        option.setIsCorrect(optionDto.correct);
                        option.setPosition(optionDto.position);
                        option.setMatchGroup(optionDto.matchGroup);
                        aufgabe.getOptions().add(option);
                    }
                }

                schritt.getTasks().add(aufgabe);
            }

            baum.getSteps().add(schritt);
        }

        // 6. Alles speichern (Cascade speichert Steps, Tasks und Options automatisch)
        return treeRepository.save(baum);
    }
}
