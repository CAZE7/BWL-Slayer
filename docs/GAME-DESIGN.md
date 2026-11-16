# Spieldesign — BWL Slayer

> Die Regeln, nach denen die Firma läuft. Jede Zahl hier ist im Code
> implementiert und getestet.

## Zeitrechnung

| Größe | Wert | Begründung |
|---|---|---|
| Tage pro Jahr | 360 | Standardisierte Wirtschaftsjahre in der BWL-Lehre |
| Startkapital | 50 000 € | Genug für eine Anlage, zu wenig für zwei |
| Simulationsgeschwindigkeiten | Pause, 1×, 2×, 4×, 8× | Der Spieler soll die Auswirkungen einer Entscheidung abwarten können, ohne auszuleiden |

Die Simulation ist **deterministisch**: gleicher Startzustand und gleiche
Aktionen ⇒ exakt derselbe Ablauf. Kein Zufall in der Wirtschaftsrechnung.

## Der Lieferzyklus einer Maschine

Das ist das Rückgrat des Spiels: Der Spieler muss mitverfolgen, wann
eine bestellte Maschine endlich Produktion bringt.

```
        Bestellung          Transport        Ankunft        Entladen
    ┌───────────────┐   ┌─────────────┐   ┌──────────┐   ┌────────────┐
    │    ORDERED    │──▶│ IN_TRANSIT  │──▶│  ARRIVED │──▶│ UNLOADING  │
    │  Kapital da,  │   │  LKW fährt  │   │  LKW da  │   │ Ware wird  │
    │  keine Kapaz. │   │  zum Werk   │   │          │   │ entladen   │
    └───────────────┘   └─────────────┘   └──────────┘   └────────────┘
                                                                   │
                              ┌────────────────────────────────────┘
                              ▼
                     ┌─────────────────┐      ┌──────────┐
                     │   INSTALLING    │─────▶│  ACTIVE  │
                     │ Aufbau & Montage │      │ Produkt. │
                     └─────────────────┘      └──────────┘
```

| Phase | Dauer | Was passiert | Was der Spieler sieht |
|---|---|---|---|
| ORDERED | 1 Tag | Bestellung ausgelöst | Statusleuchte grau, kein LKW |
| IN_TRANSIT | `Lieferzeit` (3–14 Tage) | LKW fährt über die Hauptstraße | LKW bewegt sich sichtbar |
| ARRIVED | 1 Tag | LKW steht an der Ladezone | LKW hält, dreht zur Maschine |
| UNLOADING | 2 Tage | Ware wird entladen | Statusleuchte orange |
| INSTALLING | `Montagezeit` (2–5 Tage) | Aufbau und Anschluss | Statusleuchte orange |
| ACTIVE | — | Produktion, Kapazität, Kosten | Grüne Leuchte, Auslastungsbalken |

**Wichtig für das Spielgefühl:** Zwischen Bestellung und Inbetriebnahme
fließen bereits Fixkosten der Grundstücke, aber es entsteht noch kein
Deckungsbeitrag. Der Berater weist darauf hin, sobald Maschinen länger
als 60 Tage unterwegs sind.

## Produktion

```
Tageskapazität einer Anlage = Jahreskapazität / 360
```

Die Tagesproduktion wird **auf die offenen Kundenaufträge verteilt**.
Jede Einheit wird genau einmal vergeben:

1. Der älteste offene Auftrag bekommt zuerst.
2. Übersteigt die Tagesproduktion die offene Menge, geht der Rest an den
   nächsten Auftrag.
3. Wird ein Auftrag erfüllt, wird er geliefert — aber **erst**, wenn
   (a) die geforderte Menge tatsächlich produziert **und**
   (b) die Lieferfrist noch nicht abgelaufen ist.

Läuft die Lieferfrist ab, wird der Auftrag **storniert**
(`stats["orders_cancelled"]`) — mit Verlust, weil die Maschinenkapazität
für ihn reserviert war.

### Material

Material wird aus dem Lager verbraucht, nicht „kostenlos produziert“:

```
Materialverbrauch = Tagesproduktion × Materialbedarf je Stück
```

