package com.mantiq.controller;

import org.springframework.boot.info.BuildProperties;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.time.ZoneId;
import java.time.format.DateTimeFormatter;
import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/api/version")
public class VersionController {

    private final BuildProperties buildProperties;

    public VersionController(BuildProperties buildProperties) {
        this.buildProperties = buildProperties;
    }

    @GetMapping
    public ResponseEntity<?> version() {
        String buildTime = DateTimeFormatter
                .ofPattern("dd.MM.yyyy HH:mm")
                .withZone(ZoneId.of("Europe/Berlin"))
                .format(buildProperties.getTime());

        Map<String, String> m = new HashMap<>();
        m.put("version",   buildProperties.getVersion());
        m.put("buildTime", buildTime);
        return ResponseEntity.ok(m);
    }
}
