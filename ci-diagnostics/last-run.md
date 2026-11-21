# CI-Diagnose

## Testschritt
```
Godot-Binary: /home/runner/godot-bin/godot
Projektverzeichnis: /home/runner/work/BWL-Slayer/BWL-Slayer
total 142996
drwxr-xr-x  2 runner runner      4096 Nov 21 12:19 .
drwxr-x--- 14 runner runner      4096 Nov 21 12:20 ..
-rwxr-xr-x  1 runner runner 146414384 Aug 17 14:49 Godot_v4.7.2-stable_linux.x86_64
lrwxrwxrwx  1 runner runner        55 Nov 21 12:19 godot -> /home/runner/godot-bin/Godot_v4.7.2-stable_linux.x86_64
```

## Testausgabe (Prozess)
```
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

RUN-TESTS: _ready() erreicht (Szenenlauf mit Autoloads)
RUN-TESTS: Logdatei: true
RUN-TESTS: Framework bereit
RUN-TESTS: Suite startet: res://tests/test_bwl_engine.gd

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
  OK   EPS
  OK   KGV
  OK   Dividendenrendite %
  OK   BW explizite Dividenden
  OK   Fairer Wert inkl. Verkauf
  OK   Gordon P0
  OK   Gordon bei r<=g
  OK   Implizites Wachstum %
  OK   CAPM %
  OK   CAPM-Gordon
  OK   Zweiphasen-Modell
  OK   Zweiphasen D3
  OK   Zweiphasen Terminal Value
  OK   Zweiphasen Wert heute
  OK   Nachhaltiges Wachstum %
  OK   Bewertung über KGV
  OK   Gesamtrendite %

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

--- BWL-Engine · Zahlformatierung ---
  OK   format_number gruppiert Tausender
  OK   format_number: fuenf Stellen
  OK   format_number: unter Tausend ohne Punkt
  OK   format_number: Dezimalkomma
  OK   format_eur: Betrag mit Einheit
  OK   format_eur: negativer Betrag
  OK   format_eur: kein Minus bei gerundeter Null
RUN-TESTS: Suite fertig: res://tests/test_bwl_engine.gd
RUN-TESTS: Suite startet: res://tests/test_engine_parity.gd

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
RUN-TESTS: Suite fertig: res://tests/test_engine_parity.gd
RUN-TESTS: Suite startet: res://tests/test_simulation.gd

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
  OK   Operativer Cashflow
  OK   Zinsaufwand nicht doppelt belastet
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

--- Simulation · Investitionsrechnung ---
  OK   Effektivzins korrekt gewichtet
  OK   Cashflow entspricht der Legacy-Definition
  OK   Zwei Anlagen ausgewertet
  OK   Barwert stimmt mit der Engine ueberein
  OK   Barwert stimmt mit der Handrechnung ueberein
  OK   Kapitalwert ist die Annuität zum Barwert
  OK   Rentabilitaetsindex ueber 1 bei positivem Barwert
  OK   Interne Rendite positiv
  OK   Interne Rendite ueber dem Diskontsatz
  OK   Verlustanlage hat negativen Barwert
  OK   Verlustanlage hat negativen Kapitalwert
  OK   Verlustanlage hat Index unter 1

--- Simulation · Finanzierung ---
  OK   EK-Quote startet bei 100 %
  OK   FK-Quote startet bei 0 %
  OK   Kreditrahmen vorhanden
  OK   Kreditrahmen entspricht dem Eigenkapital
  OK   Kredit aufgenommen
  OK   Kasse steigt um den Kreditbetrag
  OK   Fremdkapital steigt
  OK   Bilanz stimmt nach Kredit
  OK   FK-Quote korrekt
  OK   Zinssatz richtet sich nach der Bonitaet
  OK   Ueberziehung wird abgelehnt
  OK   Abgelehnter Kredit veraendert die Kasse nicht
  OK   Tilgung moeglich
  OK   Kasse sinkt um den Tilgungsbetrag
  OK   Fremdkapital sinkt um den Tilgungsbetrag
  OK   Bilanz stimmt nach Tilgung
  OK   Ungueltiger Tilgungsanteil abgelehnt
  OK   Tilgungsanteil unveraendert
  OK   Ohne Automatik wird nicht getilgt
  OK   Zinsbelastung berechenbar
  OK   Finanzierungskosten = Zinsen + Tilgung

--- Simulation · Tilgungspläne ---
  OK   Annuitaetendarlehen aufgenommen
  OK   Fremdkapital = Darlehenssumme
  OK   Restschuld der Darlehen
  OK   Jahr 1: Zins nach Plan
  OK   Jahr 1: Tilgung nach Plan
  OK   Jahr 1: Restschuld nach Plan
  OK   Bilanz stimmt nach Schuldendienst
  OK   Jahr 2: Zins sinkt nach Plan
  OK   Jahr 2: Restschuld nach Plan
  OK   Tilgungsanteil steigt von Jahr zu Jahr
  OK   Nach Laufzeitende schuldenfrei
  OK   Darlehen aus der Liste entfernt
  OK   Ratendarlehen: Tilgung Jahr 1
  OK   Ratendarlehen: Zins Jahr 1
  OK   Ratendarlehen: Tilgung Jahr 2 konstant
  OK   Ratendarlehen: Zins Jahr 2 sinkt
  OK   Endfaellig: keine Tilgung im Jahr 1
  OK   Endfaellig: Zins Jahr 1
  OK   Endfaellig: Restschuld unveraendert
  OK   Endfaellig: volle Tilgung am Ende
  OK   Endfaellig: Darlehen abgeschlossen
  OK   Unbekannte Darlehensform abgelehnt
  OK   Laufzeit unter 1 Jahr abgelehnt
  OK   Darlehen ueberlebt den Spielstand
  OK   Darlehensliste wiederhergestellt

--- Simulation · Dividendenpolitik ---
  OK   Ausschuettungsquote gesetzt
  OK   Quote ueber 100 % abgelehnt
  OK   Quote unveraendert nach Ablehnung
  OK   Dividende = Quote x Ueberschuss
  OK   Eigenkapital: Gewinn minus Ausschuettung
  OK   Bilanz stimmt nach Dividende
  OK   Verlustjahr: keine Dividende
  OK   Quote im Spielstand

--- Simulation · Finanzplan & Aktienbewertung ---
  OK   Finanzplan: Tageskosten
  OK   Finanzplan: Kapitalbindungsdauer
  OK   Finanzplan: Kapitalbedarf = Dauer x Tageskosten
  OK   Finanzplan: Fixkosten als Auszahlung
  OK   Finanzplan: Darlehenszins
  OK   Finanzplan: Darlehenstilgung
  OK   Bewertung: Ergebnis je Aktie
  OK   Bewertung: Buchwert je Aktie
  OK   Bewertung: Dividende je Aktie
  OK   Bewertung: nachhaltiges Wachstum
  OK   Bewertung: CAPM-Kapitalkosten
  OK   Bewertung: Gordon-Wert
  OK   Lohmann-Ruchti: Ausblick vorhanden
  OK   Lohmann-Ruchti: Anlagenzahl erkannt
  OK   Lohmann-Ruchti: 7 Jahreszeilen
  OK   Lohmann-Ruchti: AfA-Parität mit der Engine
  OK   Lohmann-Ruchti: ohne Anlagen abgelehnt

--- Simulation · Kapitalerhöhung & Bezugsrecht ---
  OK   Startkurs = Buchwert je Aktie
  OK   1.000 Aktien zu Beginn
  OK   Kapitalerhoehung durchgefuehrt
  OK   250 junge Aktien
  OK   Zufluss 10.000
  OK   Kasse steigt um den Zufluss
  OK   Eigenkapital steigt um den Zufluss
  OK   1.250 Aktien danach
  OK   Bilanz stimmt nach Kapitalerhoehung
  OK   Mischkurs 48
  OK   Bezugsrecht 2
  OK   Paritaet: Bezugsrechtswert
  OK   Paritaet: Mischkurs
  OK   Kurs nach Erhoehung = Mischkurs
  OK   Ausgabekurs ueber Kurs abgelehnt
  OK   Bezugsverhaeltnis unter 1:1 abgelehnt
  OK   Abgelehnte Erhoehung veraendert nichts
  OK   Aktienzahl im Spielstand
RUN-TESTS: Suite fertig: res://tests/test_simulation.gd
RUN-TESTS: Suite startet: res://tests/test_factory_grid.gd

--- Gelaende · Belegung ---
  OK   Gebaeude belegt
  OK   Zelle (5,9) belegt
  OK   Zelle (5,9) gehoert zum Gebaeude
  OK   Zelle (6,9) belegt
  OK   Zelle (6,9) gehoert zum Gebaeude
  OK   Zelle (7,9) belegt
  OK   Zelle (7,9) gehoert zum Gebaeude
  OK   Zelle (5,10) belegt
  OK   Zelle (5,10) gehoert zum Gebaeude
  OK   Zelle (6,10) belegt
  OK   Zelle (6,10) gehoert zum Gebaeude
  OK   Zelle (7,10) belegt
  OK   Zelle (7,10) gehoert zum Gebaeude
  OK   Keine Zelle links vom Gebaeude belegt
  OK   Keine Zelle unter dem Gebaeude belegt
  OK   Keine Zelle rechts daneben belegt
  OK   Ueberlappung wird erkannt
  OK   Ueberlappung wird abgelehnt
  OK   Direkt angrenzende Flaeche ist frei
  OK   Angrenzendes Gebaeude passt
  OK   Nach Freigabe wieder frei
  OK   Freigabe loescht genau die eigenen Zellen
  OK   Freigabe laesst fremde Zellen unberuehrt
  OK   Rand links wird abgelehnt
  OK   Rand rechts wird abgelehnt
  OK   Rand unten wird abgelehnt

--- Gelaende · Zonen und Suche ---
  OK   Zone gesetzt
  OK   Ausserhalb der Zone bleibt Gruen
  OK   Freie Stelle gefunden
  OK   Gefundene Stelle liegt in der Zone
  OK   Gefundene Stelle ist frei
  OK   Belegung mit der gefundenen Stelle
  OK   Zweite Stelle weicht aus
  OK   Koordinaten-Umrechnung stimmt
RUN-TESTS: Suite fertig: res://tests/test_factory_grid.gd
RUN-TESTS: Suite startet: res://tests/test_operations.gd

--- Ablauf · Maschinen-Lieferkette ---
  OK   Start: ORDERED
  OK   ORDERED -> IN_TRANSIT erlaubt
  OK   IN_TRANSIT -> ARRIVED erlaubt
  OK   ARRIVED -> UNLOADING erlaubt
  OK   UNLOADING -> INSTALLING erlaubt
  OK   INSTALLING -> ACTIVE erlaubt
  OK   Sprung ORDERED -> ACTIVE verboten
  OK   Sprung IN_TRANSIT -> INSTALLING verboten
  OK   Rueckwaertswechsel verboten
  OK   Nach Schritt 1: IN_TRANSIT
  OK   Lieferzeit gesetzt
  OK   Nach Schritt 2: ARRIVED
  OK   Entladezeit gesetzt
  OK   Nach Schritt 3: UNLOADING
  OK   Nach Schritt 4: INSTALLING
  OK   Montagezeit gesetzt
  OK   Nach Schritt 5: ACTIVE
  OK   Maschine betriebsbereit
  OK   Aus ACTIVE kein weiterer Schritt
  OK   Label fuer UNLOADING vorhanden
  OK   Testfall: steht in UNLOADING
  OK   Save-Roundtrip: Zustand erhalten
  OK   Save-Roundtrip: Restzeit erhalten

--- Ablauf · Produktion & Material ---
  OK   Ohne Auftrag keine Produktion
  OK   Ohne Produktion keine variablen Kosten
  OK   Ohne Material keine Produktion
  OK   Tagesproduktion
  OK   Materialverbrauch gebucht
  OK   Variable Kosten zahlungswirksam
  OK   Materialengpass stoppt die Produktion
  OK   Engpass vermerkt

--- Ablauf · Kundenaufträge ---
  OK   Auftrag bei Fristablauf storniert
  OK   Nicht als erfuellt gewertet
  OK   Gefertigte Ware faellt in den Bestand zurueck
  OK   Auftrag bei ausreichender Produktion erfuellt
  OK   Erlos gebucht
  OK   Kasse erhoeht
  OK   Eigenkapital entspricht dem Ergebnis

--- Ablauf · Investitionsentscheidung ---
  OK   Kritische Menge berechenbar
  OK   Kritische Menge positiv
  OK   Unterhalb gewinnt die Anlage mit den niedrigeren Fixkosten
  OK   Oberhalb gewinnt die Anlage mit den niedrigeren variablen Kosten
  OK   Empfehlung nennt die unterhalb guenstigere Anlage
  OK   Empfehlung beruecksichtigt die geplante Menge
  OK   Gleiche variable Kosten: keine kritische Menge
  OK   Hinweis auf die Fixkosten
  OK   Auswertung liefert zwei Zeilen
  OK   Anschaffung A ausgewiesen
  OK   Anschaffung B ausgewiesen
  OK   Umsatz A
  OK   Break-Even vorhanden
  OK   Material steckt in den variablen Stueckkosten
  OK   Deckungsbeitrag ohne Material im Vergleich
  OK   Kritische Menge beruecksichtigt das Material
  OK   Material erhoeht die kritische Menge
  OK   Kurvenpunkte vorhanden
  OK   Kurvenpunkt mit Kosten A
  OK   Kurvenpunkt mit Kosten B

--- Ablauf · Jahresabschluss & Bilanz ---
  OK   Investition mindert die Kasse
  OK   Investition erhoeht das Anlagevermoegen
  OK   Materialaufwand ausgewiesen
  OK   Materialaufwand in den Gesamtkosten
  OK   Variable Fertigungskosten ausgewiesen
  OK   Variable Kosten in den Gesamtkosten
  OK   Fixkosten gebucht
  OK   Fixkosten in den Gesamtkosten
  OK   Abschreibung gebucht
  OK   Anlagevermoegen nach AfA
  OK   Bilanz stimmt
  OK   Jahresabschluss hat das Ergebnis gebucht
  OK   Roundtrip Materialaufwand
  OK   Roundtrip variable Kosten
  OK   Roundtrip Anlagevermoegen
  OK   Roundtrip Kasse

--- Ablauf · Nachfrage ---
  OK   Ohne Anlage keine Nachfrage
  OK   Nachfrage entsteht
  OK   Preis ueber Deckungsbeitrag
  OK   Umsatz = Menge x Preis
  OK   Menge positiv
  OK   Menge im Bereich der Kapazitaet
  OK   Lieferfrist ausreichend
  OK   Nachfrage ist deterministisch
  OK   Gleiche Menge am gleichen Tag
  OK   Groessere Kapazitaet bringt mehr Auftrag

--- Ablauf · Materialbeschaffung ---
  OK   Materialpreis
  OK   Kauf erfolgreich
  OK   Bestand erhoeht
  OK   Kasse gemindert
  OK   Lagerwert gesetzt
  OK   Kauf ohne Kapital schlaegt fehl
  OK   Bestand unveraendert
  OK   Negative Menge abgelehnt
  OK   Produktion laeuft mit Material

--- Ablauf · Gesamtbetrieb über ein Jahr ---
  OK   Auftraege eingegangen
  OK   Umsatz erzielt
  OK   Auftrage erfuellt
  OK   Kasse durch Umsatz gewachsen
  OK   Variable Fertigungskosten gebucht
  OK   Bilanz stimmt nach einem Jahr
  OK   Anlagevermoegen abgeschrieben
  OK   Fixkosten gebucht
  OK   Jahreszaehler erhoeht
  OK   Tageszaehler stimmt
  OK   Maschine im Bestand

--- Ablauf · Kassenlogik ohne Doppelbuchung ---
  OK   Umsatz nicht doppelt gezaehlt
  OK   Materialkauf moeglich
  OK   Materialkauf mindert die Kasse genau einmal
  OK   Material nicht doppelt bezahlt
  OK   Bestand unveraendert ohne Produktion
  OK   Jahresabschluss ohne Aufwand veraendert die Kasse nicht

--- Ablauf · Materiallieferung mit Vorlauf ---
  OK   Materialpreis korrekt
  OK   Tagesbedarf korrekt
  OK   Bestellung moeglich
  OK   Zahlung bei Bestellung
  OK   Ware noch nicht im Lager
  OK   Material auf dem Weg
  OK   Ware nach vier Tagen noch nicht da
  OK   Lieferung noch unterwegs
  OK   Ware am Liefertag da
  OK   Kein Material mehr unterwegs
  OK   Reichweite berechenbar
  OK   Sofortkauf moeglich
  OK   Ware sofort im Lager
  OK   Sofortkauf mindert die Kasse
  OK   Zweite Bestellung moeglich
  OK   Materiallieferung im Spielstand

--- Ablauf · Getrennte Materialarten ---
  OK   Zwei Materialarten erkannt
  OK   Stahl wird gebraucht
  OK   Verpackung wird gebraucht
  OK   Stahlpreis korrekt
  OK   Verpackungspreis korrekt
  OK   Stahlbedarf korrekt
  OK   Verpackungsbedarf korrekt
  OK   Stahlkauf moeglich
  OK   Stahl im Lager
  OK   Verpackung unberuehrt
  OK   Kasse nur einmal belastet
  OK   Stahlanlage produziert
  OK   Verpackungsanlage steht still
  OK   Verpackungsanlage produziert jetzt
  OK   Stahlbestand vorhanden
  OK   Verpackungsbestand vorhanden
  OK   Stahlbestand im Spielstand
  OK   Verpackungsbestand im Spielstand

--- Ablauf · Rahmenverträge ---
  OK   Deckungsbeitrag korrekt
  OK   Variable Stueckkosten korrekt
  OK   Preis unter variablen Kosten abgelehnt
  OK   Kein Vertrag angelegt
  OK   Preis ueber variablen Kosten zulaessig
  OK   Grenzvertrag wieder kuendbar
  OK   Grenzvertrag entfernt
  OK   Ueberkapazitaet abgelehnt
  OK   Vertrag geschlossen
  OK   Vertrag in der Liste
  OK   Gesicherte Menge korrekt
  OK   Gesicherter Deckungsbeitrag korrekt
  OK   Vertragsmenge groesser als die Marktnachfrage
  OK   Kuendigung moeglich
  OK   Kuendigungsgebuehr abgebucht
  OK   Vertrag entfernt
  OK   Zweiter Vertrag geschlossen
  OK   Laufzeit um ein Jahr verringert
  OK   Vertrag ausgelaufen
  OK   Vertrag fuer den Spielstand geschlossen
  OK   Vertrag im Spielstand
  OK   Vertragsmenge im Spielstand

--- Ablauf · Mehrstufige Produktionskette ---
  OK   Endstufe ohne Vorstufe produziert nichts
  OK   Leerlauf wird protokolliert
  OK   Vorstufe produziert bedarfsgerecht
  OK   Endstufe produziert ihre Tagesmenge
  OK   Kein Rueckstau im Zwischenlager
  OK   Vorstufe erzeugt kein Endprodukt
  OK   Endstufe wird von der Vorstufe begrenzt
  OK   Zwischenlager im Spielstand

--- Ablauf · Wirtschaftlichkeit der Kette ---
  OK   Ketten-Deckungsbeitrag exakt (18 - 3 - 2x4)
  OK   Variable Kosten der Kette exakt (3 + 2x4)
  OK   Eigenfertigung schlaegt Zukauf zum Verrechnungspreis
  OK   Endstufe allein ist keine Alternative zur Kette
  OK   Teurere Vorstufe senkt den Ketten-Deckungsbeitrag
  OK   Teure Vorstufe exakt (18 - 3 - 2x12)
  OK   Ketten-Kapitalwert exakt (Engpass, zahlungswirksam)
  OK   Endstufe allein gerechnet ueberschaetzt den Wert
  OK   Ketten-Kapitalwert ist positiv
  OK   Die Kette bindet mehr Kapital als die Endstufe allein
RUN-TESTS: Suite fertig: res://tests/test_operations.gd
RUN-TESTS: Suite startet: res://tests/test_persistence.gd

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
  OK   Sanitize: Stufen boolesch
  OK   Sanitize: leerer Stand spielbar
  OK   Sanitize: Statistik vorhanden

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

--- Persistenz · Spielstand-Roundtrip ---
  OK   Spielername erhalten
  OK   XP erhalten
  OK   Stufenfortschritt erhalten
  OK   Teilaufgabe erhalten
  OK   Einstellung erhalten
  OK   Tag erhalten
  OK   Jahr erhalten
  OK   Kasse erhalten
  OK   Anlagevermoegen erhalten
  OK   Materialbestand erhalten
  OK   Materialbestand je Art erhalten
  OK   Zwischenlager erhalten
  OK   Reset setzt den Tag zurueck
  OK   Reset setzt die Kasse zurueck
  OK   Reset bindet das Startkapital in der Anlage
  OK   Bilanz nach dem Reset ausgeglichen
  OK   Reset legt die Startanlage an
RUN-TESTS: Suite fertig: res://tests/test_persistence.gd
RUN-TESTS: Suite startet: res://tests/test_learning.gd

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

--- Lernen · Zuordnungs- & Ordnungsinhalte ---
  OK   W1/Runde 1 · Zahlungsstromrichtung: Runde mit Kategorien
  OK   W1/Runde 1 · Zahlungsstromrichtung: Runde mit Karten
  OK   W1/Runde 1 · Zahlungsstromrichtung: Karte mit Kategorie
  OK   W1/Runde 1 · Zahlungsstromrichtung: Karte mit Begruendung
  OK   W1/Runde 1 · Zahlungsstromrichtung: Karte mit Kategorie
  OK   W1/Runde 1 · Zahlungsstromrichtung: Karte mit Begruendung
  OK   W1/Runde 1 · Zahlungsstromrichtung: Karte mit Kategorie
  OK   W1/Runde 1 · Zahlungsstromrichtung: Karte mit Begruendung
  OK   W1/Runde 1 · Zahlungsstromrichtung: Karte mit Kategorie
  OK   W1/Runde 1 · Zahlungsstromrichtung: Karte mit Begruendung
  OK   W1/Runde 1 · Zahlungsstromrichtung: Karte mit Kategorie
  OK   W1/Runde 1 · Zahlungsstromrichtung: Karte mit Begruendung
  OK   W1/Runde 2 · Kostenbegriffe: Runde mit Kategorien
  OK   W1/Runde 2 · Kostenbegriffe: Runde mit Karten
  OK   W1/Runde 2 · Kostenbegriffe: Karte mit Kategorie
  OK   W1/Runde 2 · Kostenbegriffe: Karte mit Begruendung
  OK   W1/Runde 2 · Kostenbegriffe: Karte mit Kategorie
  OK   W1/Runde 2 · Kostenbegriffe: Karte mit Begruendung
  OK   W1/Runde 2 · Kostenbegriffe: Karte mit Kategorie
  OK   W1/Runde 2 · Kostenbegriffe: Karte mit Begruendung
  OK   W1/Runde 2 · Kostenbegriffe: Karte mit Kategorie
  OK   W1/Runde 2 · Kostenbegriffe: Karte mit Begruendung
  OK   W1/Runde 2 · Kostenbegriffe: Karte mit Kategorie
  OK   W1/Runde 2 · Kostenbegriffe: Karte mit Begruendung
  OK   W1/Runde 2 · Kostenbegriffe: Karte mit Kategorie
  OK   W1/Runde 2 · Kostenbegriffe: Karte mit Begruendung
  OK   W1/Runde 3 · Kapitalarten: Runde mit Kategorien
  OK   W1/Runde 3 · Kapitalarten: Runde mit Karten
  OK   W1/Runde 3 · Kapitalarten: Karte mit Kategorie
  OK   W1/Runde 3 · Kapitalarten: Karte mit Begruendung
  OK   W1/Runde 3 · Kapitalarten: Karte mit Kategorie
  OK   W1/Runde 3 · Kapitalarten: Karte mit Begruendung
  OK   W1/Runde 3 · Kapitalarten: Karte mit Kategorie
  OK   W1/Runde 3 · Kapitalarten: Karte mit Begruendung
  OK   W1/Runde 3 · Kapitalarten: Karte mit Kategorie
  OK   W1/Runde 3 · Kapitalarten: Karte mit Begruendung
  OK   W1/Runde 3 · Kapitalarten: Karte mit Kategorie
  OK   W1/Runde 3 · Kapitalarten: Karte mit Begruendung
  OK   W1/Prozess-Puzzle · Investitionsentscheidung: Ordnungsaufgabe mit Elementen
  OK   W1/Investitionsrechnungs-Trichter: Runde mit Kategorien
  OK   W1/Investitionsrechnungs-Trichter: Runde mit Karten
  OK   W1/Investitionsrechnungs-Trichter: Karte mit Kategorie
  OK   W1/Investitionsrechnungs-Trichter: Karte mit Begruendung
  OK   W1/Investitionsrechnungs-Trichter: Karte mit Kategorie
  OK   W1/Investitionsrechnungs-Trichter: Karte mit Begruendung
  OK   W1/Investitionsrechnungs-Trichter: Karte mit Kategorie
  OK   W1/Investitionsrechnungs-Trichter: Karte mit Begruendung
  OK   W1/Investitionsrechnungs-Trichter: Karte mit Kategorie
  OK   W1/Investitionsrechnungs-Trichter: Karte mit Begruendung
  OK   W1/Investitionsrechnungs-Trichter: Karte mit Kategorie
  OK   W1/Investitionsrechnungs-Trichter: Karte mit Begruendung
  OK   W1/Investitionsrechnungs-Trichter: Karte mit Kategorie
  OK   W1/Investitionsrechnungs-Trichter: Karte mit Begruendung
  OK   W1/Investitionsrechnungs-Trichter: Karte mit Kategorie
  OK   W1/Investitionsrechnungs-Trichter: Karte mit Begruendung
  OK   W1/Investitionsrechnungs-Trichter: Karte mit Kategorie
  OK   W1/Investitionsrechnungs-Trichter: Karte mit Begruendung
  OK   W2/Fixkosten-Baukasten: Runde mit Kategorien
  OK   W2/Fixkosten-Baukasten: Runde mit Karten
  OK   W2/Fixkosten-Baukasten: Karte mit Kategorie
  OK   W2/Fixkosten-Baukasten: Karte mit Begruendung
  OK   W2/Fixkosten-Baukasten: Karte mit Kategorie
  OK   W2/Fixkosten-Baukasten: Karte mit Begruendung
  OK   W2/Fixkosten-Baukasten: Karte mit Kategorie
  OK   W2/Fixkosten-Baukasten: Karte mit Begruendung
  OK   W2/Fixkosten-Baukasten: Karte mit Kategorie
  OK   W2/Fixkosten-Baukasten: Karte mit Begruendung
  OK   W2/Fixkosten-Baukasten: Karte mit Kategorie
  OK   W2/Fixkosten-Baukasten: Karte mit Begruendung
  OK   W3/Werkzeugkarten zuordnen: Runde mit Kategorien
  OK   W3/Werkzeugkarten zuordnen: Runde mit Karten
  OK   W3/Werkzeugkarten zuordnen: Karte mit Kategorie
  OK   W3/Werkzeugkarten zuordnen: Karte mit Begruendung
  OK   W3/Werkzeugkarten zuordnen: Karte mit Kategorie
  OK   W3/Werkzeugkarten zuordnen: Karte mit Begruendung
  OK   W3/Werkzeugkarten zuordnen: Karte mit Kategorie
  OK   W3/Werkzeugkarten zuordnen: Karte mit Begruendung
  OK   W3/Werkzeugkarten zuordnen: Karte mit Kategorie
  OK   W3/Werkzeugkarten zuordnen: Karte mit Begruendung
  OK   W3/Werkzeugkarten zuordnen: Karte mit Kategorie
  OK   W3/Werkzeugkarten zuordnen: Karte mit Begruendung
  OK   W4/Risiko-Radar: Runde mit Kategorien
  OK   W4/Risiko-Radar: Runde mit Karten
  OK   W4/Risiko-Radar: Karte mit Kategorie
  OK   W4/Risiko-Radar: Karte mit Begruendung
  OK   W4/Risiko-Radar: Karte mit Kategorie
  OK   W4/Risiko-Radar: Karte mit Begruendung
  OK   W4/Risiko-Radar: Karte mit Kategorie
  OK   W4/Risiko-Radar: Karte mit Begruendung
  OK   W4/Risiko-Radar: Karte mit Kategorie
  OK   W4/Risiko-Radar: Karte mit Begruendung
  OK   W4/Risiko-Radar: Karte mit Kategorie
  OK   W4/Risiko-Radar: Karte mit Begruendung
  OK   W4/Zerobond-Typen: Runde mit Kategorien
  OK   W4/Zerobond-Typen: Runde mit Karten
  OK   W4/Zerobond-Typen: Karte mit Kategorie
  OK   W4/Zerobond-Typen: Karte mit Begruendung
  OK   W4/Zerobond-Typen: Karte mit Kategorie
  OK   W4/Zerobond-Typen: Karte mit Begruendung
  OK   W4/Zerobond-Typen: Karte mit Kategorie
  OK   W4/Zerobond-Typen: Karte mit Begruendung
  OK   W5/Cash-Cycle-Zeitstrahl: Ordnungsaufgabe mit Elementen
  OK   W6/Stille-Reserven-Kaskade: Ordnungsaufgabe mit Elementen
  OK   W7/Kapitalerhöhungs-Formen: Runde mit Kategorien
  OK   W7/Kapitalerhöhungs-Formen: Runde mit Karten
  OK   W7/Kapitalerhöhungs-Formen: Karte mit Kategorie
  OK   W7/Kapitalerhöhungs-Formen: Karte mit Begruendung
  OK   W7/Kapitalerhöhungs-Formen: Karte mit Kategorie
  OK   W7/Kapitalerhöhungs-Formen: Karte mit Begruendung
  OK   W7/Kapitalerhöhungs-Formen: Karte mit Kategorie
  OK   W7/Kapitalerhöhungs-Formen: Karte mit Begruendung
  OK   W7/Kapitalerhöhungs-Formen: Karte mit Kategorie
  OK   W7/Kapitalerhöhungs-Formen: Karte mit Begruendung
  OK   W7/Kapitalerhöhungs-Formen: Karte mit Kategorie
  OK   W7/Kapitalerhöhungs-Formen: Karte mit Begruendung
  OK   W8/Kreditleihe oder Geldleihe?: Runde mit Kategorien
  OK   W8/Kreditleihe oder Geldleihe?: Runde mit Karten
  OK   W8/Kreditleihe oder Geldleihe?: Karte mit Kategorie
  OK   W8/Kreditleihe oder Geldleihe?: Karte mit Begruendung
  OK   W8/Kreditleihe oder Geldleihe?: Karte mit Kategorie
  OK   W8/Kreditleihe oder Geldleihe?: Karte mit Begruendung
  OK   W8/Kreditleihe oder Geldleihe?: Karte mit Kategorie
  OK   W8/Kreditleihe oder Geldleihe?: Karte mit Begruendung
  OK   W8/Kreditleihe oder Geldleihe?: Karte mit Kategorie
  OK   W8/Kreditleihe oder Geldleihe?: Karte mit Begruendung
  OK   W8/Kreditleihe oder Geldleihe?: Karte mit Kategorie
  OK   W8/Kreditleihe oder Geldleihe?: Karte mit Begruendung
  OK   W8/Factoring oder Forfaitierung?: Runde mit Kategorien
  OK   W8/Factoring oder Forfaitierung?: Runde mit Karten
  OK   W8/Factoring oder Forfaitierung?: Karte mit Kategorie
  OK   W8/Factoring oder Forfaitierung?: Karte mit Begruendung
  OK   W8/Factoring oder Forfaitierung?: Karte mit Kategorie
  OK   W8/Factoring oder Forfaitierung?: Karte mit Begruendung
  OK   W8/Factoring oder Forfaitierung?: Karte mit Kategorie
  OK   W8/Factoring oder Forfaitierung?: Karte mit Begruendung
  OK   W8/Factoring oder Forfaitierung?: Karte mit Kategorie
  OK   W8/Factoring oder Forfaitierung?: Karte mit Begruendung
  OK   W9/Aktienwert-Treiber: Runde mit Kategorien
  OK   W9/Aktienwert-Treiber: Runde mit Karten
  OK   W9/Aktienwert-Treiber: Karte mit Kategorie
  OK   W9/Aktienwert-Treiber: Karte mit Begruendung
  OK   W9/Aktienwert-Treiber: Karte mit Kategorie
  OK   W9/Aktienwert-Treiber: Karte mit Begruendung
  OK   W9/Aktienwert-Treiber: Karte mit Kategorie
  OK   W9/Aktienwert-Treiber: Karte mit Begruendung
  OK   W9/Aktienwert-Treiber: Karte mit Kategorie
  OK   W9/Aktienwert-Treiber: Karte mit Begruendung
  OK   W9/Aktienwert-Treiber: Karte mit Kategorie
  OK   W9/Aktienwert-Treiber: Karte mit Begruendung
  OK   W9/Aktienwert-Treiber: Karte mit Kategorie
  OK   W9/Aktienwert-Treiber: Karte mit Begruendung
  OK   W9/Fundamentale Aktienbewertung: Ordnungsaufgabe mit Elementen
  OK   12 Zuordnungsrunden vorhanden
  OK   62 Karten vorhanden
  OK   4 Ordnungsaufgaben vorhanden
  OK   Ordnungsaufgaben mit Lösungsweg

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
  OK   Höherer Punktwert zählt
  OK   Niedrigerer Punktwert überschreibt nicht
  OK   Roundtrip XP
  OK   Roundtrip Weltenfortschritt

--- Lernen · Teilaufgaben-Freischaltung ---
  OK   Einzelne Teilaufgabe schaltet die Stufe nicht frei
  OK   Welt W1 hat Teilaufgaben
  OK   Alle Teilaufgaben geloest: Stufe vollstaendig
  OK   Kein doppelter XP-Gewinn
  OK   Fortschritt einer anderen Welt bleibt unberuehrt

--- Lernen · Betriebs-Lab aus echten Daten ---
  OK   Ohne Betrieb keine Betriebsaufgaben
  OK   Kapazitaet korrekt
  OK   Menge korrekt
  OK   Preis je Stueck korrekt
  OK   Variable Kosten je Stueck korrekt
  OK   Deckungsbeitrag je Stueck korrekt
  OK   Betriebsaufgaben erzeugt
  OK   Aufgabe 'betrieb-deckungsbeitrag' hat Felder
  OK   Aufgabe 'betrieb-deckungsbeitrag' hat eine Loesung
  OK   Aufgabe 'betrieb-deckungsbeitrag' hat einen Hinweis
  OK   Aufgabe 'betrieb-deckungsbeitrag' vollstaendig formatiert
  OK   Aufgabe 'betrieb-deckungsbeitrag' ohne doppeltes Waehrungszeichen
  OK   Aufgabe 'betrieb-break-even' hat Felder
  OK   Aufgabe 'betrieb-break-even' hat eine Loesung
  OK   Aufgabe 'betrieb-break-even' hat einen Hinweis
  OK   Aufgabe 'betrieb-break-even' vollstaendig formatiert
  OK   Aufgabe 'betrieb-break-even' ohne doppeltes Waehrungszeichen
  OK   Aufgabe 'betrieb-gesamtkosten' hat Felder
  OK   Aufgabe 'betrieb-gesamtkosten' hat eine Loesung
  OK   Aufgabe 'betrieb-gesamtkosten' hat einen Hinweis
  OK   Aufgabe 'betrieb-gesamtkosten' vollstaendig formatiert
  OK   Aufgabe 'betrieb-gesamtkosten' ohne doppeltes Waehrungszeichen
  OK   Aufgabe 'betrieb-ergebnis' hat Felder
  OK   Aufgabe 'betrieb-ergebnis' hat eine Loesung
  OK   Aufgabe 'betrieb-ergebnis' hat einen Hinweis
  OK   Aufgabe 'betrieb-ergebnis' vollstaendig formatiert
  OK   Aufgabe 'betrieb-ergebnis' ohne doppeltes Waehrungszeichen
  OK   Aufgabe 'betrieb-ekr' hat Felder
  OK   Aufgabe 'betrieb-ekr' hat eine Loesung
  OK   Aufgabe 'betrieb-ekr' hat einen Hinweis
  OK   Aufgabe 'betrieb-ekr' vollstaendig formatiert
  OK   Aufgabe 'betrieb-ekr' ohne doppeltes Waehrungszeichen
  OK   Aufgabe 'betrieb-bilanz' hat Felder
  OK   Aufgabe 'betrieb-bilanz' hat eine Loesung
  OK   Aufgabe 'betrieb-bilanz' hat einen Hinweis
  OK   Aufgabe 'betrieb-bilanz' vollstaendig formatiert
  OK   Aufgabe 'betrieb-bilanz' ohne doppeltes Waehrungszeichen
  OK   Aufgabe 'betrieb-kapitalbedarf' hat Felder
  OK   Aufgabe 'betrieb-kapitalbedarf' hat eine Loesung
  OK   Aufgabe 'betrieb-kapitalbedarf' hat einen Hinweis
  OK   Aufgabe 'betrieb-kapitalbedarf' vollstaendig formatiert
  OK   Aufgabe 'betrieb-kapitalbedarf' ohne doppeltes Waehrungszeichen
  OK   Aufgabe 'betrieb-materialreichweite' hat Felder
  OK   Aufgabe 'betrieb-materialreichweite' hat eine Loesung
  OK   Aufgabe 'betrieb-materialreichweite' hat einen Hinweis
  OK   Aufgabe 'betrieb-materialreichweite' vollstaendig formatiert
  OK   Aufgabe 'betrieb-materialreichweite' ohne doppeltes Waehrungszeichen
  OK   Deckungsbeitrag der Aufgabe stimmt
  OK   Gesamter Deckungsbeitrag der Aufgabe stimmt
  OK   Deckungsbeitragsaufgabe vorhanden
  OK   Break-even der Aufgabe stimmt
  OK   Break-even-Aufgabe vorhanden
  OK   Bilanz der Aufgabe geht auf
  OK   Bilanzaufgabe vorhanden
  OK   Aufgabe zuerst ungeloest
  OK   Aufgabe nach dem Markieren geloest
  OK   Zaehloest
RUN-TESTS: Suite fertig: res://tests/test_learning.gd
RUN-TESTS: Suite startet: res://tests/test_advisor.gd

--- Berater · Grundbefunde ---
  OK   Berater laesst sich instanziieren
  OK   Ohne Anlage wird die fehlende Produktion gemeldet
  OK   Zu geringe Auslastung wird erkannt
  OK   Der Hinweis nennt die Auslastung als Zahl
  OK   Kapazitätsgrenze wird erkannt
  OK   Dünne Kasse wird erkannt
  OK   Überzogene Kasse wird erkannt

--- Berater · Frage statt fertiger Antwort ---
  OK   Berater laesst sich instanziieren
  OK   Jeder Hinweis stellt mindestens eine Frage
  OK   Jeder Hinweis nennt eine Lektion
  OK   Jeder Hinweis nennt einen konkreten Ort im Menü
  OK   Die Lektion erklärt den Zusammenhang statt der Handlung

--- Berater · Nachfrage gegen Kapazität ---
  OK   Berater laesst sich instanziieren
  OK   Nachfrage über Kapazität wird erkannt
  OK   Der Hinweis nennt Bedarf und Kapazität
  OK   Kapazität über Nachfrage wird erkannt
  OK   Bei passender Nachfrage kein Hinweis

--- Berater · Produktionskette ---
  OK   Berater laesst sich instanziieren
  OK   Fehlender Zulieferer wird gemeldet
  OK   Ohne Rueckstau kein Kettenhinweis
  OK   Rückstau wird gemeldet

--- Berater · Fahrplan mit Zielzahl ---
  OK   Berater laesst sich instanziieren
  OK   Bei geringer Auslastung nennt der Fahrplan die Auslastung
  OK   Der Fahrplan nennt eine Zielzahl
  OK   Der Fahrplan stellt eine Frage
  OK   Bei dünnner Kasse nennt der Fahrplan die Reserve
  OK   Bei guter Lage nennt der Fahrplan die Investition

--- Berater · Finanzierungsbefunde ---
  OK   Ungenutzter Kreditrahmen wird erkannt
  OK   Befundtext vollstaendig formatiert (kein %s uebrig)
  OK   Befundtext nennt den Kreditrahmen
  OK   Befundtext ohne doppeltes Waehrungszeichen
  OK   Hohe Verschuldung wird erkannt
  OK   Leverage-Befund vollstaendig formatiert
  OK   Leverage-Befund ohne doppeltes Waehrungszeichen
RUN-TESTS: Suite fertig: res://tests/test_advisor.gd
RUN-TESTS: Suite startet: res://tests/test_longrun.gd

--- Langzeit · 10 Jahre Grundbetrieb ---
  OK   3.600 Tage simuliert
  OK   Zehn Jahresabschluesse
  OK   Alle Groessen endlich (Grundbetrieb)
  OK   Betrieb bleibt liquide
  OK   Eigenkapital bleibt positiv
  OK   Kasse waechst ueber zehn Jahre
  OK   Eigenkapital waechst ueber zehn Jahre
  OK   Umsatz bleibt unter der Kapazitaetsgrenze
  OK   Umsatz entstanden
  OK   Auftraege wurden erfuellt
  OK   Bilanz stimmt nach zehn Jahren
  OK   Roundtrip: Kasse
  OK   Roundtrip: Eigenkapital
  OK   Roundtrip: Tag

--- Langzeit · 10 Jahre mit Finanzierung ---
  OK   Darlehen zum Start aufgenommen
  OK   Ausschuettungsquote gesetzt
  OK   Alle Groessen endlich (finanziert)
  OK   Finanzierter Betrieb bleibt liquide
  OK   Eigenkapital uebersteht Schuldendienst und Dividende
  OK   Darlehen nach Laufzeit getilgt
  OK   Keine Restschuld aus dem Darlehen
  OK   Dividenden sind geflossen
  OK   Bilanz stimmt (finanziert)
  OK   FK-Quote im gueltigen Bereich
RUN-TESTS: Suite fertig: res://tests/test_longrun.gd

========================================
ERGEBNIS: 922 bestanden, 0 fehlgeschlagen
========================================


Alle Tests bestanden.
```

