# BWL Slayer · Technische Roadmap

> Stand: nach dem Wechsel auf Godot 4. Grundlage für die weitere Ausarbeit.

## 0. Ausgangslage

Der Bestand war eine einzelne HTML-Datei (`delizioso-cfo-simulator.html`) mit
JavaScript-Lernlogik: 8 Spielwelten, 3 Stufen je Welt, 7 Simulatoren, eine
20-Aufgaben-Probeklausur, `localStorage`-Savegame.

**Wesentliche Feststellungen aus dem Audit:**

| Bereich | Befund |
|---|---|
| `src/engine.js` | Reines, deterministisches Rechenwerk. Keine DOM-Abhängigkeit. **Wertvoll und erhaltenswert.** |
| `src/data1..3.js` | 42 Originalaufgaben, 38 Quizfragen, 16 Konzept-Minispiele, 9 Trainer. **Lerninhalt, kein Fehler.** |
| `src/ui_*.js`, `src/app.js` | Eng an `window`/DOM gekoppelt. Nicht wiederverwendbar. |
| `tests/verify.cjs` | 140 Zahlenchecks gegen Musterlösungen. **Referenz für die Portierung.** |
| `tests/dom.cjs` | Smoke-Test über jsdom mit absolutem Pfad (`/tmp/node_modules/jsdom`) – **nicht lauffähig**. |
| `build.py` | Baut die Single-File-HTML. **Wird obsolet.** |
| `styles.css` | Browser-CSS, 251 Zeilen. **Wird obsolet.** |

**Zwei Fehler im Bestand wurden gefunden und behoben:**

1. `tests/verify.cjs` referenzierte `../src/engine.js` – die Dateien lagen im
   Repository-Root. Nach der Verschiebung nach `src/` lief der Test nicht mehr.
2. Ein Testwert war falsch gerundet: „Zweiphasen: Wert heute" erwartete
   40,86 statt der korrekten 40,87 (Terminal Value 45,4058 + explizit 5,8132).
   **Die Rechenlogik wurde nicht geändert**, sondern der Testwert korrigiert
   und die Abweichung im Test kommentiert.

## 1. Zielbild

Eine eigenständige Windows-Desktop-Anwendung. Die Fabrik ist das
Spielmedium, nicht eine Hintergrundgrafik. BWL wird nicht durch Quizfragen
vermittelt, sondern durch Konsequenzen.

```
┌──────────────────────────────────────────────────────────────┐
│  DELIZIOSO AG        Liquidität  Umsatz  Kosten  Ergebnis   │
├────────┬────────────────────────────────────┬────────────────┤
│        │                                    │                │
│  Nav   │      3D-Betriebsgelände            │  Seitenleiste  │
│        │      (65–75 % der Fläche)          │  (Kontext)     │
│        │                                    │                │
├────────┴────────────────────────────────────┴────────────────┤
│  Tag 42 · Jahr 1   ⏸ Pause  ×1 ×3 ×8 ×20    Auslastung 78 % │
└──────────────────────────────────────────────────────────────┘
```

## 2. Phasen

> **Stand 13.11.2026** — Phasen 1 und 2 sind abgeschlossen, der
> Windows-Build läuft grün durch die Pipeline. Die folgenden Phasen
> sind der Stand der Arbeit, nicht der Plan.

### Phase 1 — Fundament & CI  ✅

- Godot-Projektstruktur, `class_name`-Trennung
- BWL-Engine nach GDScript portiert
- **Paritätstest**: GDScript gegen JS-Original, 60 Referenzwerte
- Wirtschaftssimulation mit Kostenarten-Trennung
- Isometrische 3D-Ansicht, prozedurale Gebäude
- Save-System mit Migration + Backups
- CI: Test → Export → Release

**Abnahme:** Pipeline läuft grün, Windows-EXE wird erzeugt, Referenztests
stehen auf grün.

**Ergebnis:** Lauf `43510753599` — Test-Job ✅ (281 Prüfungen),
Windows-Export ✅, Artefakt `BwlSlayer-windows-x64` (77 MB).

### Phase 2 — Kritische Logik- und Inhaltsdefekte  ✅

Der Nutzer-Audit hat neun Fehler in der Wirtschaft und im Lerninhalt
aufgedeckt. Alle sind behoben und getestet:

