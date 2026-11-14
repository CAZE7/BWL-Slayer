# Architektur — BWL Slayer

> Godot 4 ist die einzige Produktionsplattform. Die Legacy-Engine in
> JavaScript bleibt als **Rechenautorität** erhalten, wird aber nicht
> ausgeliefert.

## Schichten

```
┌───────────────────────────────────────────────────────────────┐
│  UI-Schicht          main.gd · learning_overlay.gd            │
│                       investment_panel.gd · advisor           │
├───────────────────────────────────────────────────────────────┤
│  Simulationskern     simulation.gd (Orchestrator)            │
│                       machine_instance.gd · economy_state.gd  │
│                       cost_comparison.gd                      │
├───────────────────────────────────────────────────────────────┤
│  Fachlogik           bwl_engine.gd (Port der Legacy-Engine)  │
│                       advisor.gd (Berater)                    │
├───────────────────────────────────────────────────────────────┤
│  Lernsystem          content_loader.gd · world_content.gd     │
│                       concept_item.gd · lab_task.gd           │
│                       player_progress.gd                      │
├───────────────────────────────────────────────────────────────┤
│  Persistenz          save_system.gd · save_store.gd          │
│                       save_service.gd                         │
├───────────────────────────────────────────────────────────────┤
│  Darstellung         factory_view.gd · factory_builder.gd    │
│                       camera_rig.gd                           │
└───────────────────────────────────────────────────────────────┘
```

Die Abhängigkeitsrichtung geht **strikt nach unten**. Keine Schicht
darunter kennt eine darüber.

## Godot-Projekt

```
godot/
├── project.godot          # Godot 4.7.2-stable, Forward+, 1600×900
├── export_presets.cfg     # "Windows Desktop" x86_64
├── scenes/main.tscn
├── src/
│   ├── core/              # event_bus, game_state, save_*
│   ├── sim/               # simulation, machine_*, economy_state
│   ├── engine/            # bwl_engine.gd
│   ├── learning/          # content_*, world_content, *_task
│   ├── advisor/           # advisor.gd
│   ├── factory/           # factory_view, factory_builder, camera_rig
│   └── ui/                # investment_panel.gd
├── tests/                 # GDScript-Testsuites
├── content/               # worlds.json, reference_values.json
└── assets/
```

### Autoloads

| Autoload | Datei | Aufgabe |
|---|---|---|
| `EventBus` | `core/event_bus.gd` | 32 Signale, lose Kopplung |
| `GameState` | `core/game_state.gd` | Fortschritt, Einstellungen, Spielstand |
| `SaveService` | `core/save_service.gd` | Fassade über `SaveStore` |
| `Simulation` | `sim/simulation.gd` | Der Wirtschaftskern |
| `Advisor` | `advisor/advisor.gd` | Unternehmensberater |

**Wichtig:** Autoload-Skripte tragen **kein** `class_name`, das dem
Autoload-Namen entspricht — Godot verbietet es, dass eine Klasse einen
Autoload-Singleton verdeckt. `simulation.gd` heißt deshalb in der Klasse
`SimulationEngine`; der Autoload bleibt `Simulation`. Dasselbe Prinzip
gilt für `game_state.gd` (`GameStateStore`) und `event_bus.gd` (kein
`class_name`).

### Ereigniskette

Die Kette vom Spielereignis zum sichtbaren Feedback läuft über den
EventBus. Simulation, UI und Berater kennen sich nicht gegenseitig.

```
Spieleraktion
   → Simulation (Buchung, Zustandswechsel)
   → EventBus-Signal
   → UI (Kopfzeile, Toast, Szene) + Advisor (Hinweis)
```

Signale, die den Spielablauf tragen:

| Signal | Auslöser | Empfänger |
|---|---|---|
| `cash_changed` | jede Kassenbewegung | Kopfzeile, Advisor |
| `order_received` | neuer Kundenauftrag | Advisor, Toast |
| `delivery_installed` | Maschine in Betrieb | Advisor, Fabrikszene |
| `order_completed` | Auftrag geliefert | Advisor |
| `machine_state_changed` | Zustandswechsel einer Anlage | Fabrikszene |
| `advisor_message_added` | neuer Hinweis | Beraterbereich, Toast |
| `notification` | allgemeine Meldung | Toast |

Der Berater hört auf `order_received`, `delivery_installed`,
`order_completed` und `cash_changed`. Er erklärt jedes dieser
Ereignisse wirtschaftlich — mit Frage, Lektion und Handlung.

Jede Kassenbewegung läuft über `EconomyState.move_cash()`. Nur diese
eine Stelle ändert `cash` und meldet die Änderung. Dadurch kann kein
Zahlungsweg die Meldung vergessen — und keine Zahlung doppelt laufen.

### Beschaffung

Material hat Vorlauf. `Simulation.order_material()` bucht die Zahlung
sofort, legt aber eine Materiallieferung mit Restlaufzeit an. Erst
wenn die Lieferzeit abgelaufen ist, geht die Ware ins Lager.