Fehlt Material, läuft die Anlage im Leerlauf. Das ist im Tagesprotokoll
sichtbar („Materialengpass – Anlage im Leerlauf“).

#### Getrennte Materialarten

Jede Anlage verbraucht ihre **eigene Materialart**. Die Förderbandlinie
arbeitet mit Stahl, der Verpackungsautomat mit Verpackungsmaterial.
Ein Bestand ersetzt keinen anderen: Wer Stahl im Lager hat, kann
deshalb keine Verpackung produzieren.

Die Bestände werden getrennt gelagert, getrennt bestellt und getrennt
bewertet. Der Lagerbestand ist damit ein eigener Vermögenswert je
Materialart.

#### Beschaffung mit Vorlauf

Material kommt **nicht sofort**. Eine Bestellung wird bezahlt, die
Ware trifft nach der Lieferzeit ein:

```
Reichweite = Bestand ÷ Tagesbedarf
```

Der Bestand muss immer die Lieferzeit überbrücken. Andernfalls steht
die Anlage still, während die Fixkosten weiterlaufen. Der Berater
warnt, **bevor** es soweit ist.

Zwei Wege stehen dem Spieler offen:

| Weg | Vorteil | Nachteil |
|---|---|---|
| Sofortkauf | Ware ist sofort da, keine Unterbrechung | Bindet sofort Kapital |
| Bestellung mit Vorlauf | Kapital bleibt länger verfügbar | Produktion stoppt, wenn der Bestand nicht reicht |

Die Materiallieferungen gehören zum Spielstand und werden beim Laden
wiederhergestellt.

## Der Jahresabschluss

Der Abschluss ist die Stelle, an der die BWL sichtbar wird. In dieser
Reihenfolge:

| Schritt | Buchung | Cashflow |
|---|---|---|
| Umsätze | `revenue_current_year` | **wirksam** |
| Materialverbrauch | `costs_current_year` | **wirksam** |
| Fixkosten (Personal, Wartung, Verwaltung) | `costs_current_year` | **wirksam** |
| Abschreibung | `costs_current_year` + `fixed_assets` | nicht zahlungswirksam |
| Kalkulatorische Zinsen | `costs_current_year` | nicht zahlungswirksam |
| Zinsaufwand Fremdkapital | `costs_current_year` | **wirksam** |
| Tilgung (10 % p.a., liquiditätsbegrenzt) | `repayment_year` | **wirksam** |

### Bilanzprüfung

```
Aktiva      = Anlagevermögen + Kasse + Forderungen + Lagerbestand
Passiva     = Eigenkapital + Fremdkapital
Bilanzcheck = Aktiva − Passiva
```

Der Bilanzcheck muss null sein. Eine Investition erhöht das
Anlagevermögen und mindert die Kasse — sie ist **keine** laufende Ausgabe.
Deshalb darf eine Maschine nie gleichzeitig zum vollen Preis als Aufwand
und zusätzlich abgeschrieben werden.

### Cashflow

```
Cashflow = Betriebsergebnis + Abschreibung + kalkulatorische Zinsen
```

Der Zinsaufwand auf Fremdkapital wird **nicht** noch einmal abgezogen:
Er steckt bereits im Betriebsergebnis. Ein zweiter Abzug wäre eine
doppelte Belastung. Die Legacy-Engine verwendet dieselbe Formel
(`profitAtX + depreciation + imputedInterest`).

### Kassenlogik: jede Zahlung genau einmal

Der Jahresabschluss darf die Kasse **nicht** über den Cashflow
verändern. Der Umsatz ist bei der Lieferung bereits gutgeschrieben,
das Material beim Einkauf bezahlt, die Fixkosten monatlich abgezogen.
Ein zweiter Abzug wäre eine Doppelbuchung.