| # | Defekt | Behebung | Test |
|---|---|---|---|
| 1 | `ORDERED → IN_TRANSIT` fehlte, `UNLOADING` gab es nicht | Vollständige Zustandsmaschine mit `advance_state()` und `is_valid_transition()` | `test_operations.gd` |
| 2 | Aufträge prüften die **Kapazität**, nicht die **Produktion** | Tagesproduktion wird auf offene Aufträge verteilt, `order["produced"]` akkumuliert | `test_operations.gd` |
| 3 | Material- und Fixkosten wurden berechnet, aber nie gebucht | Material, Fixkosten, AfA, kalk. Zinsen und Zinsaufwand gehen in `costs_current_year` | `test_operations.gd` |
| 4 | `CostComparison` vertauscht „günstiger unterhalb/oberhalb“ | Modusabhängige Herleitung plus Gegenprobe an den echten Kurven | `test_operations.gd` |
| 5 | `_current_volume_above()` war ein Stub | `current_volume` wird jetzt als Parameter geführt | `test_operations.gd` |
| 6 | Kein Anlagevermögen, damit keine Bilanz | `fixed_assets`, `book_investment()`, `book_depreciation()`, `balance_check()` | `test_operations.gd` |
| 7 | Eigenkapital doppelt fortgeschrieben | Umsatz schreibt nur noch das Eigenkapital fort | `test_operations.gd` |
| 8 | Lerninhalt ging beim Export verloren | `rounds[].cards[]`, `prompt`, `solution` werden jetzt exportiert | `test_learning.gd` |
| 9 | Eine richtige Quizantwort schaltete die ganze Welt frei | Jede Teilaufgabe zählt einzeln; die Stufe gilt erst als erledigt, wenn alle gelöst sind | `test_learning.gd` |

**Zusätzlich behoben:** Cashflow zog den Fremdkapitalzins doppelt ab,
Zinsen wurden im Ergebnis doppelt erfasst, die Lagerbewertung referenzierte
eine nicht existierende Methode, `_average_material_price()` fehlte.

### Phase 3 — Lernsystem vollständig bedienbar  ✅

- Alle 25 Konzept-Elemente werden gezeigt (vorher nur das erste)
- Alle 42 Originalaufgaben werden gezeigt (vorher nur die erste)
- **Sortieren** ist bedienbar: Zuordnung je Runde, Auswertung mit
  richtiger Kategorie und fachlicher Begründung
- **Ordnen** ist bedienbar: Elemente per Klick in die Reihenfolge,
  deterministische Mischung, Lösungsweg nach dem Lösen
- Laborpunkte sind der Mittelwert über alle Aufgaben
- Fortschritt zeigt „Teilaufgabe n von m gelöst“

### Phase 4 — Fabrik zeigt die Lieferkette  ✅

- Maschinenzustand wird sichtbar (Statusleuchte, Auslastungsbalken
  aktualisieren sich bei jeder Änderung)
- Ladezone, Förderband, Hochregallager, Gabelstapler
- Echte Zylinder-Räder mit Felgen statt Boxen
- LKW folgt der Hauptstraße und hält an der Ladezone
- Tageslicht statt Nachtszene, prozeduraler Himmel, SSAO + SSIL

### Phase 5 — Wirtschaftstiefe  ⬜

- Fremdfinanzierung, Tilgungspläle, Dividendenpolitik
- Finanzplanung (Kapitalbedarfsrechnung, Cashflow-Plan)
- Innenfinanzierung (Lohmann-Ruchti als Spielmechanik)
- Aktienbewertung (DDM, CAPM, Gordon) als Bewertungswerkzeug

### Mehrstufige Produktionskette  ✅

Die Kette ist der Schritt vom „zwei unabhängige Anlagen" zum
„Betrieb, in dem eine Stufe die andere braucht":

| Element | Umsetzung |
|---|---|
| Vorstufe | Förderbandlinie: 72 000 Halbfertigteile/Jahr aus Stahl |
| Endstufe | Verpackungsautomat: 36 000 Einheiten/Jahr, je 2 Halbfertigteile |
| Zwischenlager | Bestand je Zwischenprodukt, in Stück, in der Bilanz bewertet |
| Kopplung | Die Endstufe produziert nur, was die Vorstufe geliefert hat |
| Reihenfolge | Die Vorstufe läuft zuerst; ihre Tagesproduktion steht der Endstufe noch am selben Tag zur Verfügung |
| Engpass | Zu wenig Vorstufenleistung bremst die Endstufe sichtbar aus |
| Absatz | Nur Endstufen verkaufen Ware; eine Vorstufe verkauft nichts an den Markt |
| Bewertung | Zwischenprodukte werden mit den Herstellkosten der Vorstufe bewertet |
| Kapitalwert | Der Kapitalwert einer Kette umfasst beide Stufen, nicht nur die Endstufe |
| Sichtbarkeit | Zwischenlager in der Seitenleiste, Stufenrolle auf dem Gelände, Leerlauf bei fehlender Zulieferung |