`material_coverage_days()` beantwortet die Planungsfrage: Wie viele
Tage Produktion sichert der Bestand noch? Der Berater vergleicht das
mit der Lieferzeit und warnt **vor** dem Produktionsstopp.

## Die geschützten Altbestände

| Datei | Rolle | Status |
|---|---|---|
| `src/engine.js` | **Rechenautorität** für alle BWL-Formeln | unverändert, 140/140 Tests grün |
| `src/data1.js` … `data3.js` | Lerninhalt: 9 Welten, 42 Aufgaben, Quiz, Sortier-/Ordnungsaufgaben | unverändert, vollständig exportiert |
| `tests/verify.cjs` | 140 numerische Referenzprüfungen | unverändert, autoritativ |
| `src/ui_core.js`, `src/ui_sims.js`, `src/ui_stages.js` | Legacy-UI | bleibt im Repository als Referenz |

Es gibt **keine** zweite Produktionsanwendung. Die Legacy-Dateien werden
nicht ausgeliefert, sie dienen als Quelle und als Testmaßstab.

### Kontrollierte Portierung

Die GDScript-Fassung (`engine/bwl_engine.gd`) bildet 55 Funktionen der
Legacy-Engine ab. Die Absicherung läuft in zwei Stufen:

1. **Statisch:** `tools/generate_reference.cjs` erzeugt
   `godot/content/reference_values.json` mit 60 beschrifteten
   Referenzwerten direkt aus `src/engine.js`.
2. **Dynamisch:** `godot/tests/test_engine_parity.gd` berechnet jeden
   Wert neu über `BWLEngine` und vergleicht ihn (± 0,01).

In CI wird die Referenzdatei **vor** den Tests neu erzeugt — die
Parität wird also immer gegen die aktuelle Legacy-Engine geprüft, nicht
gegen eine eingefrorene Kopie.

### Inhalts-Export

`tools/export_content.cjs` liest die Legacy-Daten mit `eval` und
schreibt `godot/content/worlds.json`. Der Export ist **verlustfrei**:

- `rounds[].cards[]` der Zuordnungsaufgaben (12 Runden, 62 Karten)
- `prompt` und `solution` der Ordnungsaufgaben
- `questions[]` der Quizfragen

Vor dem Fix sind diese Felder stillschweigend verloren gegangen — die
Zuordnungsaufgaben waren in Godot leer. Der Test
`test_learning.gd::_test_sort_order_content` sichert die Vollständigkeit
jetzt ab.

## Datenmodelle

| Klasse | Datei | Schlüssel |
|---|---|---|
| `MachineSpec` | `sim/machine_spec.gd` | Kostenstruktur, Kapazität, Lieferzeiten |
| `MachineInstance` | `sim/machine_instance.gd` | Zustand, Alter, Buchwert, Produktion |
| `EconomyState` | `sim/economy_state.gd` | Kasse, EK, FK, Anlagevermögen, Jahrgrößen |
| `CostComparison` | `sim/cost_comparison.gd` | kritische Menge, Kurven, Empfehlung |
| `ConceptItem` | `learning/concept_item.gd` | quiz / sort / order |
| `LabTask` | `learning/lab_task.gd` | Originalaufgabe mit Feldern und Toleranzen |
| `WorldContent` | `learning/world_content.gd` | eine Welt mit allen Stufen |
| `PlayerProgress` | `learning/player_progress.gd` | Stufen, Punkte, Teilaufgaben, XP |

## Zustandsmaschine der Maschine

```
ORDERED → IN_TRANSIT → ARRIVED → UNLOADING → INSTALLING → ACTIVE
                                                                    ↓
                                                            DECOMMISSIONED
```

Jeder Übergang läuft über `advance_state()` und trägt eine fachliche
Begründung im Code. `is_valid_transition()` lehnt Sprünge ab. Die
statische Prüfung `tools/check_gdscript.cjs` sichert ab, dass kein
Übergang die Zustandsmaschine umgeht.

## Wirtschaftliche Trennung

Die zentrale Regel: **Eine Maschine wird nie doppelt belastet.**

```
Investition:    Kasse −A₀   |  Anlagevermögen +A₀     (Aktivierung)
Abschreibung:   Anlagevermögen −AfA | Gewinn −AfA      (nicht zahlungswirksam)
Fixkosten:      Gewinn −F    |  Kasse −F              (zahlungswirksam)
Material:       Gewinn −M    |  Lager −M, Kasse −M    (zahlungswirksam)
kalk. Zinsen:   Gewinn −KZ   |  Kasse unberührt       (nicht zahlungswirksam)
Zins FK:        Gewinn −Z    |  Kasse −Z              (zahlungswirksam)
Tilgung:        FK −T       |  Kasse −T              (zahlungswirksam)
```

