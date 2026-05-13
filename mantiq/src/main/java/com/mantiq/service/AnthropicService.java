package com.mantiq.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestClient;

// Kommunikation mit der Anthropic API (Claude)
@Service
public class AnthropicService {

    private static final String API_URL = "https://api.anthropic.com/v1/messages";
    private static final String MODELL  = "claude-haiku-4-5-20251001";

    @Value("${anthropic.api.key}")
    private String apiKey;

    private final RestClient restClient = RestClient.create();
    private final ObjectMapper mapper = new ObjectMapper();

    // Sendet den PDF-Text an Claude und gibt den generierten JSON-String zurueck
    public String aufgabenGenerieren(String pdfText) {
        return aufgabenGenerieren(pdfText, null);
    }

    public String aufgabenGenerieren(String pdfText, String titelVorgabe) {
        String prompt = aufgabenPromptErstellen(pdfText, titelVorgabe);

        // Anthropic API Request aufbauen
        String requestBody = """
            {
              "model": "%s",
              "max_tokens": 16000,
              "messages": [
                {
                  "role": "user",
                  "content": %s
                }
              ]
            }
            """.formatted(MODELL, mapper.valueToTree(prompt).toString());

        // API aufrufen
        String antwort = restClient.post()
                .uri(API_URL)
                .header("x-api-key", apiKey)
                .header("anthropic-version", "2023-06-01")
                .contentType(MediaType.APPLICATION_JSON)
                .body(requestBody)
                .retrieve()
                .body(String.class);

        // JSON aus der Antwort extrahieren
        return jsonAusAntwortExtrahieren(antwort);
    }

    // Baut den Prompt fuer Claude
    private String aufgabenPromptErstellen(String pdfText, String titelVorgabe) {
        String titelAnweisung = (titelVorgabe == null || titelVorgabe.isBlank())
            ? "Generiere auch einen passenden Titel fuer den gesamten Lernbaum (Feld \"tree_title\")."
            : "Der Titel des Lernbaums ist: \"" + titelVorgabe + "\"";

        return """
            Du bist ein Lernassistent. Analysiere den folgenden Text aus Vorlesungsfolien \
            und erstelle daraus einen Lernbaum fuer eine Lern-App (aehnlich wie Duolingo).

            WICHTIG: Antworte NUR mit gueltigem JSON, kein Text davor oder danach.

            %s

            Erstelle 4-7 Schritte (steps), jeder Schritt hat 5-8 Aufgaben (tasks).
            Verteile die Aufgabentypen abwechslungsreich ueber alle Schritte.
            Waehle den Typ passend zum Inhalt (z.B. Definitionen → SINGLE_CHOICE,
            Prozessschritte → SORTING, Zuordnungen → MATCHING, Zahlenwerte → NUMBER_LINE).

            Verfuegbare Typen:
            - SINGLE_CHOICE: eine richtige Antwort, 3-4 Optionen
            - MULTIPLE_CHOICE: mehrere richtige Antworten, 4 Optionen
            - MATCHING: Begriffe zuordnen, immer 4 Optionen in 2 Paaren (match_group 1 und 2)
            - SORTING: Schritte sortieren, position = korrekte Reihenfolge (0-basiert)
            - FILL_BLANK: Lueckentext, is_correct=true markiert die richtige Antwort
            - TRUE_FALSE: Aussage bewerten, 2 Optionen ("Wahr" und "Falsch")
            - NUMBER_LINE: Wert auf Skala, statt options: number_min, number_max, number_correct

            JSON-Format:
            {
              "tree_title": "Generierter oder vorgegebener Titel",
              "steps": [
                {
                  "title": "Titel des Schritts",
                  "tasks": [
                    {
                      "question": "Frage?",
                      "type": "SINGLE_CHOICE",
                      "options": [
                        {"text": "Richtige Antwort", "correct": true},
                        {"text": "Falsche Antwort", "correct": false}
                      ]
                    },
                    {
                      "question": "Ordne die Werte:",
                      "type": "NUMBER_LINE",
                      "number_min": 0,
                      "number_max": 100,
                      "number_correct": 42
                    }
                  ]
                }
              ]
            }

            Hier ist der Text aus den Vorlesungsfolien:

            %s
            """.formatted(titelAnweisung, pdfText);
    }

    // Liest den Textinhalt aus der Claude-Antwort und extrahiert das JSON
    private String jsonAusAntwortExtrahieren(String apiAntwort) {
        try {
            JsonNode root = mapper.readTree(apiAntwort);
            String text = root.path("content").get(0).path("text").asText();

            // JSON-Block aus dem Text herausschneiden (zwischen { und })
            int start = text.indexOf('{');
            int end   = text.lastIndexOf('}');
            if (start != -1 && end != -1) {
                return text.substring(start, end + 1);
            }
            return text;
        } catch (Exception e) {
            throw new RuntimeException("Fehler beim Parsen der Claude-Antwort: " + e.getMessage());
        }
    }
}