| Vorgang | Wann die Kasse sinkt | Wann der Aufwand entsteht |
|---|---|---|
| Umsatz | bei der Lieferung | bei der Lieferung |
| Material | beim Einkauf | beim Verbrauch (Bestand sinkt) |
| Fixkosten | monatlich (Zwölftel) | im Jahresabschluss |
| Abschreibung | nie | im Jahresabschluss |
| Kalk. Zinsen | nie | im Jahresabschluss |
| Zinsaufwand FK | im Jahresabschluss | im Jahresabschluss |
| Tilgung | bei der Tilgung | nie (kein Aufwand) |
| Investition | bei der Bestellung | nie (Aktivierung) |

Der Investitionsbetrag wird **nicht** auf das Betriebskonto gebucht,
sondern ins Anlagevermögen aktiviert. Erst die Abschreibung mindert
das Eigenkapital.

Jede Kassenbewegung läuft über `EconomyState.move_cash()`. Das
Signal `cash_changed` meldet die Bewegung an die UI und den Berater
— so entsteht die Kette **Spielereignis → Simulation → sichtbares
Feedback**.

## Investitionsrechnung

Zusätzlich zur Kostenfunktion werden die dynamischen Verfahren
berechnet — sie entscheiden, ob eine Anlage ihr Kapital verdient:

| Größe | Bedeutung | Formel |
|---|---|---|
| Barwert (NPV) | Wert der Investition heute | `−\|A₀\| + Σ CFₜ·(1+i)⁻ᵗ` |
| Kapitalwert | zulässiger Jahresbeitrag | `NPV · Annuitätsfaktor` |
| Rentabilitätsindex | Ertrag je investiertem Euro | `(NPV + \|A₀\|) / \|A₀\|` |
| Interne Rendite | Zinssatz, bei dem NPV = 0 | numerisch (Bisektion) |

Der Zinssatz `i` ist der **gewichtete Mittelwert** aus Eigen- und
Fremdkapitalzins:

```
i = (1 − Fremdkapitalanteil) · EK-Zins + Fremdkapitalanteil · FK-Zins
```

Der Cashflow der Investitionsrechnung ist **zahlungswirksam**. Er
folgt exakt der Legacy-Engine:

```
Cashflow = Gewinn + Abschreibung + kalkulatorische Zinsen
```

Die kalkulatorischen Zinsen stehen im Gewinn, sind aber nicht
zahlungswirksam — die Addition rechnet sie heraus. Die Abschreibung
ist ebenfalls nicht zahlungswirksam und wird hinzugefügt. Der Restwert
fließt im letzten Jahr ein.

Diese Formel ist Teil der **geschützten Parität** zum Legacy-Engine
und darf nicht verändert werden.

Für die Entscheidung zählt: **Kapitalwert über den jährlichen
Fixkosten** — erst dann verdient die Anlage ihr Kapital.

## Investitionsentscheidung

Der Kern des Spiels. Zwei Anlagen A und B werden über ihre **echten
Kostenfunktionen** verglichen:

```
K(x) = k_var · x + K_fix
K_fix = Fixkosten + (A₀ − L)/n + (A₀ + L)/2 · i
```

- **Unterhalb** der kritischen Menge gewinnt die Anlage mit den
  **niedrigeren** Fixkosten (der Fixkostenblock dominiert: `K = k_var·x + F`).
- **Oberhalb** gewinnt die Anlage mit den **niedrigeren** variablen
  Stückkosten (der Stückpreis dominiert).

In der **Gewinnbetrachtung** `G = db·x − F` gelten die umgekehrten
Regeln für den Fixkostenblock: Unterhalb gewinnt die Anlage mit den
**höheren** Fixkosten, weil ihr Abzug kleiner ist; oberhalb gewinnt
die Anlage mit dem **höheren Deckungsbeitrag**. Die Modi unterscheiden
sich also fachlich — deshalb gibt es zwei Regeln.

Die Empfehlung wird **gegen die tatsächlichen Kurven geprüft**. Stimmt
sie nicht, wird sie gespiegelt — so kann sich kein Vorzeichenfehler in
die Empfehlung einschleichen.

Gleiche variable Stückkosten ⇒ keine kritische Menge. Dann ist die
Fixkostenhöhe die entscheidende Größe, und genau das steht in der
Empfehlung.

## Finanzierung

