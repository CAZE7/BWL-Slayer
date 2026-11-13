# Delizioso AG – Der CFO-Simulator

Spielbare Umsetzung des Code-Plans zu **Investition & Finanzierung 1 (Universität Hamburg)**.
Eine einzige, eigenständige HTML-Datei – kein Backend, kein CDN, kein Build-Schritt beim Nutzer.

**Spielen:** [`delizioso-cfo-simulator.html`](../delizioso-cfo-simulator.html) öffnen (Doppelklick oder im Workspace-Preview).

---

## Was drin ist

| Baustein | Umsetzung |
|---|---|
| **8 Spielwelten** | Einführung · Statische Verfahren · Dynamische Verfahren · Anleihen · Finanzplanung · Innenfinanzierung · Beteiligungsfinanzierung · Fremdfinanzierung/Leasing/Leverage |
| **3 Mastery-Stufen pro Welt** | (1) Konzept-Minispiel (Sortier-/Swipe-/Order-/Quiz-Mechanik), (2) Rechen-Labor mit den **Originalaufgaben**, (3) prozeduraler Endlos-Trainer (Zufallszahlen, 5er-Serie) |
| **7 interaktive Simulatoren** | Fuhrpark-Tachometer (x_krit) · Kapitalwertkurve mit Sekanten-Schütze · Bond-Terminal inkl. Duration-Wippe · Du-Pont-Reaktor · Lohmann-Ruchti-Fabrik (Jahr für Jahr) · Bezugsrechts-Waage · Leverage-Regler + Tilgungspläne |
| **Smart Trap Detection** | Typische Klausurfallen werden erkannt und kommentiert: vertauschte Versicherungsprämien (Folie 8), Restwert im Durchschnittskapital, Gewinn statt Cashflow bei der Amortisation, fehlendes Minus vor A₀, 5/12 statt 7/12 beim Dividendennachteil, Vorzeichen der Kursänderung … |
| **CFO-Metriken** | Liquidität, Rentabilität, Unabhängigkeit, Flexibilität – live im Header, gespeist aus dem Fortschritt |
| **Punkte-Konto** | Investition 60 / Finanzierung 60, analog zur echten Modulprüfung |
| **Probeklausur** | 20 Aufgaben, je 6 Punkte, 120-Minuten-Countdown, Auswertung mit Schwachstellen-Liste und kopierbarer Checkliste |
| **Savegame** | `localStorage` (Schlüssel `delizioso-cfo-savegame-v1`), Streak, Budget, freigeschaltete Werkzeugkarten |

## Projektstruktur

```
delizioso-cfo-simulator.html      ← fertige App (Single File, ~183 KB)
delizioso/
├── build.py                      ← baut die HTML aus src/ zusammen
├── src/
│   ├── engine.js                 ← Finanzmathematik (1:1 nach TypeScript portierbar)
│   ├── data1.js                  ← Welten 1–3 (Aufgaben, Konzeptspiele, Trainer-Generatoren)
│   ├── data2.js                  ← Welten 4–8
│   ├── ui_core.js                ← Shell, Savegame, Cockpit, Navigation, Metriken
│   ├── ui_stages.js              ← Stufen-Runner (Konzept / Labor / Trainer)
│   ├── ui_sims.js                ← Simulatoren + SVG-Chart-Helfer
│   ├── app.js                    ← Probeklausur + Init
│   └── styles.css
└── tests/
    ├── verify.cjs                ← 122 Zahlenchecks gegen die Musterlösungen
    └── dom.cjs                   ← jsdom-Smoke-Test (alle Stufen, Simulatoren, Klausur)
```

Build & Tests:

```bash
python3 delizioso/build.py          # HTML neu bauen
node delizioso/tests/verify.cjs     # 122 / 122 grün
node delizioso/tests/dom.cjs        # Smoke-Test der kompletten App
```

## Verifikation der Rechen-Engine

`tests/verify.cjs` prüft jede im Plan genannte Musterlösung – u. a.:

