# Nachweis-Matrix Lerninhalt

> **Zweck:** Jedes Element des geschützten Legacy-Lerninhalts muss in Godot
> nachweisbar vorhanden, spielbar und getestet sein. Diese Matrix wird
> automatisch gegen `godot/content/worlds.json` geprüft.

<!-- ERZEUGT VON tools/generate_traceability.cjs – NICHT VON HAND AENDERN -->

## Erzeugung

```
node tools/export_content.cjs            # src/data1..3.js -> godot/content/worlds.json
node tools/generate_traceability.cjs     # -> docs/CONTENT-TRACEABILITY.md
```

Die Matrix ist **verlustfrei**: exportiert werden `rounds[].cards[]`,
`prompt`, `solution`, `questions[]` sowie alle Lab-Aufgaben mit ihren
Feldtoleranzen.

## Gesamtbestand

| Inhaltstyp | Anzahl | Quelle | Godot-Ziel | Test |
|---|---|---|---|---|
| Welten | 9 | `src/data1..3.js` | `godot/content/worlds.json` | `_test_content_coverage` |
| Quiz-Minispiele | 9 | `concept.items[kind=quiz]` | `ConceptItem.questions` | `_test_sort_order_content` |
| Zuordnungsaufgaben | 12 | `concept.items[kind=sort]` | `ConceptItem.rounds` | `_test_sort_order_content` |
| Zuordnungsrunden | 12 | `concept.items[kind=sort].rounds` | `ConceptItem.rounds` | `_test_sort_order_content` |
| Zuordnungskarten | 62 | `concept.items[kind=sort].rounds[].cards` | `ConceptItem.rounds[].cards` | `_test_sort_order_content` |
| Ordnungsaufgaben | 4 | `concept.items[kind=order]` | `ConceptItem.items` | `_test_sort_order_content` |
| Originalaufgaben | 42 | `lab.tasks` | `LabTask` | `_test_content_coverage` |
| Trainer-Generatoren | 9 | `trainer.gen()` | `EndlessTrainer` | `_test_content_coverage` |

## Je Welt

### W1 — Grundlagen & Einführung

- **Seite:** INV · **Quelle:** 1. Einführung (2).pdf · 2. Statische Verfahren (Folien 7–8) · Finanzierungsteil Kap. 1.0–1.1
- **Briefing:** 4 Abschnitte · **Tag:** Cashflow-Tinder & Bilanz-Architekt

| Typ | Titel | Umfang | Godot-Datei | Status |
|---|---|---|---|---|
| sort | Runde 1 · Zahlungsstromrichtung | 1 Runden, 5 Karten | `learning_overlay.gd` | ✅ |
| sort | Runde 2 · Kostenbegriffe | 1 Runden, 6 Karten | `learning_overlay.gd` | ✅ |
| sort | Runde 3 · Kapitalarten | 1 Runden, 5 Karten | `learning_overlay.gd` | ✅ |
| order | Prozess-Puzzle · Investitionsentscheidung | 5 Elemente | `learning_overlay.gd` | ✅ |
| sort | Investitionsrechnungs-Trichter | 1 Runden, 8 Karten | `learning_overlay.gd` | ✅ |
| quiz | Principal-Agent-Detektiv | 5 Fragen | `learning_overlay.gd` | ✅ |
| lab | w1t1 | 1 Felder | `LabTask` | ✅ |
| lab | w1t2 | 1 Felder | `LabTask` | ✅ |
| lab | w1t3 | 1 Felder | `LabTask` | ✅ |
| trainer | Endlos-Trainer | prozedural | `endless_trainer.gd` | ✅ |

### W2 — Statische Investitionsrechnung

- **Seite:** INV · **Quelle:** 2. Statische_Verfahren (2).pdf · Aufgaben mit Lösung · PowerPoint-Version
- **Briefing:** 4 Abschnitte · **Tag:** Fuhrpark- & Abfüllanlagen-Duell

| Typ | Titel | Umfang | Godot-Datei | Status |
|---|---|---|---|---|
| quiz | Konzept-Check | 4 Fragen | `learning_overlay.gd` | ✅ |
| sort | Fixkosten-Baukasten | 1 Runden, 5 Karten | `learning_overlay.gd` | ✅ |
| lab | w2t1 | 4 Felder | `LabTask` | ✅ |
| lab | w2t2 | 7 Felder | `LabTask` | ✅ |
| lab | w2t3 | 2 Felder | `LabTask` | ✅ |
| lab | w2t4 | 4 Felder | `LabTask` | ✅ |
| lab | w2t5 | 3 Felder | `LabTask` | ✅ |
| trainer | Endlos-Trainer | prozedural | `endless_trainer.gd` | ✅ |

### W3 — Dynamische Investitionsrechnung