Fremdkapital ist eine Entscheidung mit echten Folgen, nicht eine
Notlösung:

| Größe | Wirkung |
|---|---|
| Kreditrahmen | richtet sich nach dem Eigenkapital und der Verschuldung |
| Zinssatz | 4 % bei niedriger Verschuldung, 9 % bei hoher (linear) |
| Tilgungsanteil | Spielentscheidung: 0 % bis 100 % des Fremdkapitals p.a. |
| Zinsbelastung | Zinskosten im Verhältnis zum Eigenkapital |

Der Spieler stellt den Tilgungsanteil selbst ein. Wer nicht tilgt,
behält Liquidität für die nächste Investition, zahlt aber mehr
Zinsen. Der Kreditrahmen begrenzt die Verschuldung, damit das Spiel
nicht in eine Schuldenfalle kippt.

Der Berater warnt bei einer Fremdkapitalquote über 50 %, bei einer
Zinsbelastung über 15 % des Eigenkapitals und weist auf einen
ungenutzten Kreditrahmen hin — mit der Frage, ob eine Investition
mehr bringt als der Kreditzins.

## Der Unternehmensberater

Der Berater analysiert den **tatsächlichen** Zustand und liefert elf
Module:

| Modul | Erkennt |
|---|---|
| Auslastung | zu geringe (< 40 %) oder zu hohe (> 92 %) Auslastung |
| Liquidität | kritische Kasse, hohe FK-Quote |
| Kapazität | fehlende Kapazität bei vorhandener Nachfrage |
| Investitionen | unwirtschaftliche Anlagen im Betrieb |
| Aufträge | Aufträge unter Deckungsbeitrag |
| Effizienz | Fixkosten je Stück |
| Lieferkette | Maschinen, die Kapital binden ohne zu produzieren |
| Kapitalbindung | Anlagevermögen je Kapazitätseinheit |
| verlorene Aufträge | Nachfrage, die nicht bedient werden konnte |
| Finanzierung | zu hohe Verschuldung, Zinsbelastung, ungenutzter Kreditrahmen |
| Materialversorgung | je Materialart: Bestand reicht nicht bis zur nächsten Lieferung |

Zusätzlich reagiert der Berater auf **Spielereignisse**: neuer
Kundenauftrag, installierte Maschine, abgeschlossener Auftrag,
Zahlung über 5.000 €. Jedes Ereignis wird erklärt — mit der
wirtschaftlichen Folge, nicht nur dem Faktum.</new_text>

Jeder Hinweis hat fünf Teile: **Analyse** (mit Zahlen aus dem
Betrieb), **Fragen** (die zum Nachdenken führen), **Lektion** (die
fachliche Größe), **Aktion** (wo es weitergeht). Der Berater gibt
**niemals** eine fertige Lösung.

## Lernstufen

Drei Stufen je Welt:

1. **Konzept-Minispiel** — Quiz, Zuordnung (sort), Ordnung (order).
   Jede einzelne Teilaufgabe zählt; die Stufe gilt erst als erledigt,
   wenn **alle** gelöst sind.
2. **Rechen-Labor** — die Originalaufgaben der Vorlesung. Punkte sind der
   Mittelwert über alle Aufgaben.
3. **Endlos-Trainer** — parametrisch, mit den Referenzwerten der
   Legacy-Engine abgeglichen.

### Freischaltung

Eine Welt öffnet sich, wenn die **vorige** Welt abgeschlossen ist. Innerhalb
einer Welt muss jede Stufe bearbeitet sein, bevor die nächste sichtbar
wird.

## Speichern

- Versioniertes Format (aktuell Version 3).
- Migration von Version 1 und 2.
- Atomisches Schreiben mit rotierenden Backups.
- Sanitizing beim Laden: fehlende oder unplausible Werte werden auf
  sinnvolle Defaults gesetzt.

## Siehe auch

- `docs/PRODUCT-VISION.md` — wofür das Spiel steht
- `docs/ARCHITECTURE.md` — wie es gebaut ist
- `docs/TECHNICAL-ROADMAP.md` — was als Nächstes kommt
