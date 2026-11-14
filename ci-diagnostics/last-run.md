# CI-Diagnose

## Testschritt
```
Godot-Binary: /home/runner/godot-bin/godot
Projektverzeichnis: /home/runner/work/BWL-Slayer/BWL-Slayer
total 142992
drwxr-xr-x  2 runner runner      4096 Nov 13 17:53 .
drwxr-x--- 14 runner runner      4096 Nov 13 17:53 ..
-rwxr-xr-x  1 runner runner 146414384 Aug 17 14:49 Godot_v4.7.2-stable_linux.x86_64
lrwxrwxrwx  1 runner runner        55 Nov 13 17:53 godot -> /home/runner/godot-bin/Godot_v4.7.2-stable_linux.x86_64
```

## Testausgabe
```

--- BWL-Engine · Statische Verfahren ---
  OK   Auto A Fixkosten
  OK   Auto B Fixkosten
  OK   x_krit (Hundert-km)
  OK   Kosten A bei 15.000 km
  OK   Kosten B bei 15.000 km
  OK   Kosten A bei 40.000 km
  OK   Kosten B bei 40.000 km
  OK   Abfüllanlage 1 AfA
  OK   Abfüllanlage 1 kalk. Zinsen
  OK   Abfüllanlage 1 Fixkosten
  OK   Abfüllanlage 2 Fixkosten
  OK   x_krit Abfüllanlagen
  OK   Gewinn M1 @15.000
  OK   Rentabilität Abfüllanlage 1
  OK   Rentabilität Abfüllanlage 2
  OK   Kumulation 4,95 Jahre
  OK   Restbetrag nach Jahr 4
  OK   Kumulation Objekt 2

--- BWL-Engine · Dynamische Verfahren ---
  OK   Werkzeug I df(10%,2)
  OK   Werkzeug II rbf(10%,10)
  OK   Werkzeug III anf(10%,10)
  OK   Kapitalwert
  OK   Annuität
  OK   Rbf(4 %, 4 J.)
  OK   PI Projekt 1
  OK   PI Projekt 2
  OK   PI Projekt 3
  OK   PI Projekt 4
  OK   PI Projekt 5
  OK   Sekante i*
  OK   IRR vorhanden
  OK   IRR
  OK   IRR Einzelzahlung
  OK   IRR ewige Rente
  OK   Renten-IRR Struktur
  OK   Renten-IRR Näherung
  OK   Rbf = A0/CF
  OK   IRR ewige Rente 75.000/6.000

--- BWL-Engine · Anleihen & Duration ---
  OK   Hamburg AG PV @2 % (3 J.)
  OK   Hamburg AG PV @5 % (3 J.)
  OK   YTM 4 %-Anleihe @98, y=4 %
  OK   Spot Rate 1 J.
  OK   Spot Rate 2 J.
  OK   Spot Rate 3 J.
  OK   Barwert 4 J. 5 % @5,5 %
  OK   Macauley Duration
  OK   Modified Duration
  OK   Portfolioduration

--- BWL-Engine · Finanzierung ---
  OK   Lohmann-Ruchti 7 Zeilen
  OK   Jahr 1: 10 Maschinen aktiv
  OK   Kassenreste bleiben positiv
  OK   Mischkurs Level 1
  OK   Bezugsrechtswert Level 1
  OK   Dividendennachteil
  OK   Bezugsrechtswert Level 2
  OK   XY AG Mischkurs
  OK   XY AG Bezugsrecht
  OK   Medizin AG Mischkurs
  OK   Medizin AG Bezugsrecht
  OK   Medizin AG Kapitalerhöhung (Mio.)
  OK   Medizin AG Agio (Mio.)
  OK   Skontozins
  OK   Leasing < 40 % → Nehmer
  OK   Leasing 40–90 % ohne Option → Geber
  OK   Spezial-Leasing → immer Nehmer
  OK   Leverage EK-Rentabilität
  OK   Leverage Reingewinn
  OK   Leverage Variante 2
  OK   Annuität
  OK   Kapitalbindungsdauer
  OK   Kapitalbedarf

--- BWL-Engine · Aktienbewertung ---

--- BWL-Engine · Grenzwerte ---
  OK   AfA bei n=0
  OK   rbf bei i=0
  OK   anf bei i=0
  OK   df mit negativem i
  OK   IRR ohne Vorzeichenwechsel = null
  OK   Gordon ungültig
  OK   x_krit bei gleicher k_var = NaN
  OK   Break-even ohne DB
  OK   Skonto mit target=skonto = NaN

--- Engine-Parität · GDScript vs. JavaScript-Original ---
  OK   Referenzwerte vorhanden
  OK   auto_a_fixkosten
  OK   auto_b_fixkosten
  OK   auto_xkrit
  OK   auto_a_kosten_15000km
  OK   auto_b_kosten_15000km
  OK   auto_a_kosten_40000km
  OK   auto_b_kosten_40000km
  OK   abfuell_afa_1
  OK   abfuell_zinsen_1
  OK   abfuell_fixkosten_1
  OK   abfuell_fixkosten_2
  OK   abfuell_xkrit
  OK   abfuell_rentabilitaet_1
  OK   abfuell_kumulation_jahre
  OK   df_10_2
  OK   rbf_10_10
  OK   anf_10_10
  OK   kapitalwert
  OK   annuitaet
  OK   pi_kapitalwert
  OK   pi_barwert
  OK   sekante_i
  OK   irr_bisektion
  OK   irr_einzahlung
  OK   irr_ewige_rente
  OK   renten_irr_approx
  OK   bond_barwert
  OK   kassazinssatz
  OK   macauley_duration
  OK   modified_duration
  OK   portfolioduration
  OK   lr_rest_jahr1
  OK   lr_gekauft_jahr7
  OK   lr_aktiv_jahr7
  OK   bezugsrechtswert
  OK   mischkurs
  OK   kapitalerhoehung
  OK   agio
  OK   skontozins
  OK   leverage_roe
  OK   leverage_gewinn
  OK   leverage2_roe
  OK   annuitaet_plan
  OK   kapitalbindungsdauer
  OK   kapitalbedarf
  OK   eps
  OK   kgv
  OK   dividendenrendite_prozent
  OK   barwert_dividenden
  OK   fairer_wert_mit_verkauf
  OK   gordon_p0
  OK   implizites_wachstum_prozent
  OK   capm_prozent
  OK   capm_gordon
  OK   zweiphasen_d3
  OK   zweiphasen_terminal
  OK   zweiphasen_wert
  OK   nachhaltiges_wachstum_prozent
  OK   bewertung_kgv_multiple
  OK   gesamtrendite_prozent

--- Simulation · Kostenarten-Trennung ---
  OK   AfA linear
  OK   Durchschnittlich gebundenes Kapital
  OK   Kalkulatorische Zinsen
  OK   K_fix gesamt
  OK   Zahlungswirksam nur Fixkosten
  OK   Gewinn bei x=1000
  OK   Cashflow = Gewinn + AfA + kalk.Z
  OK   Anschaffungspreis nicht in Fixkosten
  OK   Break-even Menge

--- Simulation · Maschinen-Lebenszyklus ---
  OK   Neu: ORDERED
  OK   Restbuchwert = Anschaffung
  OK   AfA im Betriebsjahr 1
  OK   Kalk. Zinsen auf Restbuchwert
  OK   Alterung: Jahr 1 -> 2
  OK   Restbuchwert nach Jahr 1
  OK   Produktionshistorie geführt
  OK   Abschreibung im letzten Jahr
  OK   Nach Nutzungsdauer außer Betrieb
  OK   Roundtrip Restbuchwert
  OK   Roundtrip Produktion
  OK   Roundtrip Zustand

--- Simulation · Wirtschaftliche Kennzahlen ---
  OK   Betriebsergebnis
  OK   Cashflow
  OK   Fremdkapitalquote
  OK   Liquidität gesund
  OK   FK-Quote korrekt
  OK   EK-Rentabilität %

--- Simulation · Liquidität & Krisen ---
  OK   Tense bei niedriger Liquidität
  OK   Begründung vorhanden
  OK   Critical bei überzogener Kasse
  OK   Krisenbegründung
  OK   Liquiditätsgrad II

--- Persistenz · Versionierung & Migration ---
  OK   Migration: Kapital übernommen
  OK   Migration: XP initialisiert
  OK   Migration: Welten erhalten
  OK   Migration: Stufe 1 erhalten
  OK   Migration: Version gesetzt
  OK   Migration v2: XP
  OK   Migration v2: Reputation
  OK   Migration v2: Kapital
  OK   Aktuelle Version: XP
  OK   Aktuelle Version: Reputation

--- Persistenz · Sanitisierung ---
  OK   Sanitize: XP numerisch
  OK   Sanitize: Reputation begrenzt
  OK   Sanitize: Kapital numerisch
  OK   Sanitize: Schulden nicht negativ

--- Persistenz · Dateioperationen ---
  OK   Spielstand geschrieben
  OK   Spielstand geladen
  OK   Roundtrip: Kapital
  OK   Roundtrip: XP
  OK   Roundtrip: Name
  OK   Backup angelegt
  OK   Backup wiederhergestellt
  OK   Traversal abgewiesen
  OK   Fehlender Spielstand = null
  OK   Spielstände gelistet
  OK   Spielstand gelöscht

--- Lernen · Content-Vollständigkeit ---
  OK   9 Welten vorhanden
  OK   W1: 3 Stufen
  OK   W1: Briefing vorhanden
  OK   W1: Quelle dokumentiert
  OK   W2: 3 Stufen
  OK   W2: Briefing vorhanden
  OK   W2: Quelle dokumentiert
  OK   W3: 3 Stufen
  OK   W3: Briefing vorhanden
  OK   W3: Quelle dokumentiert
  OK   W4: 3 Stufen
  OK   W4: Briefing vorhanden
  OK   W4: Quelle dokumentiert
  OK   W5: 3 Stufen
  OK   W5: Briefing vorhanden
  OK   W5: Quelle dokumentiert
  OK   W6: 3 Stufen
  OK   W6: Briefing vorhanden
  OK   W6: Quelle dokumentiert
  OK   W7: 3 Stufen
  OK   W7: Briefing vorhanden
  OK   W7: Quelle dokumentiert
  OK   W8: 3 Stufen
  OK   W8: Briefing vorhanden
  OK   W8: Quelle dokumentiert
  OK   W9: 3 Stufen
  OK   W9: Briefing vorhanden
  OK   W9: Quelle dokumentiert
  OK   Welt 1 hat ID W1
  OK   Welt 2 hat ID W2
  OK   Welt 3 hat ID W3
  OK   Welt 4 hat ID W4
  OK   Welt 5 hat ID W5
  OK   Welt 6 hat ID W6
  OK   Welt 7 hat ID W7
  OK   Welt 8 hat ID W8
  OK   Welt 9 hat ID W9
  OK   5 Investitionswelten
  OK   4 Finanzierungswelten
  OK   Originalaufgaben vorhanden
  OK   W1: mindestens 2 Quizfragen
  OK   W2: mindestens 2 Quizfragen
  OK   W3: mindestens 2 Quizfragen
  OK   W4: mindestens 2 Quizfragen
  OK   W5: mindestens 2 Quizfragen
  OK   W6: mindestens 2 Quizfragen
  OK   W7: mindestens 2 Quizfragen
  OK   W8: mindestens 2 Quizfragen
  OK   W9: mindestens 2 Quizfragen
  OK   W1: Trainer vorhanden
  OK   W2: Trainer vorhanden
  OK   W3: Trainer vorhanden
  OK   W4: Trainer vorhanden
  OK   W5: Trainer vorhanden
  OK   W6: Trainer vorhanden
  OK   W7: Trainer vorhanden
  OK   W8: Trainer vorhanden
  OK   W9: Trainer vorhanden

--- Lernen · Aufgabenlogik ---
  OK   W2 geladen
  OK   Aufgabe hat Felder
  OK   Feld fixa hat Musterlösung
  OK   Feld fixa hat Toleranz
  OK   Feld fixb hat Musterlösung
  OK   Feld fixb hat Toleranz
  OK   Feld xkrit hat Musterlösung
  OK   Feld xkrit hat Toleranz
  OK   Feld kost15 hat Musterlösung
  OK   Feld kost15 hat Toleranz
  OK   x_krit Originalaufgabe
  OK   Klausurfallen dokumentiert
  OK   Relative Toleranz erkannt
  OK   Absolute Toleranz erkannt

--- Lernen · Fortschritt & Freischaltung ---
  OK   Erste Belohnung
  OK   Keine Doppelbelohnung
  OK   XP bleibt einmalig
  OK   W2 nach W1 freigeschaltet
  OK   W3 gesperrt
  OK   W3 nach W1 gesperrt
  OK   W3 nach W2 frei
  FAIL Höherer Punktwert zählt – ist false | erwartet true
  FAIL Niedrigerer Punktwert überschreibt nicht – ist false | erwartet true
  OK   Roundtrip XP
  OK   Roundtrip Weltenfortschritt

========================================
ERGEBNIS: 279 bestanden, 2 fehlgeschlagen
========================================

Fehlgeschlagene Prüfungen:
  Lernen · Fortschritt & Freischaltung ::   FAIL Höherer Punktwert zählt – ist false | erwartet true
  Lernen · Fortschritt & Freischaltung ::   FAIL Niedrigerer Punktwert überschreibt nicht – ist false | erwartet true
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         
2 Pruefungen fehlgeschlagen.
```

## Testbericht
```
{
  "failed": 2,
  "failures": [
    "Lernen · Fortschritt & Freischaltung ::   FAIL Höherer Punktwert zählt – ist false | erwartet true",
    "Lernen · Fortschritt & Freischaltung ::   FAIL Niedrigerer Punktwert überschreibt nicht – ist false | erwartet true"
  ],
  "passed": 279,
  "timestamp": "2026-11-13T17:54:01",
  "total": 281
}```