## Testausgabe (Framework)
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
  OK   EPS
  OK   KGV
  OK   Dividendenrendite %
  OK   BW explizite Dividenden
  OK   Fairer Wert inkl. Verkauf
  OK   Gordon P0
  OK   Gordon bei r<=g
  OK   Implizites Wachstum %
  OK   CAPM %
  OK   CAPM-Gordon
  OK   Zweiphasen-Modell
  OK   Zweiphasen D3
  OK   Zweiphasen Terminal Value
  OK   Zweiphasen Wert heute
  OK   Nachhaltiges Wachstum %
  OK   Bewertung über KGV
  OK   Gesamtrendite %

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

--- BWL-Engine · Zahlformatierung ---
  OK   format_number gruppiert Tausender
  OK   format_number: fuenf Stellen
  OK   format_number: unter Tausend ohne Punkt
  OK   format_number: Dezimalkomma
  OK   format_eur: Betrag mit Einheit
  OK   format_eur: negativer Betrag
  OK   format_eur: kein Minus bei gerundeter Null

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
  OK   Operativer Cashflow
  OK   Zinsaufwand nicht doppelt belastet
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

--- Simulation · Investitionsrechnung ---
  OK   Effektivzins korrekt gewichtet
  OK   Cashflow entspricht der Legacy-Definition
  OK   Zwei Anlagen ausgewertet
  OK   Barwert stimmt mit der Engine ueberein
  OK   Barwert stimmt mit der Handrechnung ueberein
  OK   Kapitalwert ist die Annuität zum Barwert
  OK   Rentabilitaetsindex ueber 1 bei positivem Barwert
  OK   Interne Rendite positiv
  OK   Interne Rendite ueber dem Diskontsatz
  OK   Verlustanlage hat negativen Barwert
  OK   Verlustanlage hat negativen Kapitalwert
  OK   Verlustanlage hat Index unter 1