`EconomyState.balance_check()` prüft, dass Aktiva und Passiva
zusammengehören.

## Persistenz

```
save_system.gd   Statische Format-Logik: Version, Migration, Sanitizing
save_store.gd    Dateisystem: atomisches Schreiben, rotierende Backups
save_service.gd  Autoload-Fassade: write_slot / load_slot / delete_slot
```

- Aktuelle Version: **3**
- Migration von Version 1 (Cash, `playerName`) und 2
- `sanitize_save()` ersetzt unplausible Werte (negative Kassen,
  Reputation außerhalb 0–100, fehlende Welten) durch Defaults

**Fallstrick:** `DirAccess.make_dir_recursive()` (Instanzmethode)
**hängt** headless. Es wird ausschließlich die statische Variante
`DirAccess.make_dir_recursive_absolute()` verwendet.

## Tests

### GDScript-Suites

| Suite | Prüft |
|---|---|
| `test_bwl_engine.gd` | Formeln der BWL-Engine gegen bekannte Werte |
| `test_engine_parity.gd` | 60 Referenzwerte gegen die Legacy-Engine |
| `test_simulation.gd` | Kostenarten, Lebenszyklus, Kennzahlen, Liquidität |
| `test_operations.gd` | Lieferkette, Produktion, Aufträge, Investition, Bilanz |
| `test_persistence.gd` | Speichern, Laden, Migration, Sanitizing |
| `test_learning.gd` | Inhaltsvollständigkeit, Aufgabenlogik, Freischaltung |

Ausführung: `godot/tests/run_tests.gd` lädt die Suites zur Laufzeit über
`load()` (ein `preload` im SceneTree-Skript bricht den Lauf vor
`_init()` ab). Der Bericht landet in `user://test-report/report.json`.

### Node-Prüfungen

| Werkzeug | Zweck |
|---|---|
| `tests/verify.cjs` | 140 numerische Referenzprüfungen der Legacy-Engine |
| `tools/check_gdscript.cjs` | statische GDScript-Prüfung (0 Fehler / 0 Warnungen) |
| `tools/export_content.cjs` | Lerninhalt nach `worlds.json` exportieren |
| `tools/generate_reference.cjs` | Referenzwerte aus der Legacy-Engine erzeugen |
| `tools/report_tests.py` | Testprotokoll in lesbare Form bringen |

## CI-Pipeline

`.github/workflows/godot-build.yml` — drei Jobs:

```
test ──▶ export ──▶ release
```

1. **Tests & Headless Import** — Version pinnen, Godot und Templates
   laden, Content regenerieren, statische Prüfung, Legacy-Engine
   (140/140), headless importieren, GDScript-Suite ausführen.
2. **Windows Desktop Build** — Export nach `BwlSlayer-windows-x64`.
3. **GitHub Release** — läuft nur, wenn alles grün ist.

### Versions-Pinning

Die Version steht **ausschließlich** in `.godot-version`:

```
4.7.2-stable
```

Editor-Binary, Export-Templates und Workflow lesen dieselbe Datei.

**Kritisch:** Godot erwartet die Export-Templates unter
`~/.local/share/godot/export_templates/4.7.2.stable/` — mit **Punkt**,
nicht mit `-stable`. Die Workflow normalisiert das:

```bash
GODOT_TEMPLATE_DIR="${GODOT_VERSION/-stable/.stable}"
```

### Zwei weitere Fallstricke, die die Pipeline geprägt haben

- **Ausgabepfad:** Godot interpretiert den Pfad relativ zum Projektordner
  (`--path godot`). `godot/build/...` wurde zu `godot/godot/build/...`.
  Der Pfad wird jetzt absolut angegeben.
- **Parsefehler mit Exitcode 0:** Ein GDScript-Parsefehler beendet Godot
  mit 0. Die CI prüft deshalb **nicht** den Exitcode, sondern die
  Existenz des Testberichts.

### Artefakte

| Artefakt | Inhalt |
|---|---|
| `BwlSlayer-windows-x64` | `.exe`, `.pck`, portables ZIP |
| `test-report` | `report.json` der GDScript-Suite |

## Was lokal nicht prüfbar ist

Die CI läuft headless auf Linux. **Visuelle Tests brauchen einen echten
Windows-Rechner.** Nicht automatisiert prüfbar sind:

- Fenstergröße, Vollbild,任务leiste-Integration
- Mausrad-Zoom, Touchpad-Gesten
- Tastatur-Navigation in allen Panels
- Rendering-Performance auf realer GPU
- DPI-Skalierung auf verschiedenen Displays

Geprüft und automatisiert sind dagegen: Import, Skriptfehler,
Wirtschaftszustände, Speichervorgänge, Export und Artefakt.

## Siehe auch

- `docs/PRODUCT-VISION.md` — wofür das Spiel steht
- `docs/GAME-DESIGN.md` — die Spielregeln
- `docs/TECHNICAL-ROADMAP.md` — Umsetzungsplan
