# Mantiq – Projektbeschreibung für Claude Code

## Konzept
Mantiq ist eine Lern-App für MINT-Studenten. Sie funktioniert wie Duolingo aber für Uni-Stoff. Ziel ist es, eine Alternative zum sinnlosen Scrollen auf TikTok zu bieten – der Nutzer soll das Gefühl haben, etwas für die Uni zu tun. Kein übertriebenes Gamification, sondern echter Lerndruck als Motivation.

---

## Name & Bedeutung
**Mantiq** – bedeutet "Logik" und "Vernunft" auf Arabisch. Klingt außerdem nach "Mantis" (Tier mit Superpower-Augen). Einprägsam, international, modern.

---

## Zielgruppe
MINT-Studenten (Mathematik, Informatik, Naturwissenschaften, Technik)

---

## Kernfeatures

### 1. Fortschrittsbäume
- Nutzer kann mehrere Fortschrittsbäume erstellen (z.B. ein Baum pro Fach oder Thema)
- Zwei Erstellungsmodi:
  - **Manuell** – Nutzer erstellt Schritte selbst
  - **Per PDF/Vorlesungsfolien** – KI analysiert die Folien und generiert automatisch Struktur und Aufgaben
- Jeder Baum und jeder einzelne Schritt ist nachträglich bearbeitbar

### 2. Aufgabentypen
Die KI wählt beim Generieren automatisch den passenden Aufgabentyp:
- **Einzelauswahl** – eine richtige Antwort aus mehreren Optionen
- **Mehrfachauswahl** – mehrere richtige Antworten möglich
- **Verbinden** – Begriffe oder Konzepte einander zuordnen
- **Zahlenstrahl** – Ergebnis auf einer Skala auswählen
- **Lückentext** – fehlende Operatoren oder Aussagen einsetzen
- **Sortieren** – Schritte/Begriffe in richtige Reihenfolge bringen
- **Wahr/Falsch** – schnelle Aussagen bewerten

### 3. UI/UX Prinzipien
- Minimalistisch – wenige Knöpfe, wenige Farben
- Icon-basiert – Icons statt Text, müssen selbsterklärend sein
- Eine Aufgabe pro Screen
- Duolingo-ähnliche visuelle Pfad-Darstellung innerhalb eines Baums

---

## Tech Stack

| Komponente | Technologie |
|------------|-------------|
| Backend | Java (Spring Boot) |
| Datenbank | SQL (PostgreSQL oder MySQL) |
| Frontend | HTML, CSS, JavaScript |
| KI | Anthropic API (claude-sonnet-4-20250514) |
| Hosting | Homelab des Entwicklers |

---

## KI-Pipeline (PDF → Aufgaben)
1. Nutzer lädt PDF/Vorlesungsfolien hoch
2. Backend sendet Inhalt an Anthropic API
3. KI extrahiert Konzepte und Themen
4. KI generiert passende Aufgaben mit dem jeweils sinnvollsten Aufgabentyp
5. Aufgaben werden in Schritte eines Fortschrittsbaums strukturiert
6. Nutzer kann alles nachträglich bearbeiten

---

## Kosten (Anthropic API)
- Modell: claude-sonnet-4-20250514
- Kosten pro PDF-Upload + Aufgabengenerierung: ca. $0.01–0.05
- Für Tests völlig vernachlässigbar
- API Key unter https://console.anthropic.com erstellen

---

## Startpunkt für die Entwicklung
1. Datenbankstruktur planen (User, Trees, Steps, Tasks, TaskTypes)
2. Spring Boot Projekt aufsetzen
3. PDF-Upload Endpoint bauen
4. Anthropic API Integration für Aufgabengenerierung
5. Frontend mit Baumansicht

---

## Hinweise für Claude Code
- Der Entwickler kann gut Java, SQL, HTML, CSS und etwas JavaScript und Python
- Einfacher, klarer Code bevorzugt
- Kommentare auf Deutsch sind willkommen
- Hosting läuft auf einem Homelab (kein Cloud-Provider)
- Keine GPU verfügbar, deshalb externe API statt lokalem Modell