--- Simulation · Finanzierung ---
  OK   EK-Quote startet bei 100 %
  OK   FK-Quote startet bei 0 %
  OK   Kreditrahmen vorhanden
  OK   Kreditrahmen entspricht dem Eigenkapital
  OK   Kredit aufgenommen
  OK   Kasse steigt um den Kreditbetrag
  OK   Fremdkapital steigt
  OK   Bilanz stimmt nach Kredit
  OK   FK-Quote korrekt
  OK   Zinssatz richtet sich nach der Bonitaet
  OK   Ueberziehung wird abgelehnt
  OK   Abgelehnter Kredit veraendert die Kasse nicht
  OK   Tilgung moeglich
  OK   Kasse sinkt um den Tilgungsbetrag
  OK   Fremdkapital sinkt um den Tilgungsbetrag
  OK   Bilanz stimmt nach Tilgung
  OK   Ungueltiger Tilgungsanteil abgelehnt
  OK   Tilgungsanteil unveraendert
  OK   Ohne Automatik wird nicht getilgt
  OK   Zinsbelastung berechenbar
  OK   Finanzierungskosten = Zinsen + Tilgung

--- Simulation · Tilgungspläne ---
  OK   Annuitaetendarlehen aufgenommen
  OK   Fremdkapital = Darlehenssumme
  OK   Restschuld der Darlehen
  OK   Jahr 1: Zins nach Plan
  OK   Jahr 1: Tilgung nach Plan
  OK   Jahr 1: Restschuld nach Plan
  OK   Bilanz stimmt nach Schuldendienst
  OK   Jahr 2: Zins sinkt nach Plan
  OK   Jahr 2: Restschuld nach Plan
  OK   Tilgungsanteil steigt von Jahr zu Jahr
  OK   Nach Laufzeitende schuldenfrei
  OK   Darlehen aus der Liste entfernt
  OK   Ratendarlehen: Tilgung Jahr 1
  OK   Ratendarlehen: Zins Jahr 1
  OK   Ratendarlehen: Tilgung Jahr 2 konstant
  OK   Ratendarlehen: Zins Jahr 2 sinkt
  OK   Endfaellig: keine Tilgung im Jahr 1
  OK   Endfaellig: Zins Jahr 1
  OK   Endfaellig: Restschuld unveraendert
  OK   Endfaellig: volle Tilgung am Ende
  OK   Endfaellig: Darlehen abgeschlossen
  OK   Unbekannte Darlehensform abgelehnt
  OK   Laufzeit unter 1 Jahr abgelehnt
  OK   Darlehen ueberlebt den Spielstand
  OK   Darlehensliste wiederhergestellt