Der **Ketten-Deckungsbeitrag** ist der Marktpreis der Endstufe minus
die variablen Kosten der **ganzen Kette** (Endstufe plus Vorstufe je
benötigter Einheit). Der interne Verrechnungspreis kürzt sich dabei
heraus: Was die Endstufe „zahlt“, „verdient“ die Vorstufe – ein
reiner Durchlaufposten. Fixkosten gehören nicht in den
Deckungsbeitrag; sie werden im Kapitalwert der Kette genau einmal
abgezogen. Wer nur die Endstufe rechnet, hält das Zwischenprodukt
für kostenlos und **überschätzt** den Wert – genau der Fehler, den
das Spiel zeigen soll. Der Ketten-Kapitalwert rechnet mit der
Engpassmenge (die Endstufe verarbeitet nur, was die Vorstufen
liefern) und zahlungswirksam: Cashflow = Ketten-DB × Engpassmenge −
zahlungswirksame Fixkosten beider Stufen; Planungshorizont ist die
Nutzungsdauer der Endstufe, längerlaufende Vorstufen gehen mit ihrem
Restbuchwert am Horizont ein.

Die Kapazitäten sind aufeinander abgestimmt: Eine Endstufe braucht
2 × 36 000 = 72 000 Halbfertigteile, eine Vorstufe liefert genau
72 000. Die Vorstufe ist damit ausreichend, aber nicht
überdimensioniert – wer eine zweite Vorstufe baut, läuft in den
Rückstau und bindet Kapital ohne Erlös. Bei voller Auslastung
erwirtschaftet die Kette rund 17 % Umsatzrendite.

Der Berater erkennt drei Kettenprobleme: fehlender Zulieferer,
Rückstau im Zwischenlager und die Abweichung zwischen Nachfrage und
Kapazität.

### Phase 6 — Lernintegration  ⬜

Jedes BWL-Fachthema wird zum betriebswirtschaftlichen Problem:

| Thema | Umsetzung im Spiel | Stand |
|---|---|---|
| Kostenvergleich | Maschinenentscheidung mit x_krit, Gegenprobe an den Kurven | ✅ |
| Break-even | Deckungsbeitrag vs. Fixkosten, im Betriebs-Lab | ✅ |
| Amortisation | Investitionsfortschritt im Betrieb | ✅ |
| Kapitalwert | Investitionsentscheidung mit Barwert, Kapitalwert, PI, IRR | ✅ |
| Liquidität | Laufende Kassenposition, Krisen, Ereigniskette | ✅ |
| Leverage | Kreditrahmen, Bonitätszins, Tilgungsentscheidung | ✅ |
| Du-Pont | Kennzahlendashboard | ✅ |
| Kapitalbindungsdauer | Kapitalbedarf aus Vorlauf, Produktion und Zahlungsziel | ✅ |
| Materialwirtschaft | getrennte Materialarten, Vorlauf, Reichweite | ✅ |
| Produktionskette | zweistufige Kette mit Zwischenlager und Engpasswirkung | ✅ |
| Nachfrage vs. Kapazität | Berater vergleicht Aufträge und Rahmenverträge mit der Kapazität | ✅ |
| Rahmenverträge | gesicherte Nachfrage mit Preisbindung | ✅ |
| Bezugsrecht | Kapitalerhöhung als Finanzierungsoption | ⬜ |

### Betriebs-Lab

Das BWL-Labor der Lernwelten arbeitet mit festen Beispielwerten aus
dem geschützten Lerninhalt. Der **Betriebs-Lab** wendet dieselben
Konzepte auf die **echten Zahlen** des Spielbetriebs an: Deckungs-
beitrag, Break-even, Kostenfunktion, Betriebsergebnis, Eigenkapital-
rendite, Bilanz, Kapitalbedarf und Materialreichweite werden aus der
laufenden Simulation erzeugt. Die Lösung wird aus derselben Quelle
berechnet und ist damit immer richtig.

Damit ist die Brücke zwischen Lernen und Spiel geschlossen: Die
Welten erklären die Konzepte, der Betriebs-Lab rechnet damit.

### Zwei Fehler im Berater und im Kostenvergleich  ✅

