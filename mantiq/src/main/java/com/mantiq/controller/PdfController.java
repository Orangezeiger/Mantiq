package com.mantiq.controller;

import com.mantiq.model.Tree;
import com.mantiq.service.TreeGenerationService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.util.Map;

// REST-Endpoint fuer den PDF-Upload
// POST /api/pdf/upload
@RestController
@RequestMapping("/api/pdf")
public class PdfController {

    private final TreeGenerationService treeGenerationService;

    public PdfController(TreeGenerationService treeGenerationService) {
        this.treeGenerationService = treeGenerationService;
    }

    /**
     * PDF hochladen und Lernbaum generieren lassen.
     *
     * Beispiel-Aufruf mit curl:
     *   curl -X POST http://localhost:8080/api/pdf/upload \
     *        -F "datei=@vorlesung.pdf" \
     *        -F "userId=1" \
     *        -F "titel=Mathe Grundlagen"
     */
    @PostMapping("/upload")
    public ResponseEntity<?> pdfHochladen(
            @RequestParam("datei")  MultipartFile datei,
            @RequestParam("userId") Integer userId,
            @RequestParam(value = "titel", required = false, defaultValue = "") String titel) {

        // Pruefen ob eine PDF-Datei hochgeladen wurde
        if (datei.isEmpty()) {
            return ResponseEntity.badRequest().body(Map.of("fehler", "Keine Datei hochgeladen"));
        }

        try {
            Tree baum = treeGenerationService.baumAusPdfErstellen(datei, userId, titel);

            // Einfache Antwort: ID und Titel des erstellten Baums
            return ResponseEntity.ok(Map.of(
                    "id",      baum.getId(),
                    "titel",   baum.getTitle(),
                    "schritte", baum.getSteps().size()
            ));

        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(Map.of("fehler", e.getMessage()));
        } catch (Exception e) {
            return ResponseEntity.internalServerError()
                    .body(Map.of("fehler", "Fehler beim Verarbeiten: " + e.getMessage()));
        }
    }
}