--- Simulation · Dividendenpolitik ---
  OK   Ausschuettungsquote gesetzt
  OK   Quote ueber 100 % abgelehnt
  OK   Quote unveraendert nach Ablehnung
  OK   Dividende = Quote x Ueberschuss
  OK   Eigenkapital: Gewinn minus Ausschuettung
  OK   Bilanz stimmt nach Dividende
  OK   Verlustjahr: keine Dividende
  OK   Quote im Spielstand

--- Simulation · Finanzplan & Aktienbewertung ---
  OK   Finanzplan: Tageskosten
  OK   Finanzplan: Kapitalbindungsdauer
  OK   Finanzplan: Kapitalbedarf = Dauer x Tageskosten
  OK   Finanzplan: Fixkosten als Auszahlung
  OK   Finanzplan: Darlehenszins
  OK   Finanzplan: Darlehenstilgung
  OK   Bewertung: Ergebnis je Aktie
  OK   Bewertung: Buchwert je Aktie
  OK   Bewertung: Dividende je Aktie
  OK   Bewertung: nachhaltiges Wachstum
  OK   Bewertung: CAPM-Kapitalkosten
  OK   Bewertung: Gordon-Wert
  OK   Lohmann-Ruchti: Ausblick vorhanden
  OK   Lohmann-Ruchti: Anlagenzahl erkannt
  OK   Lohmann-Ruchti: 7 Jahreszeilen
  OK   Lohmann-Ruchti: AfA-Parität mit der Engine
  OK   Lohmann-Ruchti: ohne Anlagen abgelehnt

