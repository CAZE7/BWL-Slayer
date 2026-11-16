# Windows-Abnahme

Der Runner baut das Spiel headless auf Linux. **Was nur ein echter
Windows-Rechner prüfen kann, steht hier.** Die Liste ist so
geschrieben, dass sie ohne Kenntnis des Quellcodes abgearbeitet werden
kann.

## 1. Start und Installation

- [ ] Die ZIP-Datei aus dem Artefakt `BwlSlayer-windows-x64` entpacken.
- [ ] `BwlSlayer.exe` per Doppelklick starten — keine Installations-
      schritte, keine Administratorrechte, kein Framework nötig.
- [ ] Es erscheint kein Fehlerdialog und keine Konsolenfenster.
- [ ] Das Spiel startet **ohne Internetverbindung** (Netzwerkadapter
      deaktivieren und neu starten).
- [ ] Der Ton ist stumm, die Oberfläche zeigt die Fabrik.

## 2. Fenster und Auflösung

- [ ] Das Fenster lässt sich in die Breite und Höhe ziehen.
- [ ] Die Seitenleiste behält ihre Breite; die Fabrik wird breiter,
      nicht die Seitenleiste.
- [ ] Bei 125 % und 150 % Windows-Skalierung sind **keine** Texte
      abgeschnitten und keine Bedienelemente überlappend.
- [ ] Das Fenster lässt sich auf einen zweiten Monitor ziehen und
      wieder zurück; die Kamera bleibt steuerbar.
- [ ] Minimieren und Wiederherstellen verursachen keinen Absturz und
      lassen die Simulation angehalten.

## 3. Kamera

- [ ] Mausrad über der Fabrik zoomt (nicht über der Seitenleiste).
- [ ] Ziehen mit gedrückter Maustaste verschiebt die Kamera.
- [ ] `+` und `−` auf der Tastatur zoomen ebenfalls.
- [ ] `R` setzt die Kamera zurück, `F` zentriert sie auf das Werk.
- [ ] Die Maschinen bleiben beim Zoomen scharf (kein Pixel-Flimmern).

## 4. Tastaturbedienung

Alles muss ohne Maus erreichbar sein. `Tab` bewegt den Fokus.

- [ ] `Tab` / `Shift+Tab` durchlaufen alle Bedienelemente der
      Seitenleiste.
- [ ] `Leertaste` hält die Simulation an, `Shift+Leertaste` startet
      sie wieder.
- [ ] `1` bis `5` stellen die Geschwindigkeit (Pause bis 5×) ein.
- [ ] `Alt+1` bis `Alt+8` wechseln die Bereiche (Fabrik, Logistik,
      Produktion, Finanzen, Statistik, Berater, Investition, Labor).
- [ ] `Esc` schließt das BWL-Labor.
- [ ] `Strg+S` speichert, `Strg+O` lädt.
- [ ] In Texteingabefelder (Spielername) lösen die Tastenkürzel
      **nicht** aus, sondern schreiben normal.

## 5. Wirtschaftlicher Ablauf (der eigentliche Test)

Ein neues Spiel starten und durchspielen:

- [ ] Das Werk startet mit **einer** aktiven Maschine und 50.000 €
      Kasse.
- [ ] Material kaufen: die Kasse sinkt sofort um den Betrag, der
      Bestand steigt, und die Anzeige „Reichweite" steigt.
- [ ] Material mit Vorlauf bestellen: die Kasse sinkt sofort, der
      Bestand **noch nicht** — aber „auf dem Weg" steigt, und nach
      fünf Tagen ist die Ware im Lager.
- [ ] Ist zu wenig Material da, stoppt die Anlage und der Berater
      warnt **vorher**.
- [ ] Eine Maschine bestellen: die Kasse sinkt sofort um den
      Anschaffungswert, im Inventar steht „Anschaffung" und daneben
      „Abschreibung" — **nicht** beides als Aufwand.
- [ ] Der Lastwagen fährt tatsächlich auf das Gelände, entlädt und
      die Maschine wird installiert.
- [ ] Erst **nach** der Installation steigt die Kapazität, und
      Kundenaufträge kommen von selbst.
- [ ] Der Finanzbereich zeigt GuV und Bilanz, und der
      Bilanzcheck steht auf **0,00 €**.
- [ ] Der Berater nennt konkrete Zahlen aus dem laufenden Betrieb und
      stellt Fragen — er verrät keine fertigen Lösungen.

## 6. Speichern und Laden

- [ ] `Strg+S` speichert, es erscheint eine Bestätigung.
- [ ] Das Spiel schließen und neu starten, dann `Strg+O`: Kasse,
      Tag, Maschinen, Aufträge und Lernfortschritt sind wieder da.
- [ ] „Neues Spiel" setzt alles zurück: 50.000 €, Tag 1, eine
      Maschine, keine Aufträge, kein gelernter Fortschritt.
- [ ] Ein Speicherstand lässt sich **nicht** überschreiben, ohne
      dass gefragt wird.

## 7. Lernen ohne Absturz

- [ ] Alle 9 Welten sind erreichbar; jede Welt hat 3 Stufen.
- [ ] Sortier-, Ordnungs- und Quizaufgaben lassen sich vollständig
      bearbeiten.
- [ ] Eine Stufe gilt erst als abgeschlossen, wenn **alle**
      Teilaufgaben gelöst sind.
- [ ] Das Labor lässt sich mit `Esc` schließen, ohne den
      Spielzustand zu verlieren.

## 8. Stabilität

- [ ] 30 Minuten Simulation bei 5× Geschwindigkeit ohne Absturz.
- [ ] Fenster während der Simulation vergrößern und verkleinern.
- [ ] Das Spiel 20 Mal starten und schließen — keine Reste im
      Task-Manager, keine wachsende Speicherbelegung.

## Was die CI bereits geprüft hat

Diese Punkte sind **nicht** manuell zu prüfen, sie laufen bei jedem
Build:

- Import ohne Skriptfehler (headless, Godot 4.7.2-stable)
- 500+ Wirtschafts-, Persistenz- und Lerntests
- Parität zum geschützten JavaScript-BWL-Engine (60 Referenzwerte)
- Export der Windows-Version, Artefakt-Upload

## Melden

Wenn ein Punkt nicht funktioniert, hilft die Angabe von:

1. Windows-Version und Bildschirmauflösung
2. Skalierung (100 / 125 / 150 %)
3. Grafikkarte und Treiber
4. Inhalt von `user://` → `BWL Slayer`-Logdatei (falls vorhanden)
