package com.mantiq.service;

import org.apache.pdfbox.Loader;
import org.apache.pdfbox.pdmodel.PDDocument;
import org.apache.pdfbox.text.PDFTextStripper;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;

// Extrahiert den Rohtext aus einer hochgeladenen PDF-Datei
@Service
public class PdfService {

    // Maximale Zeichenanzahl die wir an Claude schicken (spart Kosten)
    private static final int MAX_ZEICHEN = 15_000;

    public String textAusPdfExtrahieren(MultipartFile datei) throws IOException {
        // PDFBox 3.x: Loader.loadPDF() statt PDDocument.load()
        try (PDDocument dokument = Loader.loadPDF(datei.getBytes())) {
            PDFTextStripper stripper = new PDFTextStripper();
            String volltext = stripper.getText(dokument);

            // Zu langen Text kuerzen, damit die API nicht zu teuer wird
            if (volltext.length() > MAX_ZEICHEN) {
                volltext = volltext.substring(0, MAX_ZEICHEN);
            }

            return volltext.trim();
        }
    }
}