--- Simulation · Kapitalerhöhung & Bezugsrecht ---
  OK   Startkurs = Buchwert je Aktie
  OK   1.000 Aktien zu Beginn
  OK   Kapitalerhoehung durchgefuehrt
  OK   250 junge Aktien
  OK   Zufluss 10.000
  OK   Kasse steigt um den Zufluss
  OK   Eigenkapital steigt um den Zufluss
  OK   1.250 Aktien danach
  OK   Bilanz stimmt nach Kapitalerhoehung
  OK   Mischkurs 48
  OK   Bezugsrecht 2
  OK   Paritaet: Bezugsrechtswert
  OK   Paritaet: Mischkurs
  OK   Kurs nach Erhoehung = Mischkurs
  OK   Ausgabekurs ueber Kurs abgelehnt
  OK   Bezugsverhaeltnis unter 1:1 abgelehnt
  OK   Abgelehnte Erhoehung veraendert nichts
  OK   Aktienzahl im Spielstand

--- Gelaende · Belegung ---
  OK   Gebaeude belegt
  OK   Zelle (5,9) belegt
  OK   Zelle (5,9) gehoert zum Gebaeude
  OK   Zelle (6,9) belegt
  OK   Zelle (6,9) gehoert zum Gebaeude
  OK   Zelle (7,9) belegt
  OK   Zelle (7,9) gehoert zum Gebaeude
  OK   Zelle (5,10) belegt
  OK   Zelle (5,10) gehoert zum Gebaeude
  OK   Zelle (6,10) belegt
  OK   Zelle (6,10) gehoert zum Gebaeude
  OK   Zelle (7,10) belegt
  OK   Zelle (7,10) gehoert zum Gebaeude
  OK   Keine Zelle links vom Gebaeude belegt
  OK   Keine Zelle unter dem Gebaeude belegt
  OK   Keine Zelle rechts daneben belegt
  OK   Ueberlappung wird erkannt
  OK   Ueberlappung wird abgelehnt
  OK   Direkt angrenzende Flaeche ist frei
  OK   Angrenzendes Gebaeude passt
  OK   Nach Freigabe wieder frei
  OK   Freigabe loescht genau die eigenen Zellen
  OK   Freigabe laesst fremde Zellen unberuehrt
  OK   Rand links wird abgelehnt
  OK   Rand rechts wird abgelehnt
  OK   Rand unten wird abgelehnt

--- Gelaende · Zonen und Suche ---
  OK   Zone gesetzt
  OK   Ausserhalb der Zone bleibt Gruen
  OK   Freie Stelle gefunden
  OK   Gefundene Stelle liegt in der Zone
  OK   Gefundene Stelle ist frei
  OK   Belegung mit der gefundenen Stelle
  OK   Zweite Stelle weicht aus
  OK   Koordinaten-Umrechnung stimmt

--- Ablauf · Maschinen-Lieferkette ---
  OK   Start: ORDERED
  OK   ORDERED -> IN_TRANSIT erlaubt
  OK   IN_TRANSIT -> ARRIVED erlaubt
  OK   ARRIVED -> UNLOADING erlaubt
  OK   UNLOADING -> INSTALLING erlaubt
  OK   INSTALLING -> ACTIVE erlaubt
  OK   Sprung ORDERED -> ACTIVE verboten
  OK   Sprung IN_TRANSIT -> INSTALLING verboten
  OK   Rueckwaertswechsel verboten
  OK   Nach Schritt 1: IN_TRANSIT
  OK   Lieferzeit gesetzt
  OK   Nach Schritt 2: ARRIVED
  OK   Entladezeit gesetzt
  OK   Nach Schritt 3: UNLOADING
  OK   Nach Schritt 4: INSTALLING
  OK   Montagezeit gesetzt
  OK   Nach Schritt 5: ACTIVE
  OK   Maschine betriebsbereit
  OK   Aus ACTIVE kein weiterer Schritt
  OK   Label fuer UNLOADING vorhanden
  OK   Testfall: steht in UNLOADING
  OK   Save-Roundtrip: Zustand erhalten
  OK   Save-Roundtrip: Restzeit erhalten

