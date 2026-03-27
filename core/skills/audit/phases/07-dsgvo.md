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

### 7. EU AI Act

**Status (Maerz 2026):** GPAI-Enforcement aktiv seit Maerz 2026. High-Risk-Deadlines durch Digital Omnibus verschoben.

- [ ] Verwendet die Website KI-generierte Inhalte? (Texte, Bilder, Chatbots)
- [ ] **Transparenzpflicht (Art. 50):** KI-generierte Inhalte als solche kennzeichnen?
  - Betrifft: Chatbots, AI-generierte Texte/Bilder, Deep Fakes
  - **Deadline verlängert:** AI-Systeme auf dem Markt vor Aug 2026 → Compliance bis **2. Februar 2027**
  - Neue Systeme: Kennzeichnung ab August 2026
- [ ] **GPAI (General-Purpose AI):** Seit Maerz 2026 aktive Durchsetzung
  - Transparenz- und Dokumentationspflichten fuer GPAI-Anbieter
  - Betrifft: Projekte die Claude API, OpenAI API o.ae. einsetzen
- [ ] AI-Chatbot vorhanden? → Muss als AI-System gekennzeichnet sein
- [ ] **High-Risk AI System?** (Recruiting, Scoring, Biometrie)
  - Standalone: Compliance bis **2. Dezember 2027**
  - In Produkten eingebettet: Compliance bis **2. August 2028**
- [ ] AI-Literacy: Betreiber muessen Grundwissen ueber eingesetzte AI-Systeme haben
- [ ] Dokumentation: Welche AI-Systeme werden eingesetzt, zu welchem Zweck?
- [ ] **AI Regulatory Sandboxes:** Nationale Behoerden muessen bis Dezember 2027 einrichten

### 8. GDPR — EU Digital Omnibus (Proposed)

**Status:** Vorgeschlagen Q4 2025, EU-Rat hat Position im Maerz 2026 vereinbart. Noch NICHT in Kraft.

- [ ] **Hinweis:** Folgende Aenderungen sind vorgeschlagen aber noch nicht rechtskraeftig — vorbereitend pruefen
- [ ] AI-Datenverarbeitung: Neue Ausnahme fuer "residuale" besondere Datenkategorien bei AI-Entwicklung/-Betrieb (mit Schutzmaßnahmen)
- [ ] Automatisierte Entscheidungen (Art. 22): Lockerung fuer nicht-sensitive Daten — ohne explizite Einwilligung moeglich, mit Safeguards (Info, Widerspruch, menschliche Intervention)
- [ ] Definition personenbezogener Daten: Vorgeschlagene Einschraenkung (EU-Behoerden stark dagegen)
- [ ] Breach Notification: Single-Entry-Point geplant fuer NIS2 + DORA + GDPR + eIDAS
- [ ] Enforcement-Fokus: Dark Patterns, AI-Processing, Consent-Manipulation

---

## Ergebnis

Findings als DSGVO-01, DSGVO-02, ... dokumentieren.
Google Fonts CDN ohne Consent: HIGH (Abmahnrisiko).
Fehlende Datenschutzerklaerung: CRITICAL.
Fehlende Barrierefreiheitserklaerung: HIGH (ab BFSG-Stichtag).
AI ohne Kennzeichnung: HIGH (ab Aug 2026 / Feb 2027 fuer Bestandssysteme).
GPAI ohne Dokumentation: HIGH (Enforcement aktiv seit Maerz 2026).

---

As of: 2026-03-27 (updated for EU AI Act GPAI enforcement, Digital Omnibus timeline changes, GDPR Omnibus proposed amendments)
