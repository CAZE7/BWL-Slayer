# Produktvision — BWL Slayer

> Ein eigenständiges, lokal spielbares Unternehmenssimulation unter Windows.
> Kein Lernportal mit Fabrikbildern, sondern eine Firma, die man führen muss.

## Der eine Satz

BWL Slayer ist eine **industrielle Unternehmenssimulation**, in der der
Spieler eine Produktions- und Servicegesellschaft führt und dabei BWL
gelebt statt gelernt bekommt.

## Warum das kein Lernportal ist

Der entscheidende Unterschied liegt nicht in der Oberfläche, sondern in der
Kausalkette:

| Lernportal | BWL Slayer |
|---|---|
| Frage → Antwort → Feedback | Problem → Entscheidung → Konsequenz |
| Zahlen sind Beispiele | Zahlen sind dein Betriebsergebnis |
| „Was ist der Break-even?" | „Deine Anlage B kostet 6 445 € Fixkosten. Bei 8 000 Stück ist sie schlechter." |
| Feedback nach dem Klick | Der Markt reagiert: kein Auftrag, keine Liquidität, Bankenruckzahlung |

Alles, was der Spieler lernt, erscheint zuerst als **Handlungsdruck**. Die
BWL-Größe wird zum Werkzeug, das die Handlung trägt — nicht zum Prüfungsstoff.

## Die drei Kernschleifen

### 1. Wirtschaftsschleife (Tag / Woche / Jahr)

```
Kundenauftrag annehmen
      ↓
Tagesproduktion verteilen (Kapazität, Material, Auslastung)
      ↓
Lieferung, Erlös, Zahlungsziel
      ↓
Materialverbrauch, Fixkosten, Abschreibung, Zinsen
      ↓
Jahresabschluss: GuV, Bilanz, Cashflow
```

Jeder Zyklus schließt sich am echten Kontostand. Es gibt keine dekorativen
Zahlen.

### 2. Investitionsschleife

```
Kapazitätslücke entdeckt (zu hohe Auslastung, abgewiesene Aufträge)
      ↓
Maschinenvergleich A gegen B (echte Kostenfunktionen)
      ↓
Kritische Menge bestimmen (Schnittpunkt der Kurven)
      ↓
Bestellen → Kapital ist gebunden, noch keine Kapazität
      ↓
Lieferkette: Transport → Entladen → Montage → Inbetriebnahme
      ↓
Fixkostenblock steigt, Stückkosten sinkt → Auslastung muss nachziehen
```

Der Spieler **lebt** mit der Entscheidung: Der Fixkostenblock ist jetzt
da, egal ob die Nachfrage kommt.

### 3. Finanzierungsschleife

```
Liquidität wird knapp (Investition, Lohn, Zins)
      ↓
Fremdkapital aufnehmen oder Eigenkapital mobilisieren
      ↓
Zinsaufwand und Tilgung belasten das Ergebnis
      ↓
Kalkulatorische Zinsen auf das gebundene Kapital als Entscheidungsgröße
```

## Der Ton: Unternehmenssoftware, nicht Spielzeug

Die Oberfläche ist bewusst nüchtern. Sie sieht aus wie ein
Produktions- und Controlling-System, nicht wie ein Mobilspiel:

- Anthrazit, Graphit, Stahlgrau, Off-White
- Blau als einziger Akzent für Auswahl und aktive Elemente
- Grün ausschließlich für positive Zustände
- Orange und Rot ausschließlich für Warnungen
- Kein Gold, kein Neon, keine XP-Balken, keine Comic-Effekte

## Was ausdrücklich nicht gebaut wird

- **Keine Karriere-Ränge.** Kein Junior-Analyst-zum-CFO, keine Skill-Baum,
  keine XP-Niveaus. Fortschritt ist **Unternehmensentwicklung**: neue
  Maschinen, größere Kapazität, weitere Standorte, neue Verträge, komplexere
  Produktionsketten, mehr Verantwortung.
- **Keine Quest-Marker.** Kein „+50 EP für Auftrag 3".
- **Keine Zufallsereignisse ohne Grund.** Wenn etwas passiert, folgt es
  einer definierten Regel (Nachfrage, Lieferzeit, Zahlungsziel).
- **Kein Quiz-Druck.** Es gibt Aufgaben — aber sie verlangen eine
  Handlung oder eine Rechnung an echten Betriebsdaten.

## Zielgruppe

Studierende der Betriebswirtschaftslehre an Hochschulen und
Wirtschaftsfachschulen, sowie Berufstätige, die ihre BWL-Kenntnisse
an einem laufenden Betrieb prüfen wollen. Beide brauchen dieselbe
Eigenschaft: **Feedback muss aus dem Spiel kommen, nicht aus dem Tutor.**

## Erfolgskriterien

1. Der Spieler kann nach 30 Minuten eine Investitionsentscheidung
   **begründen** — mit Zahlen aus seinem eigenen Betrieb.
2. Er versteht die kritische Menge nicht als Formel, sondern als
   *„ab hier lohnt sich B"*.
3. Er sieht einen abgewiesenen Auftrag und versteht sofort, dass seine
   Fixkosten ihn töten.
4. Kein Lerninhalt der Vorlesung geht verloren: alle 9 Welten, 42
   Originalaufgaben, 38 Quizfragen, 12 Zuordnungsrunden und
   4 Ordnungsaufgaben sind vollständig und spielbar.

## Siehe auch

- `docs/GAME-DESIGN.md` — Spielmechanik und Regeln
- `docs/ARCHITECTURE.md` — technische Struktur
- `docs/TECHNICAL-ROADMAP.md` — Umsetzungsplan und Status
