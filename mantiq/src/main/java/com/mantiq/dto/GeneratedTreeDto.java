package com.mantiq.dto;

import com.fasterxml.jackson.annotation.JsonAlias;
import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.annotation.JsonProperty;
import java.math.BigDecimal;
import java.util.List;

// Datenstruktur fuer die Antwort von Claude
// Claude gibt JSON zurueck, das wir in diese Klassen mappen
public class GeneratedTreeDto {

    // Von Claude generierter Titel (falls kein Titel vorgegeben)
    @JsonProperty("tree_title")
    public String treeTitle;

    public List<StepDto> steps;

    public static class StepDto {
        public String title;
        public List<TaskDto> tasks;
    }

    public static class TaskDto {
        public String question;
        public String type; // z.B. "SINGLE_CHOICE", "SORTING", ...
        public List<OptionDto> options;

        // Nur fuer NUMBER_LINE
        @JsonProperty("number_min")
        public BigDecimal numberMin;

        @JsonProperty("number_max")
        public BigDecimal numberMax;

        @JsonProperty("number_correct")
        public BigDecimal numberCorrect;
    }

    @JsonIgnoreProperties(ignoreUnknown = true)
    public static class OptionDto {
        public String text;
        // @JsonAlias akzeptiert beide Varianten: "correct" und "is_correct"
        @JsonAlias("is_correct")
        public boolean correct;
        public Integer position;      // fuer SORTING: korrekte Reihenfolge
        @JsonProperty("match_group")
        public Integer matchGroup;    // fuer MATCHING: zusammengehoerige Paare
    }
}
