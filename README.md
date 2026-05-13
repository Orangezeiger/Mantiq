# Mantiq

Lern-App im Duolingo-Stil für MINT-Studenten. Erstelle Lernbäume aus eigenen Notizen oder PDFs – Claude generiert automatisch Aufgaben daraus.

---

## Features

- **Lernbäume** — Strukturiere Themen in Schritte, lerne im Duolingo-Pfad-Format
- **KI-Aufgaben** — Lade ein PDF hoch, Claude erstellt daraus Fragen (Multiple Choice, Lückentext, Sortieren u. a.)
- **Streak & XP** — Tägliche Lernziele, Erfahrungspunkte, Münzen
- **Shop** — Items kaufen (Streak-Schild, Doppel-XP, XP-Schub)
- **Freunde** — Profile, Rangliste, Anfragen per Nutzername
- **Gruppen** — Universitäten und Module als Gruppen, geteilte Lernbäume
- **Abo** — Free & Pro Tier (Zahlungsintegration folgt)

---

## Tech Stack

| Schicht | Technologie |
|---|---|
| Backend | Spring Boot 3.5 · Java 17 · PostgreSQL |
| Frontend | Flutter (iOS · Android) |
| KI | Anthropic Claude (Haiku) |
| Hosting | Proxmox LXC · Self-hosted |
| CI/CD | GitHub Actions · Self-hosted Runner |

---

## Lokale Entwicklung

**Backend**
```bash
cd mantiq
./mvnw spring-boot:run
```

**Flutter**
```bash
cd mantiq_app
flutter run
```

`application.properties` wird nicht eingecheckt – eigene Datei mit DB-Credentials und API-Key anlegen.

---

## Deployment

Push auf `main` → GitHub Actions baut das JAR → Self-hosted Runner im LXC startet den Service neu.