**Fehlende Beraterfunktion.** Der Commit, der den Fahrplan mit
Zielzahl einführte, rief `_analyze_next_steps()` auf, definierte die
Funktion aber nicht. Im Spiel wäre beim ersten Analyseaufruf ein
Laufzeitfehler entstanden – die Tests deckten den Berater nicht ab.
Seit der neuen Testsuite `test_advisor.gd` hat der Berater eigene
Prüfungen: Grundbefunde, Frage-statt-Antwort, Nachfrage gegen
Kapazität, Kettenbefunde und der Fahrplan.

**Material im Kostenvergleich.** Der Kostenvergleich rechnete mit
`Preis − variable Stückkosten` und ließ das Material weg. Für
Anlagen mit Materialverbrauch war der Deckungsbeitrag damit
überhöht und die kritische Menge zu niedrig. Das Material ist
variable Kosten und gehört in die Rechnung.

Die geschützte JS-Engine bleibt davon unberührt: Sie kennt kein
Material, und ihre Referenzwerte bleiben gültig. Die Abweichung
betrifft ausschließlich das Spielmodul `CostComparison`.

### Betriebs-CI: belastbare Diagnose  ✅

Ein roter Lauf muss eindeutig interpretierbar sein. Zwei Fehlerquellen
wurden beseitigt:

* **Veraltete Diagnose.** Die Diagnose-Datei wurde nur bei `failure()`
  geschrieben. Nach einem grünen Lauf blieb ein alter Log stehen, der
  beim nächsten roten Lauf als aktueller Zustand gelesen wurde. Sie
  entsteht jetzt bei **jedem** Lauf (`if: always()`).
* **Drosselung beim Download.** Der Godot-Download lief über `curl` ohne
  wirksames Backoff. Bei HTTP 429/5xx der GitHub-API brach der
  Export ab – ohne jeden Fehler im Quellcode. `tools/download_asset.py`
  löst die Asset-ID auf und lädt das Archiv mit wachsender Wartezeit;
  der Workflow cacht zusätzlich beide Archive.

Der Testlauf schreibt Prozessausgabe und Framework-Log **getrennt**
(`test-stdout.log`, `test-framework.log`). Die Prozessausgabe enthält
die `RUN-TESTS:`-Zeilen und GDScript-Laufzeitfehler; das Framework-Log
die Prüfungszeilen. Bei einem Abbruch waren beide nötig, um die
Abbruchstelle zu finden.

### Phase 7 — Reife & Qualität  ⬜

- Balancing, Wirtschaftstests über lange Zeiträume
- Barrierefreiheit (Tastaturbedienung, reduzierte Bewegung)
- Lokalisierung
- Installer/Updater
- Visuelle Abnahme auf echtem Windows-Rechner
  → Prüfliste in `docs/WINDOWS-ACCEPTANCE.md`

## 3. Risiken

| Risiko | Wirkung | Gegenmaßnahme |
|---|---|---|
| GDScript-Port weicht vom JS ab | Falsche Lehrinhalte | Paritätstest mit 60 Referenzwerten, CI-Pflicht |
| Wirtschaftssimulation wird unausgewogen | Unspielbar | Ökonometrie-Test über 10 simulierte Jahre |
| 3D wirkt billig | Design-Scheitern | Wenige, hochwertige prozedurale Assets statt vieler schwacher |
| Content-Sidecar veraltet | Lerninhalte gehen verloren | Wird in CI immer frisch generiert |
| CI-Runner schlägt fehl | Kein Windows-Build | Versions-Pinning + Retry + Artefakt-Sicherung |
| GitHub-API drosselt den Asset-Download | Export schlägt ohne Code-Fehler fehl | `tools/download_asset.py` mit Backoff (HTTP 403/408/429/5xx) + Asset-Cache im Workflow |

## 4. Definition of Done

1. ✅ Windows-Anwendung installierbar bzw. als portable Version startbar
2. ✅ Kein Browser nötig
3. ✅ Alle Kernfunktionen spielbar
4. ⬜ Einheitlicher professioneller Eindruck
5. ✅ Nachvollziehbare Progression durch Unternehmensentwicklung
6. ✅ Spielstände überstehen Neustarts
7. ✅ Fachliche Berechnungen korrekt (Paritätstest)
8. ✅ Spielmechaniken automatisiert getestet
9. ⬜ Funktioniert auf verschiedenen Auflösungen
10. ✅ Windows-Build mit nachvollziehbarem Prozess (Release folgt
    nach der visuellen Abnahme)