- Fixkosten Auto A/B: 5.980,20 € / 6.445,70 €, x_krit = 116,375 (11.637,5 km)
- Abfüllanlagen: K_fix 34.303,33 € / 37.066,67 €, x_krit 2.763,33, Gewinne 55.696,67 / 67.933,33 €
- Rentabilität 112,52 % / 169,83 %, Amortisation 3,55 / 4,19 Jahre, Kumulation 4,95 Jahre
- KW 8.167,88 € / 8.311,03 €, Annuitäten 2.250,17 / 2.289,60 €, PI 2,59 / 2,75 / 2,75 / 2,77 / −0,083
- Sekante: 4,828 % → 4,823 %; IRR Maschine I/II 14,49 % / 13,70 %
- Anleihen: 111,54 / 102,72 / 103,92 / 100,95 €, YTM 4,73 %, Spots 6,38 / 10,43 / 12,62 %, PV 89,69 €, Duplikation 75,02 €
- Duration: 982,47 € / D = 3,72 / MD = 3,53 / ΔPV −34,65 €, Portfolioduration 8,112
- Lohmann-Ruchti: alle 7 Jahre inkl. Neukäufen, Ausmusterungen und Kassenresten
- Bezugsrechte: 6,00 € / 3,67 € / 2,00 € / 42,00 €, Mischkurse 114 / 48 / 218, Agio 3.360 Mio. €
- Skonto 54 %, Annuität 4.021,15 €, Gesamtzahlungen 12.063,44 / 12.000 / 13.000 €, Leverage 11,25 % / 17,50 %

**Gefundene Abweichungen im Blueprint (dokumentiert, nicht stillschweigend übernommen):**

1. `KW nach 2. Sekanten-Iteration` ist mit −0,11 € statt −0,3819 € korrekt: die Folienzahl entsteht durch das gerundete i* = 4,823 %.
2. `ΔPV bei Δy = +1 %` ergibt mit exakten Werten −34,65 € (Folie rundet auf −34,68 €).
3. `Renten-IRR` (Rbf = 2,381): lineare Interpolation liefert 12,5 % – die Folie sagt „ca. 12 %“.
4. Bei der Interpolation muss der Strahlensatz auf `KW(i) = Rbf(i,n) − Zielwert` angewendet werden (nicht auf `Rbf` selbst), sonst entstehen absurde Werte.
5. Mathefehler im Plan-Text (Welt 8, Leasing): GMZ 21/60 = 35 % → Leasingnehmer (nicht 24/60 = 40 %, das liegt genau auf der Korridorgrenze und damit beim Geber). Der Lab-Task ist entsprechend konsistent zur Engine formuliert.

Zusätzlich: Die im Plan genannte Kennzahl `K_Afa = (A₀ − L)/n` und `K_Zi = (A₀ + L)/2 · i` sind exakt implementiert – der Restwert-Widerspruch (senkt AfA, erhöht Zinsen) wird im Minispiel „Restwert-Waage“ explizit als Lernziel geführt.

## Didaktische Leitlinien im Code

- **Slider vor Tastatur:** Jeder Simulator ist intuitiv bedienbar, bevor eine Zahl eingetippt wird.
- **Fehlercoaching statt Fehlermeldung:** `checkField()` prüft zuerst die Toleranz, dann die Trap-Liste und liefert eine inhaltliche Erklärung („Du hast 5/12 angesetzt – der Nachteil stammt aus den 7 Monaten ohne Dividendenberechtigung“).
- **Kein Frust-Gate:** Jede Stufe lässt sich abschließen; „Lösung zeigen“ kostet Punkte, blockiert aber nicht.
- **Klausur-Split 60/60:** Welten 1–4 zählen für Investition, 5–8 für Finanzierung – identisch zur Modulstruktur (6 ECTS, 120 Minuten).

## Nächste Ausbaustufen (passend zur Sprint-Roadmap)

1. **Kapitel 5 (Aktienbewertung)** ist als eigener Welt-Slot vorgesehen: neue Welt in `data*.js` eintragen, `FIN`-Funktionen (DDM, KGV, EPS) ergänzen, `WORLDS`-Array verlängert sich automatisch (Cockpit, Klausur-Split, Metriken passen sich an).
2. **TypeScript-Port:** `src/engine.js` ist bewusst frei von DOM-Bezügen; Interfaces (`StaticMachineInput`, `LohmannRuchtiYearRow`, …) lassen sich 1:1 als `.ts` übernehmen, Vitest kann `tests/verify.cjs` als Vorlage nutzen.
3. **Drag & Drop / Framer Motion:** Die Sortier- und Order-Spiele sind als reine Klick-Interaktionen implementiert (Preview-sicher). Für `@dnd-kit` genügen die vorhandenen `data-cat`-/`data-id`-Attribute als Drop-Targets.
4. **Formel-KaTeX:** Formeln sind als HTML/Superskript gesetzt, um offline ohne CDN zu funktionieren; ein `react-katex`-Layer kann die `given`-Strings später ersetzen.