--- Ablauf · Produktion & Material ---
  OK   Ohne Auftrag keine Produktion
  OK   Ohne Produktion keine variablen Kosten
  OK   Ohne Material keine Produktion
  OK   Tagesproduktion
  OK   Materialverbrauch gebucht
  OK   Variable Kosten zahlungswirksam
  OK   Materialengpass stoppt die Produktion
  OK   Engpass vermerkt

--- Ablauf · Kundenaufträge ---
  OK   Auftrag bei Fristablauf storniert
  OK   Nicht als erfuellt gewertet
  OK   Gefertigte Ware faellt in den Bestand zurueck
  OK   Auftrag bei ausreichender Produktion erfuellt
  OK   Erlos gebucht
  OK   Kasse erhoeht
  OK   Eigenkapital entspricht dem Ergebnis

--- Ablauf · Investitionsentscheidung ---
  OK   Kritische Menge berechenbar
  OK   Kritische Menge positiv
  OK   Unterhalb gewinnt die Anlage mit den niedrigeren Fixkosten
  OK   Oberhalb gewinnt die Anlage mit den niedrigeren variablen Kosten
  OK   Empfehlung nennt die unterhalb guenstigere Anlage
  OK   Empfehlung beruecksichtigt die geplante Menge
  OK   Gleiche variable Kosten: keine kritische Menge
  OK   Hinweis auf die Fixkosten
  OK   Auswertung liefert zwei Zeilen
  OK   Anschaffung A ausgewiesen
  OK   Anschaffung B ausgewiesen
  OK   Umsatz A
  OK   Break-Even vorhanden
  OK   Material steckt in den variablen Stueckkosten
  OK   Deckungsbeitrag ohne Material im Vergleich
  OK   Kritische Menge beruecksichtigt das Material
  OK   Material erhoeht die kritische Menge
  OK   Kurvenpunkte vorhanden
  OK   Kurvenpunkt mit Kosten A
  OK   Kurvenpunkt mit Kosten B

--- Ablauf · Jahresabschluss & Bilanz ---
  OK   Investition mindert die Kasse
  OK   Investition erhoeht das Anlagevermoegen
  OK   Materialaufwand ausgewiesen
  OK   Materialaufwand in den Gesamtkosten
  OK   Variable Fertigungskosten ausgewiesen
  OK   Variable Kosten in den Gesamtkosten
  OK   Fixkosten gebucht
  OK   Fixkosten in den Gesamtkosten
  OK   Abschreibung gebucht
  OK   Anlagevermoegen nach AfA
  OK   Bilanz stimmt
  OK   Jahresabschluss hat das Ergebnis gebucht
  OK   Roundtrip Materialaufwand
  OK   Roundtrip variable Kosten
  OK   Roundtrip Anlagevermoegen
  OK   Roundtrip Kasse

--- Ablauf · Nachfrage ---
  OK   Ohne Anlage keine Nachfrage
  OK   Nachfrage entsteht
  OK   Preis ueber Deckungsbeitrag
  OK   Umsatz = Menge x Preis
  OK   Menge positiv
  OK   Menge im Bereich der Kapazitaet
  OK   Lieferfrist ausreichend
  OK   Nachfrage ist deterministisch
  OK   Gleiche Menge am gleichen Tag
  OK   Groessere Kapazitaet bringt mehr Auftrag

--- Ablauf · Materialbeschaffung ---
  OK   Materialpreis
  OK   Kauf erfolgreich
  OK   Bestand erhoeht
  OK   Kasse gemindert
  OK   Lagerwert gesetzt
  OK   Kauf ohne Kapital schlaegt fehl
  OK   Bestand unveraendert
  OK   Negative Menge abgelehnt
  OK   Produktion laeuft mit Material

--- Ablauf · Gesamtbetrieb über ein Jahr ---
  OK   Auftraege eingegangen
  OK   Umsatz erzielt
  OK   Auftrage erfuellt
  OK   Kasse durch Umsatz gewachsen
  OK   Variable Fertigungskosten gebucht
  OK   Bilanz stimmt nach einem Jahr
  OK   Anlagevermoegen abgeschrieben
  OK   Fixkosten gebucht
  OK   Jahreszaehler erhoeht
  OK   Tageszaehler stimmt
  OK   Maschine im Bestand

--- Ablauf · Kassenlogik ohne Doppelbuchung ---
  OK   Umsatz nicht doppelt gezaehlt
  OK   Materialkauf moeglich
  OK   Materialkauf mindert die Kasse genau einmal
  OK   Material nicht doppelt bezahlt
  OK   Bestand unveraendert ohne Produktion
  OK   Jahresabschluss ohne Aufwand veraendert die Kasse nicht

--- Ablauf · Materiallieferung mit Vorlauf ---
  OK   Materialpreis korrekt
  OK   Tagesbedarf korrekt
  OK   Bestellung moeglich
  OK   Zahlung bei Bestellung
  OK   Ware noch nicht im Lager
  OK   Material auf dem Weg
  OK   Ware nach vier Tagen noch nicht da
  OK   Lieferung noch unterwegs
  OK   Ware am Liefertag da
  OK   Kein Material mehr unterwegs
  OK   Reichweite berechenbar
  OK   Sofortkauf moeglich
  OK   Ware sofort im Lager
  OK   Sofortkauf mindert die Kasse
  OK   Zweite Bestellung moeglich
  OK   Materiallieferung im Spielstand

--- Ablauf · Getrennte Materialarten ---
  OK   Zwei Materialarten erkannt
  OK   Stahl wird gebraucht
  OK   Verpackung wird gebraucht
  OK   Stahlpreis korrekt
  OK   Verpackungspreis korrekt
  OK   Stahlbedarf korrekt
  OK   Verpackungsbedarf korrekt
  OK   Stahlkauf moeglich
  OK   Stahl im Lager
  OK   Verpackung unberuehrt
  OK   Kasse nur einmal belastet
  OK   Stahlanlage produziert
  OK   Verpackungsanlage steht still
  OK   Verpackungsanlage produziert jetzt
  OK   Stahlbestand vorhanden
  OK   Verpackungsbestand vorhanden
  OK   Stahlbestand im Spielstand
  OK   Verpackungsbestand im Spielstand

--- Ablauf · Rahmenverträge ---
  OK   Deckungsbeitrag korrekt
  OK   Variable Stueckkosten korrekt
  OK   Preis unter variablen Kosten abgelehnt
  OK   Kein Vertrag angelegt
  OK   Preis ueber variablen Kosten zulaessig
  OK   Grenzvertrag wieder kuendbar
  OK   Grenzvertrag entfernt
  OK   Ueberkapazitaet abgelehnt
  OK   Vertrag geschlossen
  OK   Vertrag in der Liste
  OK   Gesicherte Menge korrekt
  OK   Gesicherter Deckungsbeitrag korrekt
  OK   Vertragsmenge groesser als die Marktnachfrage
  OK   Kuendigung moeglich
  OK   Kuendigungsgebuehr abgebucht
  OK   Vertrag entfernt
  OK   Zweiter Vertrag geschlossen
  OK   Laufzeit um ein Jahr verringert
  OK   Vertrag ausgelaufen
  OK   Vertrag fuer den Spielstand geschlossen
  OK   Vertrag im Spielstand
  OK   Vertragsmenge im Spielstand

--- Ablauf · Mehrstufige Produktionskette ---
  OK   Endstufe ohne Vorstufe produziert nichts
  OK   Leerlauf wird protokolliert
  OK   Vorstufe produziert bedarfsgerecht
  OK   Endstufe produziert ihre Tagesmenge
  OK   Kein Rueckstau im Zwischenlager
  OK   Vorstufe erzeugt kein Endprodukt
  OK   Endstufe wird von der Vorstufe begrenzt
  OK   Zwischenlager im Spielstand

--- Ablauf · Wirtschaftlichkeit der Kette ---
  OK   Ketten-Deckungsbeitrag exakt (18 - 3 - 2x4)
  OK   Variable Kosten der Kette exakt (3 + 2x4)
  OK   Eigenfertigung schlaegt Zukauf zum Verrechnungspreis
  OK   Endstufe allein ist keine Alternative zur Kette
  OK   Teurere Vorstufe senkt den Ketten-Deckungsbeitrag
  OK   Teure Vorstufe exakt (18 - 3 - 2x12)
  OK   Ketten-Kapitalwert exakt (Engpass, zahlungswirksam)
  OK   Endstufe allein gerechnet ueberschaetzt den Wert
  OK   Ketten-Kapitalwert ist positiv
  OK   Die Kette bindet mehr Kapital als die Endstufe allein

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
  OK   Sanitize: Stufen boolesch
  OK   Sanitize: leerer Stand spielbar
  OK   Sanitize: Statistik vorhanden

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

--- Persistenz · Spielstand-Roundtrip ---
  OK   Spielername erhalten
  OK   XP erhalten
  OK   Stufenfortschritt erhalten
  OK   Teilaufgabe erhalten
  OK   Einstellung erhalten
  OK   Tag erhalten
  OK   Jahr erhalten
  OK   Kasse erhalten
  OK   Anlagevermoegen erhalten
  OK   Materialbestand erhalten
  OK   Materialbestand je Art erhalten
  OK   Zwischenlager erhalten
  OK   Reset setzt den Tag zurueck
  OK   Reset setzt die Kasse zurueck
  OK   Reset bindet das Startkapital in der Anlage
  OK   Bilanz nach dem Reset ausgeglichen
  OK   Reset legt die Startanlage an

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

