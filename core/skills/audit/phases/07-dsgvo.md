# Phase 07: DSGVO

Datenschutz-Grundverordnung — Consent, Tracking, externe Ressourcen.
Finding-Prefix: `DSGVO`

---

## Checks

### 1. Externe Ressourcen

- [ ] **Fonts:** Self-hosted? Kein Google Fonts CDN ohne Consent!
- [ ] **CSS/JS:** Keine externen CDNs (cdnjs, unpkg, jsdelivr) ohne Consent?
- [ ] **Bilder:** Keine externen Bildquellen (Unsplash, Cloudinary) ohne Consent?
- [ ] **Maps:** Google Maps / Leaflet Tiles — Click-to-Load oder Consent-basiert?
- [ ] **Videos:** YouTube/Vimeo — Click-to-Load oder Consent-basiert?
- [ ] **Social Embeds:** Keine direkten Einbettungen ohne Consent?
- [ ] Browser DevTools → Network Tab: Welche Domains werden kontaktiert?

### 2. Cookie Banner & Consent

- [ ] Cookie Banner vorhanden wenn Cookies gesetzt werden?
- [ ] Consent BEVOR Cookies/Tracking — nicht erst nach Klick initialisieren?
- [ ] Ablehnen muss genauso einfach sein wie Annehmen
- [ ] Consent-Wahl wird gespeichert (Cookie oder localStorage)?
- [ ] Consent widerrufbar? (Link im Footer / Datenschutz-Seite)
- [ ] Keine vorausgewaehlten Checkboxen (Dark Patterns)

### 3. Analytics & Tracking

- [ ] Welches Analytics-Tool? (Umami, Matomo, Google Analytics, Plausible)
- [ ] Self-hosted? (Umami/Matomo = gut, Google Analytics = Consent-pflichtig)
- [ ] Consent-basiert? Analytics erst NACH Einwilligung laden?
- [ ] IP-Anonymisierung aktiviert?
- [ ] Keine User-Fingerprinting-Techniken?

### 4. Formulare & Datenverarbeitung

- [ ] Datenschutz-Hinweis bei Formularen? (Link zur Datenschutzerklaerung)
- [ ] Nur notwendige Daten erheben (Datensparsamkeit)?
- [ ] Daten verschluesselt uebertragen? (HTTPS)
- [ ] Daten auf eigenem Server gespeichert? (Kein Drittanbieter ohne AV-Vertrag)
- [ ] Loesch-Konzept: Wie lange werden Daten aufbewahrt?
- [ ] Email-Versand: Ueber eigenen Server oder Drittanbieter? AV-Vertrag?

### 5. Rechtliche Seiten

- [ ] **Impressum:** Vorhanden, vollstaendig, von jeder Seite erreichbar?
  - Name, Anschrift, Kontakt, Handelsregister (falls), USt-ID (falls)
- [ ] **Datenschutzerklaerung:** Vorhanden, aktuell, von jeder Seite erreichbar?
  - Verantwortlicher, Kontakt DSB (falls noetig)
  - Welche Daten, Rechtsgrundlage, Zweck, Speicherdauer
  - Rechte der Betroffenen (Auskunft, Loeschung, Widerruf)
  - Cookies, Analytics, Formulare beschrieben
- [ ] **Barrierefreiheitserklaerung:** Ab Juni 2025 (BFSG) noetig

### 6. E-Mail & Kommunikation

- [ ] Newsletter: Double-Opt-In?
- [ ] Kontaktformular: Bestaetigung an Absender?
- [ ] Auto-Reply-Mails: Datenschutz-konform? Keine ueberfluessigen Daten?

### 7. EU AI Act (ab August 2, 2026)

- [ ] Verwendet die Website KI-generierte Inhalte? (Texte, Bilder, Chatbots)
- [ ] **Transparenzpflicht (Art. 50):** KI-generierte Inhalte als solche kennzeichnen?
  - Betrifft: Chatbots, AI-generierte Texte/Bilder, Deep Fakes
  - Pflicht zur Kennzeichnung ab August 2026
- [ ] AI-Chatbot vorhanden? → Muss als AI-System gekennzeichnet sein
- [ ] High-Risk AI System? (Recruiting, Scoring, Biometrie) → Zusaetzliche Pflichten
- [ ] AI-Literacy: Betreiber muessen Grundwissen ueber eingesetzte AI-Systeme haben
- [ ] Dokumentation: Welche AI-Systeme werden eingesetzt, zu welchem Zweck?

---

## Ergebnis

Findings als DSGVO-01, DSGVO-02, ... dokumentieren.
Google Fonts CDN ohne Consent: HIGH (Abmahnrisiko).
Fehlende Datenschutzerklaerung: CRITICAL.
Fehlende Barrierefreiheitserklaerung: HIGH (ab BFSG-Stichtag).