- **Seite:** INV · **Quelle:** 3. Dynamische_Verfahren (1).pdf · Aufgaben mit Lösung · Aufgabendatei
- **Briefing:** 4 Abschnitte · **Tag:** Zeitwert-Zeitmaschine & IRR-Laser

| Typ | Titel | Umfang | Godot-Datei | Status |
|---|---|---|---|---|
| sort | Werkzeugkarten zuordnen | 1 Runden, 5 Karten | `learning_overlay.gd` | ✅ |
| quiz | Methodenkonflikt | 4 Fragen | `learning_overlay.gd` | ✅ |
| lab | w3t1 | 2 Felder | `LabTask` | ✅ |
| lab | w3t2 | 4 Felder | `LabTask` | ✅ |
| lab | w3t3 | 3 Felder | `LabTask` | ✅ |
| lab | w3t4 | 4 Felder | `LabTask` | ✅ |
| lab | w3t5 | 2 Felder | `LabTask` | ✅ |
| lab | w3t6 | 3 Felder | `LabTask` | ✅ |
| trainer | Endlos-Trainer | prozedural | `endless_trainer.gd` | ✅ |

### W4 — Festverzinsliche Wertpapiere

- **Seite:** INV · **Quelle:** 4. Anleihen.pdf (Folien 1–71)
- **Briefing:** 4 Abschnitte · **Tag:** Bond-Desk & Arbitrage-Labor

| Typ | Titel | Umfang | Godot-Datei | Status |
|---|---|---|---|---|
| quiz | Pari-Scanner | 4 Fragen | `learning_overlay.gd` | ✅ |
| sort | Risiko-Radar | 1 Runden, 5 Karten | `learning_overlay.gd` | ✅ |
| sort | Zerobond-Typen | 1 Runden, 3 Karten | `learning_overlay.gd` | ✅ |
| lab | w4t1 | 4 Felder | `LabTask` | ✅ |
| lab | w4t2 | 2 Felder | `LabTask` | ✅ |
| lab | w4t3 | 4 Felder | `LabTask` | ✅ |
| lab | w4t4 | 3 Felder | `LabTask` | ✅ |
| lab | w4t5 | 4 Felder | `LabTask` | ✅ |
| trainer | Endlos-Trainer | prozedural | `endless_trainer.gd` | ✅ |

### W5 — Finanzplanung & Finanzkontrolle

- **Seite:** FIN · **Quelle:** Finanzierungsteil (2).pdf, Kap. 2.0–2.2 (Folien 26–48)
- **Briefing:** 4 Abschnitte · **Tag:** Working-Capital-Defense & Du-Pont-Reaktor

| Typ | Titel | Umfang | Godot-Datei | Status |
|---|---|---|---|---|
| order | Cash-Cycle-Zeitstrahl | 5 Elemente | `learning_overlay.gd` | ✅ |
| quiz | Bilanz-Cockpit | 4 Fragen | `learning_overlay.gd` | ✅ |
| lab | w5t1 | 2 Felder | `LabTask` | ✅ |
| lab | w5t2 | 3 Felder | `LabTask` | ✅ |
| lab | w5t3 | 5 Felder | `LabTask` | ✅ |
| lab | w5t4 | 4 Felder | `LabTask` | ✅ |
| trainer | Endlos-Trainer | prozedural | `endless_trainer.gd` | ✅ |

### W6 — Innenfinanzierung

- **Seite:** FIN · **Quelle:** Finanzierungsteil (2).pdf, Kap. 3.1 (Folien 49–71)
- **Briefing:** 4 Abschnitte · **Tag:** Lohmann-Ruchti-Fabrik & Stille-Reserven-Tresor

| Typ | Titel | Umfang | Godot-Datei | Status |
|---|---|---|---|---|
| quiz | Innenfinanzierung verstehen | 4 Fragen | `learning_overlay.gd` | ✅ |
| order | Stille-Reserven-Kaskade | 5 Elemente | `learning_overlay.gd` | ✅ |
| lab | w6t1 | 3 Felder | `LabTask` | ✅ |
| lab | w6t2 | 3 Felder | `LabTask` | ✅ |
| lab | w6t3 | 3 Felder | `LabTask` | ✅ |
| lab | w6t4 | 3 Felder | `LabTask` | ✅ |
| trainer | Endlos-Trainer | prozedural | `endless_trainer.gd` | ✅ |

### W7 — Beteiligungsfinanzierung

- **Seite:** FIN · **Quelle:** Finanzierungsteil (2).pdf, Kap. 3.2 (Folien 72–121) · Vergleichsabschnitt 4. Anleihen
- **Briefing:** 4 Abschnitte · **Tag:** Roadshow-Tycoon & Bezugsrechts-Rechner