--- Lernen · Zuordnungs- & Ordnungsinhalte ---
  OK   W1/Runde 1 · Zahlungsstromrichtung: Runde mit Kategorien
  OK   W1/Runde 1 · Zahlungsstromrichtung: Runde mit Karten
  OK   W1/Runde 1 · Zahlungsstromrichtung: Karte mit Kategorie
  OK   W1/Runde 1 · Zahlungsstromrichtung: Karte mit Begruendung
  OK   W1/Runde 1 · Zahlungsstromrichtung: Karte mit Kategorie
  OK   W1/Runde 1 · Zahlungsstromrichtung: Karte mit Begruendung
  OK   W1/Runde 1 · Zahlungsstromrichtung: Karte mit Kategorie
  OK   W1/Runde 1 · Zahlungsstromrichtung: Karte mit Begruendung
  OK   W1/Runde 1 · Zahlungsstromrichtung: Karte mit Kategorie
  OK   W1/Runde 1 · Zahlungsstromrichtung: Karte mit Begruendung
  OK   W1/Runde 1 · Zahlungsstromrichtung: Karte mit Kategorie
  OK   W1/Runde 1 · Zahlungsstromrichtung: Karte mit Begruendung
  OK   W1/Runde 2 · Kostenbegriffe: Runde mit Kategorien
  OK   W1/Runde 2 · Kostenbegriffe: Runde mit Karten
  OK   W1/Runde 2 · Kostenbegriffe: Karte mit Kategorie
  OK   W1/Runde 2 · Kostenbegriffe: Karte mit Begruendung
  OK   W1/Runde 2 · Kostenbegriffe: Karte mit Kategorie
  OK   W1/Runde 2 · Kostenbegriffe: Karte mit Begruendung
  OK   W1/Runde 2 · Kostenbegriffe: Karte mit Kategorie
  OK   W1/Runde 2 · Kostenbegriffe: Karte mit Begruendung
  OK   W1/Runde 2 · Kostenbegriffe: Karte mit Kategorie
  OK   W1/Runde 2 · Kostenbegriffe: Karte mit Begruendung
  OK   W1/Runde 2 · Kostenbegriffe: Karte mit Kategorie
  OK   W1/Runde 2 · Kostenbegriffe: Karte mit Begruendung
  OK   W1/Runde 2 · Kostenbegriffe: Karte mit Kategorie
  OK   W1/Runde 2 · Kostenbegriffe: Karte mit Begruendung
  OK   W1/Runde 3 · Kapitalarten: Runde mit Kategorien
  OK   W1/Runde 3 · Kapitalarten: Runde mit Karten
  OK   W1/Runde 3 · Kapitalarten: Karte mit Kategorie
  OK   W1/Runde 3 · Kapitalarten: Karte mit Begruendung
  OK   W1/Runde 3 · Kapitalarten: Karte mit Kategorie
  OK   W1/Runde 3 · Kapitalarten: Karte mit Begruendung
  OK   W1/Runde 3 · Kapitalarten: Karte mit Kategorie
  OK   W1/Runde 3 · Kapitalarten: Karte mit Begruendung
  OK   W1/Runde 3 · Kapitalarten: Karte mit Kategorie
  OK   W1/Runde 3 · Kapitalarten: Karte mit Begruendung
  OK   W1/Runde 3 · Kapitalarten: Karte mit Kategorie
  OK   W1/Runde 3 · Kapitalarten: Karte mit Begruendung
  OK   W1/Prozess-Puzzle · Investitionsentscheidung: Ordnungsaufgabe mit Elementen
  OK   W1/Investitionsrechnungs-Trichter: Runde mit Kategorien
  OK   W1/Investitionsrechnungs-Trichter: Runde mit Karten
  OK   W1/Investitionsrechnungs-Trichter: Karte mit Kategorie
  OK   W1/Investitionsrechnungs-Trichter: Karte mit Begruendung
  OK   W1/Investitionsrechnungs-Trichter: Karte mit Kategorie
  OK   W1/Investitionsrechnungs-Trichter: Karte mit Begruendung
  OK   W1/Investitionsrechnungs-Trichter: Karte mit Kategorie
  OK   W1/Investitionsrechnungs-Trichter: Karte mit Begruendung
  OK   W1/Investitionsrechnungs-Trichter: Karte mit Kategorie
  OK   W1/Investitionsrechnungs-Trichter: Karte mit Begruendung
  OK   W1/Investitionsrechnungs-Trichter: Karte mit Kategorie
  OK   W1/Investitionsrechnungs-Trichter: Karte mit Begruendung
  OK   W1/Investitionsrechnungs-Trichter: Karte mit Kategorie
  OK   W1/Investitionsrechnungs-Trichter: Karte mit Begruendung
  OK   W1/Investitionsrechnungs-Trichter: Karte mit Kategorie
  OK   W1/Investitionsrechnungs-Trichter: Karte mit Begruendung
  OK   W1/Investitionsrechnungs-Trichter: Karte mit Kategorie
  OK   W1/Investitionsrechnungs-Trichter: Karte mit Begruendung
  OK   W2/Fixkosten-Baukasten: Runde mit Kategorien
  OK   W2/Fixkosten-Baukasten: Runde mit Karten
  OK   W2/Fixkosten-Baukasten: Karte mit Kategorie
  OK   W2/Fixkosten-Baukasten: Karte mit Begruendung
  OK   W2/Fixkosten-Baukasten: Karte mit Kategorie
  OK   W2/Fixkosten-Baukasten: Karte mit Begruendung
  OK   W2/Fixkosten-Baukasten: Karte mit Kategorie
  OK   W2/Fixkosten-Baukasten: Karte mit Begruendung
  OK   W2/Fixkosten-Baukasten: Karte mit Kategorie
  OK   W2/Fixkosten-Baukasten: Karte mit Begruendung
  OK   W2/Fixkosten-Baukasten: Karte mit Kategorie
  OK   W2/Fixkosten-Baukasten: Karte mit Begruendung
  OK   W3/Werkzeugkarten zuordnen: Runde mit Kategorien
  OK   W3/Werkzeugkarten zuordnen: Runde mit Karten
  OK   W3/Werkzeugkarten zuordnen: Karte mit Kategorie
  OK   W3/Werkzeugkarten zuordnen: Karte mit Begruendung
  OK   W3/Werkzeugkarten zuordnen: Karte mit Kategorie
  OK   W3/Werkzeugkarten zuordnen: Karte mit Begruendung
  OK   W3/Werkzeugkarten zuordnen: Karte mit Kategorie
  OK   W3/Werkzeugkarten zuordnen: Karte mit Begruendung
  OK   W3/Werkzeugkarten zuordnen: Karte mit Kategorie
  OK   W3/Werkzeugkarten zuordnen: Karte mit Begruendung
  OK   W3/Werkzeugkarten zuordnen: Karte mit Kategorie
  OK   W3/Werkzeugkarten zuordnen: Karte mit Begruendung
  OK   W4/Risiko-Radar: Runde mit Kategorien
  OK   W4/Risiko-Radar: Runde mit Karten
  OK   W4/Risiko-Radar: Karte mit Kategorie
  OK   W4/Risiko-Radar: Karte mit Begruendung
  OK   W4/Risiko-Radar: Karte mit Kategorie
  OK   W4/Risiko-Radar: Karte mit Begruendung
  OK   W4/Risiko-Radar: Karte mit Kategorie
  OK   W4/Risiko-Radar: Karte mit Begruendung
  OK   W4/Risiko-Radar: Karte mit Kategorie
  OK   W4/Risiko-Radar: Karte mit Begruendung
  OK   W4/Risiko-Radar: Karte mit Kategorie
  OK   W4/Risiko-Radar: Karte mit Begruendung
  OK   W4/Zerobond-Typen: Runde mit Kategorien
  OK   W4/Zerobond-Typen: Runde mit Karten
  OK   W4/Zerobond-Typen: Karte mit Kategorie
  OK   W4/Zerobond-Typen: Karte mit Begruendung
  OK   W4/Zerobond-Typen: Karte mit Kategorie
  OK   W4/Zerobond-Typen: Karte mit Begruendung
  OK   W4/Zerobond-Typen: Karte mit Kategorie
  OK   W4/Zerobond-Typen: Karte mit Begruendung
  OK   W5/Cash-Cycle-Zeitstrahl: Ordnungsaufgabe mit Elementen
  OK   W6/Stille-Reserven-Kaskade: Ordnungsaufgabe mit Elementen
  OK   W7/Kapitalerhöhungs-Formen: Runde mit Kategorien
  OK   W7/Kapitalerhöhungs-Formen: Runde mit Karten
  OK   W7/Kapitalerhöhungs-Formen: Karte mit Kategorie
  OK   W7/Kapitalerhöhungs-Formen: Karte mit Begruendung
  OK   W7/Kapitalerhöhungs-Formen: Karte mit Kategorie
  OK   W7/Kapitalerhöhungs-Formen: Karte mit Begruendung
  OK   W7/Kapitalerhöhungs-Formen: Karte mit Kategorie
  OK   W7/Kapitalerhöhungs-Formen: Karte mit Begruendung
  OK   W7/Kapitalerhöhungs-Formen: Karte mit Kategorie
  OK   W7/Kapitalerhöhungs-Formen: Karte mit Begruendung
  OK   W7/Kapitalerhöhungs-Formen: Karte mit Kategorie
  OK   W7/Kapitalerhöhungs-Formen: Karte mit Begruendung
  OK   W8/Kreditleihe oder Geldleihe?: Runde mit Kategorien
  OK   W8/Kreditleihe oder Geldleihe?: Runde mit Karten
  OK   W8/Kreditleihe oder Geldleihe?: Karte mit Kategorie
  OK   W8/Kreditleihe oder Geldleihe?: Karte mit Begruendung
  OK   W8/Kreditleihe oder Geldleihe?: Karte mit Kategorie
  OK   W8/Kreditleihe oder Geldleihe?: Karte mit Begruendung
  OK   W8/Kreditleihe oder Geldleihe?: Karte mit Kategorie
  OK   W8/Kreditleihe oder Geldleihe?: Karte mit Begruendung
  OK   W8/Kreditleihe oder Geldleihe?: Karte mit Kategorie
  OK   W8/Kreditleihe oder Geldleihe?: Karte mit Begruendung
  OK   W8/Kreditleihe oder Geldleihe?: Karte mit Kategorie
  OK   W8/Kreditleihe oder Geldleihe?: Karte mit Begruendung
  OK   W8/Factoring oder Forfaitierung?: Runde mit Kategorien
  OK   W8/Factoring oder Forfaitierung?: Runde mit Karten
  OK   W8/Factoring oder Forfaitierung?: Karte mit Kategorie
  OK   W8/Factoring oder Forfaitierung?: Karte mit Begruendung
  OK   W8/Factoring oder Forfaitierung?: Karte mit Kategorie
  OK   W8/Factoring oder Forfaitierung?: Karte mit Begruendung
  OK   W8/Factoring oder Forfaitierung?: Karte mit Kategorie
  OK   W8/Factoring oder Forfaitierung?: Karte mit Begruendung
  OK   W8/Factoring oder Forfaitierung?: Karte mit Kategorie
  OK   W8/Factoring oder Forfaitierung?: Karte mit Begruendung
  OK   W9/Aktienwert-Treiber: Runde mit Kategorien
  OK   W9/Aktienwert-Treiber: Runde mit Karten
  OK   W9/Aktienwert-Treiber: Karte mit Kategorie
  OK   W9/Aktienwert-Treiber: Karte mit Begruendung
  OK   W9/Aktienwert-Treiber: Karte mit Kategorie
  OK   W9/Aktienwert-Treiber: Karte mit Begruendung
  OK   W9/Aktienwert-Treiber: Karte mit Kategorie
  OK   W9/Aktienwert-Treiber: Karte mit Begruendung
  OK   W9/Aktienwert-Treiber: Karte mit Kategorie
  OK   W9/Aktienwert-Treiber: Karte mit Begruendung
  OK   W9/Aktienwert-Treiber: Karte mit Kategorie
  OK   W9/Aktienwert-Treiber: Karte mit Begruendung
  OK   W9/Aktienwert-Treiber: Karte mit Kategorie
  OK   W9/Aktienwert-Treiber: Karte mit Begruendung
  OK   W9/Fundamentale Aktienbewertung: Ordnungsaufgabe mit Elementen
  OK   12 Zuordnungsrunden vorhanden
  OK   62 Karten vorhanden
  OK   4 Ordnungsaufgaben vorhanden
  OK   Ordnungsaufgaben mit Lösungsweg

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
  OK   Höherer Punktwert zählt
  OK   Niedrigerer Punktwert überschreibt nicht
  OK   Roundtrip XP
  OK   Roundtrip Weltenfortschritt

