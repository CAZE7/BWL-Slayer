/* ============================================================
   src/data2.js – Welten 4 bis 8
   ============================================================ */
(function () {
  'use strict';
  const R = (x, d) => (x).toLocaleString('de-DE', { minimumFractionDigits: d === undefined ? 2 : d, maximumFractionDigits: d === undefined ? 2 : d });

  /* ---------------- WELT 4: ANLEIHEN ---------------- */
  const W4 = {
    id: 'W4', no: 4, side: 'INV', color: '#fbbf24', icon: '📜',
    title: 'Festverzinsliche Wertpapiere',
    tag: 'Bond-Desk & Arbitrage-Labor',
    sources: '4. Anleihen.pdf (Folien 1–71)',
    briefing: [
      { h: 'Merkmale einer Anleihe', p: '30-jährige Bundesanleihe 2005/2037: Volumen 28,25 Mrd. €, Kupon 4,00 %, Zinsberechnung actual/actual ICMA. Grüne Bundesanleihen (seit 2020) werden als Zwillingsanleihen begeben; das „Greenium“ ist der negative Rendite-Spread bzw. höhere Kurs grüner Anleihen.' },
      { h: 'Bewertung', p: 'PV = Σ CP_t/(1+y)^t + FV_T/(1+y)^T. Bei flacher Zinsstruktur diskontiert man mit einer einheitlichen Rendite; bei laufzeitabhängigen Kassazinssätzen (Spot Rates) je Periode mit dem passenden Zinssatz.' },
      { h: 'Effektivverzinsung (YTM)', p: 'Liegt der Kurs unter pari, ist die YTM größer als der Kuponzins – die laufende Verzinsung (Kupon/Kurs) plus der Tilgungsgewinn ergeben die Gesamtrendite. Rechnerisch: Nullstelle des NPV, z. B. per Sekante.' },
      { h: 'Duration', p: 'Macauley-Duration D = Σ t·PV(CF_t)/PV₀ (barwertgewichtete Restlaufzeit). Modified Duration MD = D/(1+y₀) gibt die relative Kursänderung bei Zinsänderung an: ΔPV/PV ≈ −MD · Δy.' }
    ],
    concept: {
      title: 'Pari-Scanner & Risiko-Radar',
      intro: 'Kurs-Gefühl und Risiko-Zuordnung, bevor gerechnet wird.',
      items: [
        {
          kind: 'quiz',
          title: 'Pari-Scanner',
          questions: [
            { q: 'Eine 4-%-Anleihe notiert bei 98 €. Die YTM ist …', options: ['kleiner als 4 %', 'genau 4 %', 'größer als 4 %'], a: 2, why: 'Unter pari → zusätzlicher Tilgungsgewinn (98 → 100) → YTM > Kupon.' },
            { q: 'Wie ändert sich der Kurs einer Anleihe, wenn der Marktzins steigt?', options: ['Er steigt', 'Er fällt', 'Er bleibt gleich'], a: 1, why: 'Die künftigen Zahlungen werden stärker abgezinst.' },
            { q: 'Was bezeichnet das „Greenium“?', options: ['Einen Renditeaufschlag grüner Anleihen', 'Einen negativen Rendite-Spread bzw. höheren Kurs grüner Anleihen', 'Die Prämie für die grüne Bundesanleihe bei Emission'], a: 1, why: 'Grüne Anleihen rentieren etwas niedriger (höherer Kurs) – der sog. Greenium.' },
            { q: 'Eine inverse Zinsstrukturkurve …', options: ['signalisiert häufig eine Rezession', 'gilt als Normalfall', 'bedeutet, dass kurzfristige Zinsen niedriger sind als langfristige'], a: 0, why: 'Inverse Strukturen (kurz > lang) gelten als Rezessionsindikator.' }
          ]
        },
        {
          kind: 'sort',
          title: 'Risiko-Radar',
          rounds: [{
            title: 'Welches Risiko?',
            categories: [{ id: 'ZINS', label: 'Zinsänderungsrisiko' }, { id: 'WÄHR', label: 'Währungsrisiko' }, { id: 'INFL', label: 'Inflationsrisiko' }, { id: 'INS', label: 'Insolvenzrisiko' }],
            cards: [
              { text: 'Lange Restlaufzeit, Marktzins steigt um 1 %', cat: 'ZINS', why: 'Die Sensitivität wächst mit der Duration.' },
              { text: '4-jährige USD-Anleihe, Kupon in Dollar', cat: 'WÄHR', why: 'Umrechnung zum Wechselkurs EUR/USD schwankt.' },
              { text: 'Kaufkraft der Kuponzahlungen sinkt', cat: 'INFL', why: 'Schutz: inflationsindexierte Anleihen.' },
              { text: 'Rating verschlechtert sich von BBB- auf BB+', cat: 'INS', why: 'Ab BB+/Ba1: Non-Investment Grade / Junk Bond.' },
              { text: 'Absicherung über Währungsswaps oder Optionen', cat: 'WÄHR', why: 'Hedging des Wechselkursrisikos.' }
            ]
          }]
        },
        {
          kind: 'sort',
          title: 'Zerobond-Typen',
          rounds: [{
            title: 'Diskontpapier oder Zinssammler?',
            categories: [{ id: 'D', label: 'Diskontpapier' }, { id: 'Z', label: 'Zinssammler' }],
            cards: [
              { text: 'Erwerb zu 93 €, Rückzahlung 100 €', cat: 'D', why: 'Abschlag (Disagio) unter pari, keine laufenden Zinsen.' },
              { text: 'Erwerb zu 100 €, Rückzahlung 103 €', cat: 'Z', why: 'Zinsen werden thesauriert und mit der Rückzahlung ausgekehrt.' },
              { text: 'Rendite entsteht ausschließlich aus der Differenz Erwerbs-/Rückzahlungskurs', cat: 'D', why: 'Charakteristikum des Diskontpapiers (z. B. Treasury Bill).' }
            ]
          }]
        }
      ]
    },
    lab: {
      title: 'Rechen-Labor · Pricing, Spots & Duration',
      intro: 'Vom Barwert bis zur Kursänderung.',
      tasks: [
        {
          id: 'w4t1',
          prompt: '<b>Hamburg AG:</b> Nennwert 100 €, Kupon 6 %, 3 Jahre Restlaufzeit. Bewerte bei 2 % und 5 % Marktzins; danach bei nur 1 Jahr Restlaufzeit.',
          given: 'PV = Σ CP/(1+y)<sup>t</sup> + FV/(1+y)<sup>T</sup>',
          fields: [
            { key: 'pv2', label: 'Preis bei 2 % (3 Jahre)', ans: 111.54, unit: '€', tol: 0.02 },
            { key: 'pv5', label: 'Preis bei 5 % (3 Jahre)', ans: 102.72, unit: '€', tol: 0.02 },
            { key: 'pv2_1', label: 'Preis bei 2 % (1 Jahr)', ans: 103.92, unit: '€', tol: 0.02 },
            { key: 'pv5_1', label: 'Preis bei 5 % (1 Jahr)', ans: 100.95, unit: '€', tol: 0.02 }
          ],
          solution: '3 Jahre: 6/1,02 + 6/1,02² + 106/1,02³ = 111,54 €; bei 5 %: 102,72 €. 1 Jahr: 106/1,02 = 103,92 €; 106/1,05 = 100,95 €. Je kürzer die Restlaufzeit, desto geringer die Zinssensitivität.'
        },
        {
          id: 'w4t2',
          prompt: '<b>Yield-to-Maturity.</b> Eine 3-jährige 4-%-Kuponanleihe (Nennwert 100 €) notiert bei 98 €. Testzinssätze: 4 % (NPV +2,00) und 5 % (NPV −0,72).',
          given: 'i* = i₁ + NPV₁ · (i₂ − i₁)/(NPV₁ − NPV₂)',
          fields: [
            { key: 'richtung', type: 'choice', label: 'YTM im Verhältnis zum Kupon', options: ['YTM < 4 %', 'YTM = 4 %', 'YTM > 4 %'], ans: 'YTM > 4 %' },
            { key: 'ytm', label: 'YTM (Sekante)', ans: 4.73, unit: '%', tol: 0.02 }
          ],
          solution: 'Unter-pari-Notierung → YTM > 4 %. Rechnung: 4 % + 2,00 · 1/(2,00 + 0,72) = 4,73 %. Die laufende Verzinsung allein (4/98 = 4,08 %) unterschätzt die Gesamtrendite.'
        },
        {
          id: 'w4t3',
          prompt: '<b>Zinsstrukturkurve.</b> Zerobonds: A (1 Jahr, 94 €), B (2 Jahre, 82 €), C (3 Jahre, 70 €), Rückzahlung jeweils 100 €. Berechne die Kassazinssätze und bewerte anschließend eine 3-jährige 8-%-Kuponanleihe.',
          given: 'ytm<sub>0,T</sub> = (FV/PV)<sup>1/T</sup> − 1',
          fields: [
            { key: 'r1', label: 'Spot Rate 1 Jahr', ans: 6.38, unit: '%', tol: 0.02 },
            { key: 'r2', label: 'Spot Rate 2 Jahre', ans: 10.43, unit: '%', tol: 0.02, hint: '√(100/82) − 1, Wurzel ziehen!' },
            { key: 'r3', label: 'Spot Rate 3 Jahre', ans: 12.62, unit: '%', tol: 0.02 },
            { key: 'pv', label: 'Preis der 8-%-Kuponanleihe', ans: 89.69, unit: '€', tol: 0.05 }
          ],
          solution: 'r₁ = 6,38 %, r₂ = 10,43 %, r₃ = 12,62 % (normale, steigende Struktur). PV = 8/1,0638 + 8/1,1043² + 108/1,1262³ = 89,69 €.'
        },
        {
          id: 'w4t4',
          prompt: '<b>Duplikation.</b> Eine 3-jährige 2-%-Kuponanleihe (2, 2, 102) soll aus Zerobonds mit Nennwert 1 € nachgebaut werden: ZB₁ = 0,94 €, ZB₂ = 0,87 €, ZB₃ = 0,70 €.',
          given: 'Law of One Price: gleicher Zahlungsstrom → gleicher Preis',
          fields: [
            { key: 'pv', label: 'Faire Preis der Kuponanleihe', ans: 75.02, unit: '€', tol: 0.02 },
            { key: 'n3', label: 'Anzahl benötigter ZB₃ (Nennwert 1 €)', ans: 102, unit: 'Stück', tol: 0.01 },
            { key: 'arb', type: 'choice', label: 'Notiert die Anleihe bei 76 €, dann …', options: ['ist alles im Gleichgewicht', 'gibt es eine Arbitragegelegenheit (short Anleihe, long Duplikationsportfolio)', 'ist die Anleihe unterbewertet'], ans: 'gibt es eine Arbitragegelegenheit (short Anleihe, long Duplikationsportfolio)' }
          ],
          solution: '2·0,94 + 2·0,87 + 102·0,70 = 1,88 + 1,74 + 71,40 = 75,02 €. Jeder andere Preis erzeugt Arbitrage.'
        },
        {
          id: 'w4t5',
          prompt: '<b>Duration-Wippe.</b> 4-jährige Kuponanleihe: Nennwert 1.000 €, Kupon 5 %, Marktzins 5,5 %.',
          given: 'D = Σ t·PV(CF_t)/PV₀,  MD = D/(1+y₀),  ΔPV/PV ≈ −MD·Δy',
          fields: [
            { key: 'pv', label: 'Barwert', ans: 982.47, unit: '€', tol: 0.05 },
            { key: 'd', label: 'Macauley-Duration', ans: 3.72, unit: 'Jahre', tol: 0.01 },
            { key: 'md', label: 'Modified Duration', ans: 3.53, unit: '%', tol: 0.01 },
            { key: 'dpv', label: 'Absolute Kursänderung bei Δy = +1 %', ans: -34.65, unit: '€', tol: 0.15, traps: [{ v: 34.65, tol: 0.2, msg: 'Steigender Marktzins senkt den Kurs – das Vorzeichen ist negativ.' }] }
          ],
          solution: 'PV₀ = 982,47 €, D = 3,72 Jahre, MD = 3,72/1,055 = 3,53. Bei Δy = +1 %: −3,53 % · 982,47 = −34,65 € (Folie: −34,68 €, Rundungsdifferenz).'
        }
      ]
    },
    trainer: {
      title: 'Endlos-Trainer · Bond-Pricing & Duration',
      intro: 'Zufällige Anleihen – Preis und Duration.',
      gen: function () {
        const fv = [100, 1000][Math.floor(Math.random() * 2)];
        const coupon = [2, 3, 4, 5, 6, 8][Math.floor(Math.random() * 6)] / 100;
        const mat = 2 + Math.floor(Math.random() * 5);
        const y = [2, 3, 4, 5, 6, 7][Math.floor(Math.random() * 6)] / 100;
        const pv = FIN.bondPV(fv, coupon, mat, y);
        const d = FIN.duration(fv, coupon, mat, y);
        return {
          prompt: 'Anleihe: Nennwert ' + R(fv, 0) + ' €, Kupon ' + R(coupon * 100, 1) + ' %, Restlaufzeit ' + mat + ' Jahre, Marktzins ' + R(y * 100, 1) + ' %.',
          given: 'PV = Σ CF/(1+y)<sup>t</sup>',
          fields: [
            { key: 'pv', label: 'Barwert', ans: pv, unit: '€', tol: Math.max(0.05, pv * 0.002) },
            { key: 'status', type: 'choice', label: 'Notierung', options: ['über pari', 'zu pari', 'unter pari'], ans: coupon > y ? 'über pari' : coupon < y ? 'unter pari' : 'zu pari' },
            { key: 'd', label: 'Macauley-Duration', ans: d.macauleyDuration, unit: 'Jahre', tol: 0.02 }
          ],
          solution: 'PV = ' + R(pv) + ' € (' + (coupon > y ? 'über' : coupon < y ? 'unter' : 'zu') + ' pari), D = ' + R(d.macauleyDuration) + ' Jahre, MD = ' + R(d.modifiedDuration) + '.'
        };
      }
    }
  };

  /* ---------------- WELT 5: FINANZPLANUNG ---------------- */
  const W5 = {
    id: 'W5', no: 5, side: 'FIN', color: '#22d3ee', icon: '📊',
    title: 'Finanzplanung & Finanzkontrolle',
    tag: 'Working-Capital-Defense & Du-Pont-Reaktor',
    sources: 'Finanzierungsteil (2).pdf, Kap. 2.0–2.2 (Folien 26–48)',
    briefing: [
      { h: 'Kapitalbindung im Umlaufvermögen', p: 'Kapitalbindungsdauer = Lagerzeit Material + Produktionszeit + Lagerzeit Fertiggüter + Debitorenfrist − Lieferantenzahlungsziel. Multipliziert mit den durchschnittlichen Produktionskosten pro Tag ergibt sich der Kapitalbedarf.' },
      { h: 'Du-Pont-Kennzahlensystem', p: 'ROI = Umsatzrendite × Kapitalumschlag = [(Gewinn + FK-Zinsen)/Umsatz] × [Umsatz/Ø Gesamtkapital]. Der Baum macht sichtbar, welche Stellschraube den ROI treibt.' },
      { h: 'Liquiditätskennzahlen', p: 'Liquiditätsgrad 2 (Quick Ratio) = (liquide Mittel + Geldforderungen)/kfr. FK → Soll > 100 %. Liquiditätsgrad 3 (Current Ratio) = Umlaufvermögen/kfr. FK → Sollkorridor 150–200 %.' },
      { h: 'Kapitalflussrechnung', p: 'Operativer CF (indirekt): Jahresüberschuss ± Veränderung des Working Capital. Investiver CF (direkt): Auszahlungen für Anlagevermögen. Finanzierungs-CF: Ein-/Auszahlungen von Kapitalgebern. Summe = Veränderung des Finanzmittelfonds.' }
    ],
    concept: {
      title: '90-Tage-Lücke & Kennzahlen-Ampel',
      intro: 'Liquidität ist eine Nebenbedingung – aber eine harte.',
      items: [
        {
          kind: 'order',
          title: 'Cash-Cycle-Zeitstrahl',
          prompt: 'Ordne den Weg vom Materialeingang bis zum Geldrückfluss (Klick = anhängen).',
          items: [
            { id: 'a', text: 'Lagerzeit Material (25 Tage)' },
            { id: 'b', text: 'Produktionszeit (20 Tage)' },
            { id: 'c', text: 'Lagerzeit Fertiggüter (30 Tage)' },
            { id: 'd', text: 'Debitorenfrist (45 Tage)' },
            { id: 'e', text: 'abzüglich Lieferantenzahlungsziel (30 Tage)' }
          ],
          solution: '25 + 20 + 30 + 45 = 120 Tage bis zum Geldeingang, minus 30 Tage Zahlungsziel = 90 Tage Kapitalbindung.'
        },
        {
          kind: 'quiz',
          title: 'Bilanz-Cockpit',
          questions: [
            { q: 'Der Anlagendeckungsgrad II liegt bei 116 %. Wie ist das zu bewerten?', options: ['Zu niedrig – Regelwert 120–160 % für Produktionsunternehmen', 'Zu hoch – Regelwert 90–120 %', 'Genau richtig'], a: 0, why: 'AD II (EK + lfr. FK)/AV sollte bei Produktionsunternehmen 120–160 % erreichen (AD I: 90–120 %).' },
            { q: 'Welche Kennzahl misst die Fristenkongruenz?', options: ['Verschuldungsgrad', 'Deckungsgrad', 'Umsatzrendite'], a: 1, why: 'Deckungsgrade setzen langfristiges Kapital ins Verhältnis zum Anlagevermögen.' },
            { q: 'Der ROI nach Du Pont steigt, wenn …', options: ['die Umsatzrendite steigt oder der Kapitalumschlag steigt', 'nur die FK-Zinsen steigen', 'das Gesamtkapital steigt'], a: 0, why: 'ROI = Umsatzrendite × Kapitalumschlag.' },
            { q: 'Ein negativer Cashflow aus investiver Tätigkeit bedeutet …', options: ['eine Krise', 'Auszahlungen für Investitionen – bei wachsendem Unternehmen normal', 'einen Rechenfehler'], a: 1, why: 'Investitionen führen zunächst zu Mittelabflüssen.' }
          ]
        }
      ]
    },
    lab: {
      title: 'Rechen-Labor · Kapitalbedarf, Kennzahlen, Cashflow',
      intro: 'Die Delizioso AG unter Liquiditätsdruck.',
      tasks: [
        {
          id: 'w5t1',
          prompt: '<b>Die 90-Tage-Lücke.</b> Lagerzeit Material 25 Tage, Produktionszeit 20 Tage, Lagerzeit Fertiggüter 30 Tage, Debitorenfrist 45 Tage, Lieferantenzahlungsziel 30 Tage. Durchschnittliche Produktionskosten: 12.000 €/Tag.',
          given: 'Kapitalbedarf = Kapitalbindungsdauer × Kosten pro Tag',
          fields: [
            { key: 'tage', label: 'Kapitalbindungsdauer', ans: 90, unit: 'Tage', tol: 0.01, traps: [{ v: 120, tol: 0.01, msg: 'Das Lieferantenzahlungsziel von 30 Tagen verkürzt die Bindung: 120 − 30 = 90 Tage.' }] },
            { key: 'bedarf', label: 'Kapitalbedarf Umlaufvermögen', ans: 1080000, unit: '€', tol: 1 }
          ],
          solution: '120 Tage Umschlagdauer − 30 Tage Zahlungsziel = 90 Tage. 90 · 12.000 € = 1.080.000 € dauerhaft zu finanzierender Kapitalbedarf.'
        },
        {
          id: 'w5t2',
          prompt: '<b>Du-Pont-Reaktor.</b> Umsatz 2.000.000 €, Gewinn 80.000 €, FK-Zinsen 40.000 €, Ø Gesamtkapital 1.000.000 €.',
          given: 'ROI = (Gewinn + FK-Zinsen)/Umsatz × Umsatz/Ø GK',
          fields: [
            { key: 'ur', label: 'Umsatzrendite', ans: 6, unit: '%', tol: 0.01 },
            { key: 'ku', label: 'Kapitalumschlag', ans: 2, unit: '×', tol: 0.01 },
            { key: 'roi', label: 'ROI', ans: 12, unit: '%', tol: 0.01, traps: [{ v: 4, tol: 0.01, msg: 'Nur der Reingewinn (80.000) wird zur Umsatzrendite? Nein: (Gewinn + FK-Zinsen)/Umsatz = 120.000/2.000.000 = 6 % → ROI = 6 % · 2 = 12 %.' }] }
          ],
          solution: 'Umsatzrendite = 120.000/2.000.000 = 6 %, Kapitalumschlag = 2.0 → ROI = 12 %.'
        },
        {
          id: 'w5t3',
          prompt: '<b>Bilanzkennzahlen.</b> Bilanz (Mio. €): AV 300, Vorräte 100, Forderungen 70, liquide Mittel 30; EK 200, lfr. FK 150, kfr. FK 150.',
          given: 'LG2 = (liquide + Forderungen)/kfr. FK · 100, LG3 = UV/kfr. FK · 100, AD I = EK/AV · 100, AD II = (EK + lfr. FK)/AV · 100',
          fields: [
            { key: 'lg2', label: 'Liquiditätsgrad 2', ans: 66.67, unit: '%', tol: 0.02 },
            { key: 'lg3', label: 'Liquiditätsgrad 3', ans: 133.33, unit: '%', tol: 0.02 },
            { key: 'ad1', label: 'Anlagendeckungsgrad I', ans: 66.67, unit: '%', tol: 0.02 },
            { key: 'ad2', label: 'Anlagendeckungsgrad II', ans: 116.67, unit: '%', tol: 0.02 },
            { key: 'verdict', type: 'choice', label: 'Gesamturteil', options: ['Alle Zielwerte erfüllt', 'Liquidität und AD I unter Soll – Handlungsbedarf', 'Nur der AD II ist zu hoch'], ans: 'Liquidität und AD I unter Soll – Handlungsbedarf' }
          ],
          solution: 'LG2 = 66,67 % (< 100 %), LG3 = 133,33 % (< 150 %), AD I = 66,67 % (< 90 %), AD II = 116,67 % (knapp unter 120 %). Die Fristenkongruenz ist nicht durchgängig gesichert.'
        },
        {
          id: 'w5t4',
          prompt: '<b>Cashflow-Brücke.</b> Bilanz t₁ → t₂ (Mio. €): AV 10 → 15, Vorräte 20 → 30, Liquide 35 → 50, Bilanzsumme 65 → 95; Gezeichnetes Kapital 20 → 20, Jahresüberschuss 0 → 25, Verbindlichkeiten 45 → 50.',
          given: 'CF operativ (indirekt) = JÜ ± Δ Working Capital',
          fields: [
            { key: 'op', label: 'Cashflow operativ', ans: 15, unit: 'Mio. €', tol: 0.01, traps: [{ v: 25, tol: 0.01, msg: 'Die Vorratserhöhung von 10 bindet Liquidität: 25 − 10 = 15.' }] },
            { key: 'inv', label: 'Cashflow investiv', ans: -5, unit: 'Mio. €', tol: 0.01 },
            { key: 'fin', label: 'Cashflow Finanzierung', ans: 5, unit: 'Mio. €', tol: 0.01 },
            { key: 'end', label: 'Endbestand Finanzmittelfonds', ans: 50, unit: 'Mio. €', tol: 0.01 }
          ],
          solution: 'Operativ: 25 − 10 = +15; investiv: −5 (AV +5); Finanzierung: +5 (Verbindlichkeiten +5). Summe +15; 35 + 15 = 50 ✓'
        }
      ]
    },
    trainer: {
      title: 'Endlos-Trainer · Kennzahlen-Mix',
      intro: 'Liquidität, Deckung und ROI mit Zufallszahlen.',
      gen: function () {
        const liq = (5 + Math.floor(Math.random() * 30)) * 10;
        const ford = (5 + Math.floor(Math.random() * 30)) * 10;
        const vor = (10 + Math.floor(Math.random() * 40)) * 10;
        const kfk = (10 + Math.floor(Math.random() * 40)) * 10;
        const ek = (10 + Math.floor(Math.random() * 40)) * 10;
        const lfk = (10 + Math.floor(Math.random() * 30)) * 10;
        const av = (10 + Math.floor(Math.random() * 40)) * 10;
        return {
          prompt: 'Bilanz (T€): Liquide ' + liq + ', Forderungen ' + ford + ', Vorräte ' + vor + ', AV ' + av + '; EK ' + ek + ', lfr. FK ' + lfk + ', kfr. FK ' + kfk + '.',
          given: 'LG2 = (liq + Ford)/kfr. FK · 100 · AD I = EK/AV · 100',
          fields: [
            { key: 'lg2', label: 'Liquiditätsgrad 2', ans: ((liq + ford) / kfk) * 100, unit: '%', tol: 0.05 },
            { key: 'lg3', label: 'Liquiditätsgrad 3', ans: ((liq + ford + vor) / kfk) * 100, unit: '%', tol: 0.05 },
            { key: 'ad1', label: 'Anlagendeckungsgrad I', ans: (ek / av) * 100, unit: '%', tol: 0.05 }
          ],
          solution: 'LG2 = ' + R(((liq + ford) / kfk) * 100) + ' %, LG3 = ' + R(((liq + ford + vor) / kfk) * 100) + ' %, AD I = ' + R((ek / av) * 100) + ' %.'
        };
      }
    }
  };

  /* ---------------- WELT 6: INNENFINANZIERUNG ---------------- */
  const W6 = {
    id: 'W6', no: 6, side: 'FIN', color: '#4ade80', icon: '🏭',
    title: 'Innenfinanzierung',
    tag: 'Lohmann-Ruchti-Fabrik & Stille-Reserven-Tresor',
    sources: 'Finanzierungsteil (2).pdf, Kap. 3.1 (Folien 49–71)',
    briefing: [
      { h: 'Kapitalfreisetzungseffekt', p: 'Abschreibungen sind Aufwand, aber keine Auszahlung. Über die Umsatzerlöse fließen die Abschreibungsgegenwerte als liquide Mittel zurück (Vermögensumschichtung).' },
      { h: 'Kapazitätserweiterungseffekt', p: 'Werden die freigesetzten Mittel sofort in gleichartige Anlagen reinvestiert, wächst die Kapazität – bei 10 Maschinen, 5 Jahren Nutzungsdauer und Reinvestition steigt der Bestand bis auf 20 Maschinen (Lohmann-Ruchti-Effekt).' },
      { h: 'Grenzen in der Praxis', p: 'Fehlende Teilbarkeit vernetzter Fertigungsstufen, steigende Wiederbeschaffungspreise, technischer Fortschritt, zusätzlicher Finanzierungsbedarf für das Umlaufvermögen, ausbleibende Nachfrage.' },
      { h: 'Stille Selbstfinanzierung', p: 'Bildung stiller Reserven über Unterbewertung der Aktiva (hohe Abschreibungen, Ansatz zu Einkaufspreis) oder Überbewertung der Passiva (überhöhte Rückstellungen) → Steuerstundungseffekt.' }
    ],
    concept: {
      title: 'Fabrik-Puzzle & Rückstellungs-Uhr',
      intro: 'Wer finanziert hier wen – und wann?',
      items: [
        {
          kind: 'quiz',
          title: 'Innenfinanzierung verstehen',
          questions: [
            { q: 'Abschreibungen sind …', options: ['Auszahlungen', 'Aufwand ohne Auszahlung, aber mit Mittelfreisetzung über den Umsatz', 'Einzahlungen'], a: 1, why: 'Der Abschreibungsgegenwert fließt über die Umsatzerlöse als Zahlungsmittel zurück.' },
            { q: 'Welche Rückstellung hat den größten Finanzierungseffekt?', options: ['Urlaubsrückstellungen (kurzfristig)', 'Prozessrückstellungen (mittelfristig)', 'Pensionsrückstellungen (langfristig)'], a: 2, why: 'Je länger die Fristigkeit, desto länger steht das Geld zur Verfügung.' },
            { q: 'Offene Selbstfinanzierung bedeutet …', options: ['Einstellung versteuerter Gewinne in die Gewinnrücklagen', 'Bildung stiller Reserven', 'Ausgabe junger Aktien'], a: 0, why: 'Sichtbar im Jahresabschluss; die Kapitalrücklage aus Agio gehört dagegen zur Außenfinanzierung.' },
            { q: 'Factoring ist …', options: ['Vermögensumschichtung (Kapitalfreisetzung)', 'Selbstfinanzierung', 'Beteiligungsfinanzierung'], a: 0, why: 'Forderungen werden verkauft – es wird Vermögen umgeschichtet, nicht neu zugeführt.' }
          ]
        },
        {
          kind: 'order',
          title: 'Stille-Reserven-Kaskade',
          prompt: 'Ordne den Mechanismus der stillen Selbstfinanzierung.',
          items: [
            { id: 'a', text: 'Bilanzielle Wahlrechte nutzen (z. B. kürzere Nutzungsdauer)' },
            { id: 'b', text: 'Aktiva unterbewerten / Passiva überbewerten' },
            { id: 'c', text: 'Periodengewinn und Steuerbemessungsgrundlage sinken' },
            { id: 'd', text: 'Steuerzahlung wird gestundet (Liquiditätsvorteil)' },
            { id: 'e', text: 'Stille Reserve entsteht, wird bei Verkauf/Auflösung aufgedeckt' }
          ],
          solution: 'Wahlrecht → Bewertung → geringerer Gewinn/Steuer → Steuerstundung → stille Reserve.'
        }
      ]
    },
    lab: {
      title: 'Rechen-Labor · Lohmann-Ruchti & stille Reserven',
      intro: 'Start: 10 Maschinen à 5.000 €, lineare AfA über 5 Jahre, jährliche AfA 1.000 €/Maschine, Kapazität 10.000 Stück je Maschine.',
      tasks: [
        {
          id: 'w6t1',
          prompt: '<b>Jahr 1 der Lohmann-Ruchti-Fabrik.</b> Wie viel AfA wird freigesetzt, wie viele Maschinen werden gekauft und wie viel Kasse bleibt?',
          given: 'Neukauf = ⌊verfügbare Mittel / 5.000 €⌋',
          fields: [
            { key: 'afa', label: 'Freigesetzte Abschreibung Jahr 1', ans: 10000, unit: '€', tol: 0.01 },
            { key: 'kauf', label: 'Neukauf Maschinen', ans: 2, unit: 'Stück', tol: 0.01 },
            { key: 'rest', label: 'Restbetrag', ans: 0, unit: '€', tol: 0.01 }
          ],
          solution: '10 Maschinen · 1.000 € = 10.000 € → 2 neue Maschinen (10.000 €), kein Rest.'
        },
        {
          id: 'w6t2',
          prompt: '<b>Jahr 3.</b> Bestand 14 Maschinen, Vorjahres-Rest 2.000 €. Wie viel ist verfügbar, wie viele Maschinen werden gekauft, wie hoch ist der Rest?',
          fields: [
            { key: 'avail', label: 'Verfügbare Mittel', ans: 16000, unit: '€', tol: 0.01, traps: [{ v: 14000, tol: 0.01, msg: 'Der Kassenrest des Vorjahres (2.000 €) wird addiert: 14.000 + 2.000 = 16.000 €.' }] },
            { key: 'kauf', label: 'Neukauf Maschinen', ans: 3, unit: 'Stück', tol: 0.01 },
            { key: 'rest', label: 'Restbetrag', ans: 1000, unit: '€', tol: 0.01 }
          ],
          solution: '14 · 1.000 = 14.000 € + 2.000 € Rest = 16.000 € → 3 Maschinen (15.000 €), Rest 1.000 €.'
        },
        {
          id: 'w6t3',
          prompt: '<b>Der Höhepunkt und der Absturz.</b> Wie viele Maschinen sind in Jahr 5 aktiv, wie viele in Jahr 6 (nach Ausmusterung der Erstausstattung)?',
          fields: [
            { key: 'j5', label: 'Aktive Maschinen Jahr 5', ans: 20, unit: 'Stück', tol: 0.01 },
            { key: 'kauf5', label: 'Neukauf Jahr 5', ans: 4, unit: 'Stück', tol: 0.01 },
            { key: 'j6', label: 'Aktive Maschinen Jahr 6', ans: 14, unit: 'Stück', tol: 0.01, traps: [{ v: 24, tol: 0.01, msg: 'Am Ende von Jahr 5 werden die 10 Maschinen der Erstausstattung ausgemustert: 20 + 4 − 10 = 14.' }] }
          ],
          solution: 'Jahr 5: 17 + 3 = 20 Maschinen, AfA 20.000 € + 3.000 € = 23.000 € → 4 Neukäufe, dann Ausmusterung der 10 Erstmaschinen. Jahr 6: 20 + 4 − 10 = 14 Maschinen.'
        },
        {
          id: 'w6t4',
          prompt: '<b>Stille Reserven.</b> Eine Maschine mit 100.000 € Anschaffungskosten wird statt über 10 Jahre über 5 Jahre abgeschrieben (lineare AfA). Wie hoch ist die zusätzliche Abschreibung pro Jahr und die stille Reserve nach 5 Jahren?',
          fields: [
            { key: 'afa10', label: 'AfA bei 10 Jahren ND', ans: 10000, unit: '€', tol: 0.01 },
            { key: 'afa5', label: 'AfA bei 5 Jahren ND', ans: 20000, unit: '€', tol: 0.01 },
            { key: 'reserve', label: 'Stille Reserve nach 5 Jahren', ans: 50000, unit: '€', tol: 0.01 }
          ],
          solution: '10.000 € vs. 20.000 € jährlich → 10.000 € zusätzlicher Aufwand pro Jahr → nach 5 Jahren 50.000 € stille Reserve (Buchwert 0 statt 50.000 €).'
        }
      ]
    },
    trainer: {
      title: 'Endlos-Trainer · Lohmann-Ruchti',
      intro: 'Zufällige Parameter – simuliere den Kapazitätseffekt.',
      gen: function () {
        const machines = 6 + Math.floor(Math.random() * 10);
        const cost = [4000, 5000, 6000, 8000][Math.floor(Math.random() * 4)];
        const life = 4 + Math.floor(Math.random() * 3);
        const rows = FIN.lohmannRuchti(machines, cost, life, life);
        const peak = Math.max.apply(null, rows.map((r) => r.activeMachines));
        const last = rows[rows.length - 1];
        return {
          prompt: 'Start: ' + machines + ' Maschinen à ' + R(cost, 0) + ' €, Nutzungsdauer ' + life + ' Jahre, sofortige Reinvestition.',
          given: 'AfA pro Maschine und Jahr = Anschaffungskosten / n',
          fields: [
            { key: 'afa', label: 'AfA in Jahr 1 (gesamt)', ans: machines * (cost / life), unit: '€', tol: 0.01 },
            { key: 'peak', label: 'Höchster Maschinenbestand', ans: peak, unit: 'Stück', tol: 0.01 },
            { key: 'last', label: 'Bestand im letzten Jahr (' + life + ')', ans: last.activeMachines, unit: 'Stück', tol: 0.01 }
          ],
          solution: 'Höchstbestand ' + peak + ' Maschinen in Jahr ' + life + ', danach Rückgang auf ' + last.activeMachines + ' (Ausmusterung der Erstausstattung).'
        };
      }
    }
  };

  /* ---------------- WELT 7: BETEILIGUNGSFINANZIERUNG ---------------- */
  const W7 = {
    id: 'W7', no: 7, side: 'FIN', color: '#f472b6', icon: '📈',
    title: 'Beteiligungsfinanzierung',
    tag: 'Roadshow-Tycoon & Bezugsrechts-Rechner',
    sources: 'Finanzierungsteil (2).pdf, Kap. 3.2 (Folien 72–121) · Vergleichsabschnitt 4. Anleihen',
    briefing: [
      { h: 'Emissionsfähigkeit', p: 'Personengesellschaften und GmbH haben keinen direkten Börsenzugang – erforderlich ist die Umwandlung in eine AG oder KGaA (oder ein vergleichbares Vorgehen).' },
      { h: 'Aktiengattungen', p: 'Stammaktien: volles Stimm- und Dividendenrecht. Vorzugsaktien: Stimmrechtsverzicht gegen Dividendenvorzug (ca. 2 % des Kurses), handeln meist 10–20 % unter Stammaktien, dienen der EK-Beschaffung ohne Stimmverwässerung. Inhaber- vs. Namensaktien (vinkuliert = Zustimmung des Vorstands).' },
      { h: 'Börsensegmente', p: 'Entry Standard/Freiverkehr (ab 250.000 € Mindestkapital, ca. 50 % geringere Kosten) · General Standard (Kurswert ≥ 1,25 Mio. €, ≥ 25 % Freefloat, ≥ 3 Jahre Unternehmensalter) · Prime Standard (IFRS/US-GAAP, Quartalsberichte, Analystenkonferenzen – Voraussetzung für DAX/MDAX/SDAX/TecDAX).' },
      { h: 'Bezugsrecht', p: 'BR = (K_a − K_n)/(a/n + 1) = K_a − K_m, mit Mischkurs K_m = (a·K_a + n·K_n)/(a + n). Dividendennachteil: d_nt = d·(1 − t_n/12) wird zum Bezugskurs addiert.' }
    ],
    concept: {
      title: 'IPO-Roadshow',
      intro: 'Entscheide wie ein Vorstand – jede Wahl hat einen Preis.',
      items: [
        {
          kind: 'sort',
          title: 'Kapitalerhöhungs-Formen',
          rounds: [{
            title: 'Welche Form liegt vor?',
            categories: [{ id: 'ORD', label: 'Ordentliche KE' }, { id: 'BED', label: 'Bedingte KE' }, { id: 'GEN', label: 'Genehmigte KE' }, { id: 'GES', label: 'KE aus Gesellschaftsmitteln' }],
            cards: [
              { text: 'Ausgabe junger Aktien gegen Einlagen, HV-Beschluss', cat: 'ORD', why: 'Klassische ordentliche Kapitalerhöhung mit Mittelzufluss.' },
              { text: 'Wandel-/Optionsanleihen, max. 50 % des Grundkapitals', cat: 'BED', why: 'Bedingte Kapitalerhöhung (§ 192 AktG).' },
              { text: 'Vorstand ermächtigt, binnen 5 Jahren bis 50 % des GK auszugeben', cat: 'GEN', why: 'Genehmigte Kapitalerhöhung (§ 202 AktG).' },
              { text: 'Grundkapital 40 → 50 Mio. €, Rücklagen 14 → 4 Mio. €, Bilanzsumme unverändert', cat: 'GES', why: 'Reiner Passivtausch, Berichtigungsaktien (Gratisaktien), kein Mittelzufluss.' },
              { text: 'Mitarbeiteraktien-Programm auf Basis eines HV-Beschlusses', cat: 'BED', why: 'Typischer Fall der bedingten Kapitalerhöhung.' }
            ]
          }]
        },
        {
          kind: 'quiz',
          title: 'Going-Public-Entscheidungen',
          questions: [
            { q: 'Vorzugsaktien sind attraktiv, weil …', options: ['sie ein Stimmrecht geben', 'sie Eigenkapital beschaffen, ohne die Stimmrechte zu verwässern', 'sie steuerlich als FK gelten'], a: 1, why: 'Stimmrechtsverzicht gegen Dividendenvorzug – Unabhängigkeit bleibt erhalten.' },
            { q: 'Das Bookbuilding-Verfahren …', options: ['setzt einen starren Festpreis', 'ermittelt die Preisspanne aus der Investorennachfrage', 'wird nur bei Anleihen verwendet'], a: 1, why: 'Dreistufiges Verfahren mit Angebotsspanne, Zeichnungsfrist und Preisfestsetzung, oft mit Greenshoe.' },
            { q: 'Die Greenshoe-Option dient …', options: ['der Kursstabilisierung (Mehrzuteilung)', 'der Steueroptimierung', 'der Erhöhung des Freefloat auf 25 %'], a: 0, why: 'Mehrzuteilungsoption zur Glättung der Erstnotiz.' },
            { q: 'Ab welcher Meldeschwelle greift die 7-Tage-Meldepflicht nach WpHG?', options: ['3 %', '5 %', '10 %'], a: 1, why: 'Schwellen 5 %, 10 %, 25 %, 50 %, 75 % – Meldung an BaFin und Gesellschaft binnen 7 Tagen.' }
          ]
        }
      ]
    },
    lab: {
      title: 'Rechen-Labor · Bezugsrecht & Verwässerungsschutz',
      intro: 'Alle vier Szenarien aus dem Skript.',
      tasks: [
        {
          id: 'w7t1',
          prompt: '<b>Level 1 (Vorlesungsbeispiel).</b> 80.000 alte Aktien (NW 50 €), Börsenkurs 120 €; 20.000 junge Aktien zu 90 €.',
          given: 'BR = (K_a − K_n)/(a/n + 1)',
          fields: [
            { key: 'ratio', label: 'Bezugsverhältnis a : n', ans: 4, unit: ': 1', tol: 0.001 },
            { key: 'km', label: 'Mischkurs K_m', ans: 114, unit: '€', tol: 0.01 },
            { key: 'br', label: 'Bezugsrecht', ans: 6, unit: '€', tol: 0.01 },
            { key: 'vermoegen', label: 'Vermögen von Aktionär A nach Kauf einer jungen Aktie (5 Aktien)', ans: 480, unit: '€', tol: 0.5 }
          ],
          solution: 'K_m = (80.000·120 + 20.000·90)/100.000 = 114 €; BR = (120 − 90)/5 = 6 €. Aktionär A: 5 · 114 − 90 = 480 € = Aktionär B: 4 · 114 + 4 · 6 = 480 € – keine Verwässerung.'
        },
        {
          id: 'w7t2',
          prompt: '<b>Level 2 (Dividendennachteil).</b> Wie Level 1, aber die jungen Aktien sind nur 5 von 12 Monaten dividendenberechtigt; Dividende d = 20 €.',
          given: 'BR = (K_a − (K_n + d_nt))/(a/n + 1),  d_nt = d·(1 − t_n/12)',
          fields: [
            { key: 'dnt', label: 'Dividendennachteil', ans: 11.67, unit: '€', tol: 0.01, traps: [{ v: 8.33, tol: 0.01, msg: 'Du hast 5/12 angesetzt. Der Nachteil entsteht aus den 7 Monaten ohne Dividendenberechtigung: 20 · (1 − 5/12) = 11,67 €.' }] },
            { key: 'br', label: 'Bezugsrecht', ans: 3.67, unit: '€', tol: 0.01 }
          ],
          solution: 'd_nt = 20 · 7/12 = 11,67 €; BR = (120 − 101,67)/5 = 3,67 €.'
        },
        {
          id: 'w7t3',
          prompt: '<b>Level 3 (XY AG).</b> Grundkapital 100 Mio. € (NW 5 €) → 20 Mio. Aktien, Kurs 50 €; Erhöhung um 25 Mio. € → 5 Mio. junge Aktien zu 40 €.',
          fields: [
            { key: 'km', label: 'Mischkurs', ans: 48, unit: '€', tol: 0.01 },
            { key: 'br', label: 'Bezugsrecht', ans: 2, unit: '€', tol: 0.01 },
            { key: 'depot', label: 'Gesamtvermögen, wenn stattdessen alle 200 Bezugsrechte verkauft werden (200 Altaktien + 400 € Verkaufserlös + 200 € Kasse)', ans: 10200, unit: '€', tol: 0.5 }
          ],
          solution: 'K_m = (20·50 + 5·40)/25 = 48 €; BR = (50 − 40)/5 = 2 €. Startvermögen: 200 · 50 + 200 = 10.200 €. Verkauf der BR: 200 · 48 + 200 · 2 + 200 = 10.200 € ✓. Zeichnung: 50 junge Aktien kosten 2.000 €, danach 250 · 48 = 12.000 € minus 2.000 € Einsatz = 10.000 € plus 200 € Kasse = 10.200 € ✓ – das Vermögen bleibt konstant.'
        },
        {
          id: 'w7t4',
          prompt: '<b>Level 4 (Medizin AG).</b> Grundkapital 75 Mio. € (NW 1 €) → 75 Mio. Aktien, Kurs 260 €; Erhöhung auf 105 Mio. € mit 30 Mio. jungen Aktien zu 113 €.',
          fields: [
            { key: 'km', label: 'Mischkurs', ans: 218, unit: '€', tol: 0.02 },
            { key: 'br', label: 'Bezugsrecht', ans: 42, unit: '€', tol: 0.02 },
            { key: 'gk', label: 'Erhöhung des gezeichneten Kapitals', ans: 30, unit: 'Mio. €', tol: 0.01 },
            { key: 'agio', label: 'Zuführung Kapitalrücklage (Agio)', ans: 3360, unit: 'Mio. €', tol: 0.05 },
            { key: 'cash', label: 'Mittelzufluss insgesamt', ans: 3390, unit: 'Mio. €', tol: 0.05 }
          ],
          solution: 'K_m = (75·260 + 30·113)/105 = 218 €; BR = (260 − 113)/3,5 = 42 €. Gezeichnetes Kapital +30 Mio. €, Agio 112 € · 30 Mio. = 3.360 Mio. €, Cash +3.390 Mio. €.'
        }
      ]
    },
    trainer: {
      title: 'Endlos-Trainer · Bezugsrechts-Maschine',
      intro: 'Zufällige Kapitalerhöhungen durchrechnen.',
      gen: function () {
        const oldS = (5 + Math.floor(Math.random() * 20)) * 10000;
        const newS = Math.max(1, Math.floor(oldS / (2 + Math.floor(Math.random() * 5)))) ;
        const ka = 40 + Math.floor(Math.random() * 120);
        const kn = Math.max(5, ka - (5 + Math.floor(Math.random() * 40)));
        const r = FIN.subscriptionRight({ oldShares: oldS, newShares: newS, oldSharePrice: ka, issuePriceNew: kn });
        return {
          prompt: 'Alt: ' + R(oldS, 0) + ' Aktien zu ' + R(ka, 0) + ' €; Neu: ' + R(newS, 0) + ' Aktien zu ' + R(kn, 0) + ' €.',
          given: 'BR = (K_a − K_n)/(a/n + 1)',
          fields: [
            { key: 'ratio', label: 'Bezugsverhältnis a/n', ans: oldS / newS, unit: ': 1', tol: 0.02 },
            { key: 'km', label: 'Mischkurs', ans: r.mixedPrice, unit: '€', tol: 0.02 },
            { key: 'br', label: 'Bezugsrecht', ans: r.subscriptionRightValue, unit: '€', tol: 0.02 }
          ],
          solution: 'K_m = ' + R(r.mixedPrice) + ' €, BR = ' + R(r.subscriptionRightValue) + ' € (Verhältnis ' + R(oldS / newS, 2) + ' : 1).'
        };
      }
    }
  };

  /* ---------------- WELT 8: FREMD- & OPTIMIERUNG ---------------- */
  const W8 = {
    id: 'W8', no: 8, side: 'FIN', color: '#fb923c', icon: '🏦',
    title: 'Fremdfinanzierung, Leasing & Optimierung',
    tag: 'Skonto-Schocker & Leverage-Boss',
    sources: 'Finanzierungsteil (2).pdf, Kap. 3.3 & 4.0 (Folien 122–193)',
    briefing: [
      { h: 'Lieferantenkredit', p: 'i = Skontosatz/(Zahlungsziel − Skontofrist) · 360. Bei „30 Tage, 3 % Skonto in 10 Tagen“ sind das 54 % p.a. – die Skontofrist sollte selbst mit Kontokorrentkredit genutzt werden.' },
      { h: 'Kurzfristige Instrumente', p: 'Geldleihe: Kontokorrent-, Lombard-, Diskontkredit. Kreditleihe: Akzept- und Avalkredit (Bank verleiht ihre Bonität). Factoring: laufender Forderungsankauf (30–150 Tage), Finanzierungs-, Delkredere- und Servicefunktion. Forfaitierung: Einzelankauf mittel-/langfristiger Exportforderungen ohne Rückgriff.' },
      { h: 'Tilgungsformen', p: 'Annuitätendarlehen (konstante Rate), Abzahlungsdarlehen (konstante Tilgung), Festdarlehen (Zins während der Laufzeit, Tilgung am Ende).' },
      { h: 'Leasing-Zurechnung', p: 'GMZ < 40 % oder > 90 % der BGND oder Spezial-Leasing → Leasingnehmer. 40–90 %: ohne Option Leasinggeber; Kaufoption unter Restbuchwert bzw. Anschlussmiete unter linearem Wertverzehr → Leasingnehmer.' },
      { h: 'Leverage-Effekt', p: 'r_e = r_g + FK/EK · (r_g − r_f). Bei r_g > r_f steigt die Eigenkapitalrentabilität mit der Verschuldung – bei r_g < r_f kehrt sich der Effekt um (negativer Leverage). Zielsystem: Rentabilität als Hauptziel, Liquidität und Unabhängigkeit als Nebenbedingungen (Pecking Order).' }
    ],
    concept: {
      title: 'Skonto-Schocker & Leasing-Baum',
      intro: 'Zinsen, Fristen, Bilanzierung – alles auf einmal.',
      items: [
        {
          kind: 'sort',
          title: 'Kreditleihe oder Geldleihe?',
          rounds: [{
            title: 'Sortiere die kurzfristigen Instrumente',
            categories: [{ id: 'GELD', label: 'Geldleihe' }, { id: 'TITEL', label: 'Kreditleihe' }],
            cards: [
              { text: 'Kontokorrentkredit', cat: 'GELD', why: 'Die Bank stellt tatsächlich Liquidität bereit.' },
              { text: 'Lombardkredit gegen Verpfändung von Wertpapieren', cat: 'GELD', why: 'Geld gegen Sicherheit.' },
              { text: 'Diskontkredit (Ankauf eines Wechsels unter Zinsabzug)', cat: 'GELD', why: 'Die Bank schafft Liquidität durch Wechselankauf.' },
              { text: 'Avalkredit (Bürgschaftsrahmen)', cat: 'TITEL', why: 'Die Bank verleiht nur ihre Kreditwürdigkeit.' },
              { text: 'Akzeptkredit (Bankwechsel)', cat: 'TITEL', why: 'Bank akzeptiert den Wechsel – Kreditleihe.' }
            ]
          }]
        },
        {
          kind: 'sort',
          title: 'Factoring oder Forfaitierung?',
          rounds: [{
            title: 'Sortiere die Forderungsverkäufe',
            categories: [{ id: 'FAC', label: 'Factoring' }, { id: 'FOR', label: 'Forfaitierung' }],
            cards: [
              { text: 'Laufender Ankauf kurzfristiger Forderungen (30–150 Tage)', cat: 'FAC', why: 'Typisch Factoring mit Service- und Delkrederefunktion.' },
              { text: 'Einzelankauf mittel- bis langfristiger Exportforderungen (6 Monate bis 6 Jahre) à forfait', cat: 'FOR', why: 'Forfaitierung, ohne Rückgriffsrecht.' },
              { text: 'Verkauf von Forderungen aus Konsumgütergeschäften, meist offen', cat: 'FAC', why: 'Factoring.' },
              { text: 'Übertragung von politischem, Transfer- und Währungsrisiko', cat: 'FOR', why: 'Bei der Forfaitierung wird das gesamte Risikopaket übertragen.' }
            ]
          }]
        },
        {
          kind: 'quiz',
          title: 'Leasing & Zielsystem',
          questions: [
            { q: 'GMZ = 50 % der BGND, keine Option. Wer bilanziert?', options: ['Leasingnehmer', 'Leasinggeber', 'Beide je 50 %'], a: 1, why: 'Im Korridor 40–90 % und ohne Option bilanziert der Leasinggeber.' },
            { q: 'Der Leverage-Effekt wirkt positiv, wenn …', options: ['r_g > r_f', 'r_g < r_f', 'EK > FK'], a: 0, why: 'Nur wenn die Gesamtkapitalrendite über dem Fremdkapitalzins liegt.' },
            { q: 'Pecking Order bedeutet …', options: ['Erst Aktien, dann Kredite, dann Innenfinanzierung', 'Erst Innenfinanzierung, dann FK, dann Beteiligungskapital', 'Nur Fremdfinanzierung'], a: 1, why: 'Minimaler Unabhängigkeitsverlust: Selbstfinanzierung → FK → EK.' },
            { q: 'Bei einem Festdarlehen …', options: ['bleibt die Rate konstant', 'bleibt die Tilgung konstant', 'wird nur der Zins gezahlt, die Tilgung erfolgt am Laufzeitende'], a: 2, why: 'Fälligkeitsdarlehen: Zins während der Laufzeit, Endtilgung.' }
          ]
        }
      ]
    },
    lab: {
      title: 'Rechen-Labor · Skonto, Tilgung, Leverage',
      intro: 'Das Finale der Finanzierungshälfte.',
      tasks: [
        {
          id: 'w8t1',
          prompt: '<b>Skonto-Schocker.</b> Lieferantenrechnung: „Zahlungsziel 30 Tage, bei Zahlung innerhalb von 10 Tagen 3 % Skonto“ (360-Tage-Jahr).',
          given: 'i = Skontosatz/(Ziel − Skontofrist) · 360',
          fields: [
            { key: 'i', label: 'Jahreszinssatz des Lieferantenkredits', ans: 54, unit: '%', tol: 0.05 },
            { key: 'decision', type: 'choice', label: 'Was tun bei Bankzins von 9 %?', options: ['Zahlungsziel voll ausschöpfen', 'Skonto ziehen, notfalls per Kontokorrentkredit', 'Rechnung gar nicht zahlen'], ans: 'Skonto ziehen, notfalls per Kontokorrentkredit' }
          ],
          solution: '3/20 · 360 = 54 % p.a. – weit über dem Bankzins. Also: Skonto ziehen und den Kontokorrentkredit (9 %) nutzen.'
        },
        {
          id: 'w8t2',
          prompt: '<b>Tilgungs-Architekt.</b> Darlehen 10.000 €, 10 % Zins, 3 Jahre. Gesucht: Annuitätendarlehen.',
          given: 'Annuität = A₀ · i/[1 − (1+i)<sup>−n</sup>]',
          fields: [
            { key: 'ann', label: 'Konstante Jahresrate', ans: 4021.15, unit: '€', tol: 0.05, traps: [{ v: 4333.33, tol: 0.05, msg: '4.333,33 € ist die Rate des Abzahlungsdarlehens (konstante Tilgung 3.333,33 € + Zins 1.000 €). Die Annuität ist konstant 4.021,15 €.' }] },
            { key: 'z1', label: 'Zinsanteil Jahr 1', ans: 1000, unit: '€', tol: 0.01 },
            { key: 't1', label: 'Tilgungsanteil Jahr 1', ans: 3021.15, unit: '€', tol: 0.05 },
            { key: 'z2', label: 'Zinsanteil Jahr 2', ans: 697.89, unit: '€', tol: 0.05 },
            { key: 'total', label: 'Gesamtzahlung (3 Jahre)', ans: 12063.44, unit: '€', tol: 0.1 }
          ],
          solution: 'Annuität = 10.000 · 0,40211 = 4.021,15 €. Zinsen 1.000,00 → 697,89 → 365,67; Tilgung 3.021,15 → 3.323,27 → 3.655,58. Gesamtzahlung 12.063,44 €.'
        },
        {
          id: 'w8t3',
          prompt: '<b>Vergleich der Tilgungsformen</b> für dasselbe Darlehen (10.000 €, 10 %, 3 Jahre).',
          fields: [
            { key: 'rat1', label: 'Rate Abzahlungsdarlehen Jahr 1', ans: 4333.33, unit: '€', tol: 0.02 },
            { key: 'rattotal', label: 'Gesamtzahlung Abzahlungsdarlehen', ans: 12000, unit: '€', tol: 0.02 },
            { key: 'festtotal', label: 'Gesamtzahlung Festdarlehen', ans: 13000, unit: '€', tol: 0.02 },
            { key: 'cheap', type: 'choice', label: 'Günstigste Variante', options: ['Annuitätendarlehen', 'Abzahlungsdarlehen', 'Festdarlehen'], ans: 'Abzahlungsdarlehen' }
          ],
          solution: 'Ratendarlehen: 4.333,33 / 3.666,67 / 3.500,00 → 12.000 € Gesamtzahlung (günstigste Variante, weil die Tilgung am schnellsten erfolgt). Festdarlehen: 3 × 1.000 € Zins + 10.000 € Tilgung = 13.000 € (teuerste).'
        },
        {
          id: 'w8t4',
          prompt: '<b>Leverage-Regler.</b> Gesamtkapital 1.000.000 €, r_g = 10 %, r_f = 5 %. Variante 1: EK 800.000 € / FK 200.000 €. Variante 2: EK 400.000 € / FK 600.000 €.',
          given: 'r_e = r_g + FK/EK · (r_g − r_f)',
          fields: [
            { key: 'g1', label: 'Reingewinn Variante 1', ans: 90000, unit: '€', tol: 0.02 },
            { key: 're1', label: 'Eigenkapitalrentabilität Variante 1', ans: 11.25, unit: '%', tol: 0.01 },
            { key: 're2', label: 'Eigenkapitalrentabilität Variante 2', ans: 17.5, unit: '%', tol: 0.01 },
            { key: 'krise', type: 'choice', label: 'Was passiert, wenn r_g auf 4 % fällt?', options: ['Der Hebel wirkt weiter positiv', 'Negativer Leverage-Effekt: die EK-Rentabilität sinkt unter r_g', 'Die EK-Rentabilität bleibt bei 10 %'], ans: 'Negativer Leverage-Effekt: die EK-Rentabilität sinkt unter r_g' }
          ],
          solution: 'V1: 100.000 − 10.000 = 90.000 € → 11,25 %. V2: 100.000 − 30.000 = 70.000 € → 17,50 %. Bei r_g = 4 %: 40.000 − 30.000 = 10.000 € → 2,5 % EK-Rentabilität (negativer Leverage).'
        },
        {
          id: 'w8t5',
          prompt: '<b>Leasing-Prüfer.</b> Entscheide für vier Fälle, wer bilanziert (BGND jeweils 60 Monate).',
          fields: [
            { key: 'f1', type: 'choice', label: 'GMZ 21 Monate (35 % der BGND), keine Option', options: ['Leasingnehmer', 'Leasinggeber'], ans: 'Leasingnehmer' },
            { key: 'f2', type: 'choice', label: 'GMZ 30 Monate (50 %), keine Option', options: ['Leasingnehmer', 'Leasinggeber'], ans: 'Leasinggeber' },
            { key: 'f3', type: 'choice', label: 'GMZ 30 Monate (50 %), Kaufoption unter Restbuchwert', options: ['Leasingnehmer', 'Leasinggeber'], ans: 'Leasingnehmer' },
            { key: 'f4', type: 'choice', label: 'Spezial-Leasing, GMZ 30 Monate', options: ['Leasingnehmer', 'Leasinggeber'], ans: 'Leasingnehmer' }
          ],
          solution: '21/60 = 35 % < 40 % → Zurechnung Leasingnehmer. 30/60 = 50 % liegt im Korridor 40–90 %: ohne Option bilanziert der Leasinggeber, mit einer Kaufoption unterhalb des Restbuchwerts dagegen der Leasingnehmer (Ebenso bei Anschlussmiete unter linearem Wertverzehr). Spezial-Leasing wird immer dem Leasingnehmer zugerechnet.'
        }
      ]
    },
    trainer: {
      title: 'Endlos-Trainer · Skonto & Leverage',
      intro: 'Zwei Klassiker, unendlich viele Zahlen.',
      gen: function () {
        const disc = [1, 2, 3, 4][Math.floor(Math.random() * 4)];
        const sd = [7, 10, 14][Math.floor(Math.random() * 3)];
        const td = sd + [10, 20, 30, 45][Math.floor(Math.random() * 4)];
        const total = (10 + Math.floor(Math.random() * 20)) * 100000;
        const eqShare = [0.2, 0.3, 0.4, 0.6, 0.8][Math.floor(Math.random() * 5)];
        const rg = 8 + Math.floor(Math.random() * 8);
        const rf = 3 + Math.floor(Math.random() * 5);
        const lev = FIN.leverage(total * eqShare, total * (1 - eqShare), rg, rf);
        return {
          prompt: 'Rechnung: „Zahlungsziel ' + td + ' Tage, bei Zahlung in ' + sd + ' Tagen ' + disc + ' % Skonto“. Zusätzlich: Gesamtkapital ' + R(total, 0) + ' €, EK-Quote ' + R(eqShare * 100, 0) + ' %, r_g = ' + rg + ' %, r_f = ' + rf + ' %.',
          given: 'i = Skonto/(Ziel − Frist) · 360 · r_e = r_g + FK/EK·(r_g − r_f)',
          fields: [
            { key: 'i', label: 'Lieferantenkredit-Jahreszins', ans: FIN.supplierCreditRate(disc, td, sd), unit: '%', tol: 0.05 },
            { key: 're', label: 'Eigenkapitalrentabilität', ans: lev.roePct, unit: '%', tol: 0.02 },
            { key: 'hebel', type: 'choice', label: 'Leverage-Wirkung', options: ['positiv', 'negativ'], ans: rg > rf ? 'positiv' : 'negativ' }
          ],
          solution: 'Lieferantenkredit: ' + R(FIN.supplierCreditRate(disc, td, sd)) + ' % p.a.; EK-Rentabilität ' + R(lev.roePct) + ' % (' + (rg > rf ? 'positiver' : 'negativer') + ' Leverage, FK/EK = ' + R(lev.leverageRatio, 2) + ').'
        };
      }
    }
  };

  window.GAMEDATA_PART2 = [W4, W5, W6, W7, W8];
})();