| Typ | Titel | Umfang | Godot-Datei | Status |
|---|---|---|---|---|
| sort | Kapitalerhöhungs-Formen | 1 Runden, 5 Karten | `learning_overlay.gd` | ✅ |
| quiz | Going-Public-Entscheidungen | 4 Fragen | `learning_overlay.gd` | ✅ |
| lab | w7t1 | 4 Felder | `LabTask` | ✅ |
| lab | w7t2 | 2 Felder | `LabTask` | ✅ |
| lab | w7t3 | 3 Felder | `LabTask` | ✅ |
| lab | w7t4 | 5 Felder | `LabTask` | ✅ |
| trainer | Endlos-Trainer | prozedural | `endless_trainer.gd` | ✅ |

### W8 — Fremdfinanzierung, Leasing & Optimierung

- **Seite:** FIN · **Quelle:** Finanzierungsteil (2).pdf, Kap. 3.3 & 4.0 (Folien 122–193)
- **Briefing:** 5 Abschnitte · **Tag:** Skonto-Schocker & Leverage-Boss

| Typ | Titel | Umfang | Godot-Datei | Status |
|---|---|---|---|---|
| sort | Kreditleihe oder Geldleihe? | 1 Runden, 5 Karten | `learning_overlay.gd` | ✅ |
| sort | Factoring oder Forfaitierung? | 1 Runden, 4 Karten | `learning_overlay.gd` | ✅ |
| quiz | Leasing & Zielsystem | 4 Fragen | `learning_overlay.gd` | ✅ |
| lab | w8t1 | 2 Felder | `LabTask` | ✅ |
| lab | w8t2 | 5 Felder | `LabTask` | ✅ |
| lab | w8t3 | 4 Felder | `LabTask` | ✅ |
| lab | w8t4 | 4 Felder | `LabTask` | ✅ |
| lab | w8t5 | 4 Felder | `LabTask` | ✅ |
| trainer | Endlos-Trainer | prozedural | `endless_trainer.gd` | ✅ |

### W9 — Aktien & Aktienbewertung

- **Seite:** INV · **Quelle:** Kapitel 5 (Slot, Folien ab Dez. 2026) · Aktien-Grundlagen aus Finanzierungsteil Kap. 3.2 & 4. Anleihen (Vergleichsabschnitt)
- **Briefing:** 4 Abschnitte · **Tag:** Bewertungs-Terminal & Gordon-Reaktor

| Typ | Titel | Umfang | Godot-Datei | Status |
|---|---|---|---|---|
| sort | Aktienwert-Treiber | 1 Runden, 6 Karten | `learning_overlay.gd` | ✅ |
| order | Fundamentale Aktienbewertung | 6 Elemente | `learning_overlay.gd` | ✅ |
| quiz | Bewertungs-Check | 5 Fragen | `learning_overlay.gd` | ✅ |
| lab | w9t1 | 3 Felder | `LabTask` | ✅ |
| lab | w9t2 | 2 Felder | `LabTask` | ✅ |
| lab | w9t3 | 3 Felder | `LabTask` | ✅ |
| lab | w9t4 | 3 Felder | `LabTask` | ✅ |
| lab | w9t5 | 3 Felder | `LabTask` | ✅ |
| lab | w9t6 | 3 Felder | `LabTask` | ✅ |
| trainer | Endlos-Trainer | prozedural | `endless_trainer.gd` | ✅ |

## Rechenwerte

Die Legacy-Engine `src/engine.js` ist die Rechenautorität. Ihre 140
numerischen Referenzprüfungen laufen unverändert unter `tests/verify.cjs`.
Für den GDScript-Port werden zusätzlich 60 Referenzwerte erzeugt:

```
node tools/generate_reference.cjs   # -> godot/content/reference_values.json
```

`godot/tests/test_engine_parity.gd` berechnet jeden dieser Werte neu
über `BWLEngine` und vergleicht ihn mit ± 0,01. In CI wird die
Referenzdatei **vor** den Tests neu erzeugt — die Parität wird also immer
gegen die aktuelle Legacy-Engine geprüft.

| Umfang | Wert |
|---|---|
| Legacy-Prüfungen (`tests/verify.cjs`) | 140 |
| Port-Referenzwerte (`reference_values.json`) | 60 |

## Automatische Vollständigkeitsprüfung

`godot/tests/test_learning.gd` schlägt fehl, wenn

- eine Welt weniger als 3 Stufen hat,
- eine Welt kein Briefing oder keine Quelle hat,
- die Verteilung der Seiten nicht 5 INV / 4 FIN ergibt,
- eine Welt keine Originalaufgaben hat,
- eine Welt weniger als 2 Quizfragen hat,
- eine Welt keinen Trainer hat,
- eine Zuordnungsrunde keine Kategorien oder Karten hat,
- eine Karte keine Kategorie oder keine Begründung hat,
- eine Ordnungsaufgabe weniger als 3 Elemente hat,
- eine Ordnungsaufgabe keinen Lösungsweg hat,
- die Anzahl der Zuordnungsrunden oder Karten vom Legacy-Bestand abweicht.