--- Lernen · Teilaufgaben-Freischaltung ---
  OK   Einzelne Teilaufgabe schaltet die Stufe nicht frei
  OK   Welt W1 hat Teilaufgaben
  OK   Alle Teilaufgaben geloest: Stufe vollstaendig
  OK   Kein doppelter XP-Gewinn
  OK   Fortschritt einer anderen Welt bleibt unberuehrt

--- Lernen · Betriebs-Lab aus echten Daten ---
  OK   Ohne Betrieb keine Betriebsaufgaben
  OK   Kapazitaet korrekt
  OK   Menge korrekt
  OK   Preis je Stueck korrekt
  OK   Variable Kosten je Stueck korrekt
  OK   Deckungsbeitrag je Stueck korrekt
  OK   Betriebsaufgaben erzeugt
  OK   Aufgabe 'betrieb-deckungsbeitrag' hat Felder
  OK   Aufgabe 'betrieb-deckungsbeitrag' hat eine Loesung
  OK   Aufgabe 'betrieb-deckungsbeitrag' hat einen Hinweis
  OK   Aufgabe 'betrieb-deckungsbeitrag' vollstaendig formatiert
  OK   Aufgabe 'betrieb-deckungsbeitrag' ohne doppeltes Waehrungszeichen
  OK   Aufgabe 'betrieb-break-even' hat Felder
  OK   Aufgabe 'betrieb-break-even' hat eine Loesung
  OK   Aufgabe 'betrieb-break-even' hat einen Hinweis
  OK   Aufgabe 'betrieb-break-even' vollstaendig formatiert
  OK   Aufgabe 'betrieb-break-even' ohne doppeltes Waehrungszeichen
  OK   Aufgabe 'betrieb-gesamtkosten' hat Felder
  OK   Aufgabe 'betrieb-gesamtkosten' hat eine Loesung
  OK   Aufgabe 'betrieb-gesamtkosten' hat einen Hinweis
  OK   Aufgabe 'betrieb-gesamtkosten' vollstaendig formatiert
  OK   Aufgabe 'betrieb-gesamtkosten' ohne doppeltes Waehrungszeichen
  OK   Aufgabe 'betrieb-ergebnis' hat Felder
  OK   Aufgabe 'betrieb-ergebnis' hat eine Loesung
  OK   Aufgabe 'betrieb-ergebnis' hat einen Hinweis
  OK   Aufgabe 'betrieb-ergebnis' vollstaendig formatiert
  OK   Aufgabe 'betrieb-ergebnis' ohne doppeltes Waehrungszeichen
  OK   Aufgabe 'betrieb-ekr' hat Felder
  OK   Aufgabe 'betrieb-ekr' hat eine Loesung
  OK   Aufgabe 'betrieb-ekr' hat einen Hinweis
  OK   Aufgabe 'betrieb-ekr' vollstaendig formatiert
  OK   Aufgabe 'betrieb-ekr' ohne doppeltes Waehrungszeichen
  OK   Aufgabe 'betrieb-bilanz' hat Felder
  OK   Aufgabe 'betrieb-bilanz' hat eine Loesung
  OK   Aufgabe 'betrieb-bilanz' hat einen Hinweis
  OK   Aufgabe 'betrieb-bilanz' vollstaendig formatiert
  OK   Aufgabe 'betrieb-bilanz' ohne doppeltes Waehrungszeichen
  OK   Aufgabe 'betrieb-kapitalbedarf' hat Felder
  OK   Aufgabe 'betrieb-kapitalbedarf' hat eine Loesung
  OK   Aufgabe 'betrieb-kapitalbedarf' hat einen Hinweis
  OK   Aufgabe 'betrieb-kapitalbedarf' vollstaendig formatiert
  OK   Aufgabe 'betrieb-kapitalbedarf' ohne doppeltes Waehrungszeichen
  OK   Aufgabe 'betrieb-materialreichweite' hat Felder
  OK   Aufgabe 'betrieb-materialreichweite' hat eine Loesung
  OK   Aufgabe 'betrieb-materialreichweite' hat einen Hinweis
  OK   Aufgabe 'betrieb-materialreichweite' vollstaendig formatiert
  OK   Aufgabe 'betrieb-materialreichweite' ohne doppeltes Waehrungszeichen
  OK   Deckungsbeitrag der Aufgabe stimmt
  OK   Gesamter Deckungsbeitrag der Aufgabe stimmt
  OK   Deckungsbeitragsaufgabe vorhanden
  OK   Break-even der Aufgabe stimmt
  OK   Break-even-Aufgabe vorhanden
  OK   Bilanz der Aufgabe geht auf
  OK   Bilanzaufgabe vorhanden
  OK   Aufgabe zuerst ungeloest
  OK   Aufgabe nach dem Markieren geloest
  OK   Zaehloest

--- Berater · Grundbefunde ---
  OK   Berater laesst sich instanziieren
  OK   Ohne Anlage wird die fehlende Produktion gemeldet
  OK   Zu geringe Auslastung wird erkannt
  OK   Der Hinweis nennt die Auslastung als Zahl
  OK   Kapazitätsgrenze wird erkannt
  OK   Dünne Kasse wird erkannt
  OK   Überzogene Kasse wird erkannt

--- Berater · Frage statt fertiger Antwort ---
  OK   Berater laesst sich instanziieren
  OK   Jeder Hinweis stellt mindestens eine Frage
  OK   Jeder Hinweis nennt eine Lektion
  OK   Jeder Hinweis nennt einen konkreten Ort im Menü
  OK   Die Lektion erklärt den Zusammenhang statt der Handlung

--- Berater · Nachfrage gegen Kapazität ---
  OK   Berater laesst sich instanziieren
  OK   Nachfrage über Kapazität wird erkannt
  OK   Der Hinweis nennt Bedarf und Kapazität
  OK   Kapazität über Nachfrage wird erkannt
  OK   Bei passender Nachfrage kein Hinweis

--- Berater · Produktionskette ---
  OK   Berater laesst sich instanziieren
  OK   Fehlender Zulieferer wird gemeldet
  OK   Ohne Rueckstau kein Kettenhinweis
  OK   Rückstau wird gemeldet

--- Berater · Fahrplan mit Zielzahl ---
  OK   Berater laesst sich instanziieren
  OK   Bei geringer Auslastung nennt der Fahrplan die Auslastung
  OK   Der Fahrplan nennt eine Zielzahl
  OK   Der Fahrplan stellt eine Frage
  OK   Bei dünnner Kasse nennt der Fahrplan die Reserve
  OK   Bei guter Lage nennt der Fahrplan die Investition

--- Berater · Finanzierungsbefunde ---
  OK   Ungenutzter Kreditrahmen wird erkannt
  OK   Befundtext vollstaendig formatiert (kein %s uebrig)
  OK   Befundtext nennt den Kreditrahmen
  OK   Befundtext ohne doppeltes Waehrungszeichen
  OK   Hohe Verschuldung wird erkannt
  OK   Leverage-Befund vollstaendig formatiert
  OK   Leverage-Befund ohne doppeltes Waehrungszeichen

--- Langzeit · 10 Jahre Grundbetrieb ---
  OK   3.600 Tage simuliert
  OK   Zehn Jahresabschluesse
  OK   Alle Groessen endlich (Grundbetrieb)
  OK   Betrieb bleibt liquide
  OK   Eigenkapital bleibt positiv
  OK   Kasse waechst ueber zehn Jahre
  OK   Eigenkapital waechst ueber zehn Jahre
  OK   Umsatz bleibt unter der Kapazitaetsgrenze
  OK   Umsatz entstanden
  OK   Auftraege wurden erfuellt
  OK   Bilanz stimmt nach zehn Jahren
  OK   Roundtrip: Kasse
  OK   Roundtrip: Eigenkapital
  OK   Roundtrip: Tag

--- Langzeit · 10 Jahre mit Finanzierung ---
  OK   Darlehen zum Start aufgenommen
  OK   Ausschuettungsquote gesetzt
  OK   Alle Groessen endlich (finanziert)
  OK   Finanzierter Betrieb bleibt liquide
  OK   Eigenkapital uebersteht Schuldendienst und Dividende
  OK   Darlehen nach Laufzeit getilgt
  OK   Keine Restschuld aus dem Darlehen
  OK   Dividenden sind geflossen
  OK   Bilanz stimmt (finanziert)
  OK   FK-Quote im gueltigen Bereich

========================================
ERGEBNIS: 922 bestanden, 0 fehlgeschlagen
========================================
```

## Testbericht
```
{
  "failed": 0,
  "failures": [],
  "passed": 922,
  "timestamp": "2026-11-21T12:20:16",
  "total": 922
}```
