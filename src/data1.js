/* ============================================================
   src/data.js – Kuratierte UHH-Spieldaten, Aufgaben & Konzeptspiele
   ============================================================ */
(function () {
  'use strict';

  const R = (x, d) => (x).toLocaleString('de-DE', { minimumFractionDigits: d === undefined ? 2 : d, maximumFractionDigits: d === undefined ? 2 : d });

  /* ---------------- WELT 1 ---------------- */
  const W1 = {
    id: 'W1', no: 1, side: 'INV', color: '#38bdf8', icon: '🧭',
    title: 'Grundlagen & Einführung',
    tag: 'Cashflow-Tinder & Bilanz-Architekt',
    sources: '1. Einführung (2).pdf · 2. Statische Verfahren (Folien 7–8) · Finanzierungsteil Kap. 1.0–1.1',
    briefing: [
      { h: 'Investition vs. Finanzierung', p: 'Beide sind Zahlungsreihen – nur die Richtung des ersten Zahlungsstroms unterscheidet sie. Investition: beginnt mit einer Auszahlung (−), danach folgen Einzahlungen. Finanzierung: beginnt mit einer Einzahlung (+), danach folgen Auszahlungen (Zins & Tilgung).' },
      { h: 'Pagatorisch vs. kalkulatorisch', p: 'Pagatorische Kosten haben einen äquivalenten Aufwand in der FiBu (Löhne, Rohstoffe, Miete, Fremdkapitalzinsen). Kalkulatorische Kosten nicht – unterteilt in Anderskosten (kalk. Zinsen, kalk. Abschreibungen) und Zusatzkosten (kalk. Unternehmerlohn, fiktive Miete).' },
      { h: 'Entscheidungsprozess in 5 Phasen', p: 'Anregungsphase → Suchphase → Entscheidungsphase → Durchführungsphase → Kontrollphase (Soll-Ist-Abweichungsanalyse). Relevante Bewertungskriterien sind quantitativ-monetär; qualitative Kriterien (Service, Lieferzeit, Umweltschutz) gehören in die Vorprüfung.' },
      { h: 'Drei Theorie-Schulen', p: 'Klassische Finanzierungstheorie (Fisher-Separation, vollkommener Kapitalmarkt), Neoklassik (Markowitz-Portfoliotheorie 1952, CAPM nach Sharpe/Lintner/Mossin), Neue Institutionenökonomik (Coase/Williamson, Property Rights, Principal-Agent nach Jensen/Meckling 1972).' }
    ],
    concept: {
      title: 'Cashflow-Tinder & Prozess-Puzzle',
      intro: 'Wische jede Karte in das richtige Feld. Fehlerfreie Serien laden deinen Kombo-Multiplikator auf.',
      items: [
        {
          kind: 'sort',
          title: 'Runde 1 · Zahlungsstromrichtung',
          rounds: [{
            title: 'Investition oder Finanzierung?',
            categories: [{ id: 'INV', label: 'Investition' }, { id: 'FIN', label: 'Finanzierung' }],
            cards: [
              { text: 'Zahlungsreihe: −10.000, +2.000, +3.000, +5.000', cat: 'INV', why: 'Erste Zahlung ist eine Auszahlung → Investition.' },
              { text: 'Zahlungsreihe: +10.000, −2.000, −3.000, −4.000', cat: 'FIN', why: 'Erste Zahlung ist eine Einzahlung, danach Zins und Tilgung → Finanzierung.' },
              { text: 'Kauf einer neuen Abfüllanlage für 95.000 €', cat: 'INV', why: 'Auszahlung heute, Einzahlungen aus dem Verkauf der Flaschen später.' },
              { text: 'Aufnahme eines Investitionskredits bei der Hamburger Sparkasse', cat: 'FIN', why: 'Einzahlung heute, Auszahlungen (Zins/Tilgung) in der Zukunft.' },
              { text: 'Ausgabe junger Aktien im Rahmen des IPO', cat: 'FIN', why: 'Beteiligungsfinanzierung: Einzahlung heute, später Dividenden.' }
            ]
          }]
        },
        {
          kind: 'sort',
          title: 'Runde 2 · Kostenbegriffe',
          rounds: [{
            title: 'Pagatorisch oder kalkulatorisch?',
            categories: [{ id: 'PAG', label: 'Pagatorisch' }, { id: 'KALK', label: 'Kalkulatorisch' }],
            cards: [
              { text: 'Fertigungslöhne der Abfüllstraße', cat: 'PAG', why: 'Hat einen äquivalenten Aufwand in der FiBu.' },
              { text: 'Kalkulatorische Zinsen auf das durchschnittlich gebundene Kapital', cat: 'KALK', why: 'Anderskosten: kein äquivalenter Aufwand in der FiBu.' },
              { text: 'Fremdkapitalzinsen für den Maschinenkredit', cat: 'PAG', why: 'Zinsaufwand steht so auch in der GuV.' },
              { text: 'Kalkulatorischer Unternehmerlohn der Gründer', cat: 'KALK', why: 'Zusatzkosten: in der FiBu überhaupt nicht enthalten.' },
              { text: 'Fiktive Miete für die eigengenutzte Produktionshalle', cat: 'KALK', why: 'Zusatzkosten – es fließt keine Mietzahlung.' },
              { text: 'Kalkulatorische Abschreibung (Wiederbeschaffungswert)', cat: 'KALK', why: 'Anderskosten: weicht von der bilanzielen Abschreibung ab.' }
            ]
          }]
        },
        {
          kind: 'sort',
          title: 'Runde 3 · Kapitalarten',
          rounds: [{
            title: 'Eigenkapital oder Fremdkapital?',
            categories: [{ id: 'EK', label: 'Eigenkapital' }, { id: 'FK', label: 'Fremdkapital' }],
            cards: [
              { text: 'Beteiligungsverhältnis, volle Verlustteilnahme', cat: 'EK', why: 'Quotenanspruch statt fester Nominalanspruch.' },
              { text: 'Fester Nominalanspruch auf Zins und Tilgung', cat: 'FK', why: 'Schuldverhältnis mit fixen Ansprüchen.' },
              { text: 'Zinsen sind steuerlich als Aufwand absetzbar', cat: 'FK', why: 'Der Tax-Shield gehört zum Fremdkapital.' },
              { text: 'Unbegrenzte Verfügbarkeit, keine Rückzahlungspflicht', cat: 'EK', why: 'Haftungskapital ohne Laufzeit.' },
              { text: 'Keine Haftung, aber Gläubigerrechte bei Krise', cat: 'FK', why: 'Gläubigereinfluss ist eine Nebenwirkung des FK.' }
            ]
          }]
        },
        {
          kind: 'order',
          title: 'Prozess-Puzzle · Investitionsentscheidung',
          prompt: 'Bringe die fünf Phasen in die richtige Reihenfolge (Klick = anhängen).',
          items: [
            { id: 'a', text: 'Anregungsphase' },
            { id: 'b', text: 'Suchphase' },
            { id: 'c', text: 'Entscheidungsphase' },
            { id: 'd', text: 'Durchführungsphase' },
            { id: 'e', text: 'Kontrollphase (Soll-Ist-Abweichung)' }
          ],
          solution: 'Anregung → Suche → Entscheidung → Durchführung → Kontrolle'
        },
        {
          kind: 'sort',
          title: 'Investitionsrechnungs-Trichter',
          rounds: [{
            title: 'Quantitativ-monetär oder qualitativ?',
            categories: [{ id: 'QN', label: 'In den Trichter (quantitativ)' }, { id: 'QL', label: 'Qualitative Vorprüfung' }],
            cards: [
              { text: 'Kostenvergleich', cat: 'QN', why: 'Monetäre Größe.' },
              { text: 'Kapitalwert', cat: 'QN', why: 'Monetäre Größe.' },
              { text: 'Amortisationszeit', cat: 'QN', why: 'Quantitativ (Zeit, aus Zahlungen abgeleitet).' },
              { text: 'Servicequalität des Lieferanten', cat: 'QL', why: 'Nicht monetarisierbar.' },
              { text: 'Unfallschutz der Maschine', cat: 'QL', why: 'Qualitativ – gehört in die Vorprüfung.' },
              { text: 'Interner Zinsfuß', cat: 'QN', why: 'Monetäre Größe.' },
              { text: 'Lieferzeit', cat: 'QL', why: 'Qualitativ.' },
              { text: 'Umweltverträglichkeit', cat: 'QL', why: 'Qualitativ (bzw. nur über Hilfsrechnungen monetarisierbar).' }
            ]
          }]
        },
        {
          kind: 'quiz',
          title: 'Principal-Agent-Detektiv',
          questions: [
            { q: 'Was fordert der Kapitalgeber (Principal) typischerweise?', options: ['Hohe Verzinsung, kurze Laufzeit, geringes Risiko', 'Niedrige Kapitalkosten, lange Laufzeit, Risikoabwälzung', 'Möglichst viel Stimmrecht ohne Rendite'], a: 0, why: 'Der Principal will hohe Rendite bei kurzer Bindung und minimalem Risiko – der Gegensatz zu den Wünschen des Kapitalnehmers.' },
            { q: 'Welche Transformationsfunktion erfüllt die Bank als Finanzintermediär?', options: ['Nur die Losgrößentransformation', 'Losgrößen-, Fristen- und Risikotransformation', 'Ausschließlich die Risikotransformation durch den Staat'], a: 1, why: 'Banken bündeln kleine Beträge (Losgröße), wandeln Fristen und übernehmen Risiken.' },
            { q: 'Das Fisher-Separationstheorem gehört zur …', options: ['Neuen Institutionenökonomik', 'Klassischen Finanzierungstheorie', 'Neoklassischen Portfoliotheorie'], a: 1, why: 'Fisher-Separation: vollkommener Kapitalmarkt und Sicherheit → klassische Theorie.' },
            { q: 'Worin unterscheiden sich Risiko und Ungewissheit?', options: ['Risiko: Wahrscheinlichkeiten bekannt; Ungewissheit: keine Wahrscheinlichkeiten', 'Risiko: nur negativ; Ungewissheit: nur positiv', 'Beides ist identisch, nur sprachlich verschieden'], a: 0, why: 'Risiko = messbare Wahrscheinlichkeitsverteilung (nach Knight), Ungewissheit = keine.' },
            { q: 'Agency-Kosten gehen zurück auf …', options: ['Markowitz (1952)', 'Jensen & Meckling (1972)', 'Coase (1937) allein'], a: 1, why: 'Jensen/Meckling 1972 formulieren die Principal-Agent-Theorie mit Agency-Kosten.' }
          ]
        }
      ]
    },
    lab: {
      title: 'Rechen-Labor · Zahlungsreihen & Nutzungsdauer',
      intro: 'Wende die Begriffe auf die Delizioso AG an.',
      tasks: [
        {
          id: 'w1t1',
          prompt: 'Eine Zahlungsreihe lautet: <b>+25.000 €, −6.000 €, −6.000 €, −15.000 €</b>. Handelt es sich um eine Investition oder eine Finanzierung?',
          fields: [{
            key: 'typ', type: 'choice', options: ['Investition', 'Finanzierung'], ans: 'Finanzierung',
            hint: 'Schau nur auf das Vorzeichen der ersten Zahlung.'
          }],
          solution: 'Finanzierung: Der erste Zahlungsstrom ist eine Einzahlung (+25.000 €), die später durch Zins- und Tilgungszahlungen zurückgeführt wird.'
        },
        {
          id: 'w1t2',
          prompt: 'Die neue Abfüllanlage hat eine <b>technische</b> Nutzungsdauer von 12 Jahren. Die Delizioso AG erwartet, dass sie nach 7 Jahren wegen einer besseren Generation wirtschaftlich überholt ist. Welche Nutzungsdauer ist in der Investitionsrechnung maßgeblich?',
          fields: [{ key: 'n', label: 'Maßgebliche Nutzungsdauer (Jahre)', ans: 7, unit: 'Jahre', hint: 'Wirtschaftliche ≤ technische Nutzungsdauer.' }],
          solution: 'Maßgeblich ist die <b>wirtschaftliche Nutzungsdauer (7 Jahre)</b>. Die technische Nutzungsdauer ist die Obergrenze; gerechnet wird mit dem kürzeren, wirtschaftlich relevanten Zeitraum.'
        },
        {
          id: 'w1t3',
          prompt: 'Ordne ein: Die Delizioso AG zahlt für die Produktionshalle, die ihr eigentümer gehört, keine Miete. In der Kostenrechnung werden dennoch 4.500 €/Monat als Kosten angesetzt. Wie heißen diese Kosten?',
          fields: [{ key: 'art', type: 'choice', options: ['Pagatorische Kosten', 'Kalkulatorische Zusatzkosten', 'Kalkulatorische Anderskosten'], ans: 'Kalkulatorische Zusatzkosten', hint: 'Es existiert überhaupt kein Aufwand in der FiBu.' }],
          solution: 'Kalkulatorische <b>Zusatzkosten</b> – in der FiBu gibt es keinen entsprechenden Aufwand (fiktive Miete für eigengenutzte Immobilie). Anderskosten hätten dagegen einen Aufwand, aber in anderer Höhe (z. B. kalk. Zinsen).'
        }
      ]
    },
    trainer: {
      title: 'Endlos-Trainer · Zahlungsreihen-Scanner',
      intro: 'Klassifiziere 5 Zahlungsreihen in Folge.',
      gen: function () {
        const sign = Math.random() < 0.5;
        const a0 = (3 + Math.floor(Math.random() * 18)) * 1000;
        const rest = [1, 2, 3].map(() => (1 + Math.floor(Math.random() * 6)) * 1000);
        const flows = sign ? [-a0].concat(rest) : [a0].concat(rest.map((x) => -x));
        return {
          prompt: 'Zahlungsreihe: <b>' + flows.map((f) => (f > 0 ? '+' : '−') + R(Math.abs(f), 0) + ' €').join(', ') + '</b>',
          fields: [{ key: 'typ', type: 'choice', options: ['Investition', 'Finanzierung'], ans: sign ? 'Investition' : 'Finanzierung' }],
          solution: sign ? 'Investition (erste Zahlung ist eine Auszahlung).' : 'Finanzierung (erste Zahlung ist eine Einzahlung).'
        };
      }
    }
  };

  /* ---------------- WELT 2 ---------------- */
  const carA = { acquisitionCost: 16000, residualValue: 0, usefulLife: 4, interestRate: 0.10, fixedOperatingCosts: 355.8 + 824.4, variableCostPerUnit: 26 };
  const carB = { acquisitionCost: 17000, residualValue: 0, usefulLife: 4, interestRate: 0.10, fixedOperatingCosts: 415.2 + 930.5, variableCostPerUnit: 22 };
  const fill1 = { acquisitionCost: 95000, residualValue: 4000, usefulLife: 3, interestRate: 0.06, fixedOperatingCosts: 1000, variableCostPerUnit: 4, pricePerUnit: 10 };
  const fill2 = { acquisitionCost: 80000, residualValue: 0, usefulLife: 3, interestRate: 0.06, fixedOperatingCosts: 8000, variableCostPerUnit: 3, pricePerUnit: 10 };

  const W2 = {
    id: 'W2', no: 2, side: 'INV', color: '#34d399', icon: '🚚',
    title: 'Statische Investitionsrechnung',
    tag: 'Fuhrpark- & Abfüllanlagen-Duell',
    sources: '2. Statische_Verfahren (2).pdf · Aufgaben mit Lösung · PowerPoint-Version',
    briefing: [
      { h: 'Die Kostenvergleichsformel', p: 'K(x) = k_var · x + K_Bfix + (A₀ − L)/n + (A₀ + L)/2 · i. Die beiden letzten Terme sind die kalkulatorische Abschreibung und die kalkulatorischen Zinsen auf das durchschnittlich gebundene Kapital.' },
      { h: 'Achtung Zahlendreher im Material', p: 'Auf Folie 8 der Aufgabenstellung sind die Versicherungsprämien der Automodelle A und B vertauscht abgedruckt. Musterlösung und PowerPoint rechnen mit A = 824,40 € und B = 930,50 € – diese Werte verwendet auch der Simulator.' },
      { h: 'Restwert-Waage', p: 'Ein Liquidationserlös senkt die Abschreibung, erhöht aber das durchschnittlich gebundene Kapital (A₀ + L)/2 – und damit die kalkulatorischen Zinsen. Beide Effekte laufen gegenläufig.' },
      { h: 'Amortisation & Cashflow', p: 'Die zahlungsunwirksamen kalkulatorischen Kosten werden zum Gewinn addiert: CF = G + K_Afa + K_Zi. Erst dann gilt T* = A₀ / CF. Bei ungleichen Rückflüssen Kumulationsmethode.' }
    ],
    concept: {
      title: 'Kosten-Duell & Payback-Rennen',
      intro: 'Intuition vor Taschenrechner: Wer gewinnt – und ab welcher Menge kippt die Entscheidung?',
      items: [
        {
          kind: 'quiz',
          title: 'Konzept-Check',
          questions: [
            { q: 'Zwei Maschinen: M1 hat hohe Fixkosten, aber niedrige variable Stückkosten. Bei steigender Menge …', options: ['gewinnt M1 relativ immer mehr', 'verliert M1 relativ immer mehr', 'ändert sich nichts'], a: 0, why: 'Fixkostendegression: Mit steigendem x werden die hohen Fixkosten auf mehr Stück verteilt.' },
            { q: 'Was passiert mit den kalkulatorischen Zinsen, wenn der Restwert steigt?', options: ['Sie steigen, weil (A₀+L)/2 wächst', 'Sie sinken, weil die Abschreibung sinkt', 'Sie bleiben konstant'], a: 0, why: 'Das durchschnittlich gebundene Kapital (A₀+L)/2 steigt mit L – und damit die kalkulatorischen Zinsen.' },
            { q: 'Warum darf bei der Amortisationsrechnung nicht der Gewinn verwendet werden?', options: ['Weil Abschreibungen und kalk. Zinsen keine Zahlungen sind und wieder addiert werden müssen', 'Weil Gewinne besteuert werden', 'Weil der Gewinn zu klein ist'], a: 0, why: 'Amortisation misst Zahlungsrückflüsse: CF = G + AfA + kalk. Zinsen.' },
            { q: 'Die Amortisationsdauer ist ein Maß für …', options: ['Rentabilität', 'Liquidität und Risiko', 'Kapazität'], a: 1, why: 'Sie zeigt, wie schnell das Kapital zurückfließt – ein Liquiditäts-/Risikoindikator, kein Rentabilitätsmaß.' }
          ]
        },
        {
          kind: 'sort',
          title: 'Fixkosten-Baukasten',
          rounds: [{
            title: 'Welche Bestandteile gehören in K_fix?',
            categories: [{ id: 'FIX', label: 'Fixkosten-Block' }, { id: 'VAR', label: 'Variabler Block' }],
            cards: [
              { text: 'Kalkulatorische Abschreibung (A₀ − L)/n', cat: 'FIX', why: 'Unabhängig von der Menge.' },
              { text: 'Kalkulatorische Zinsen (A₀ + L)/2 · i', cat: 'FIX', why: 'Unabhängig von der Menge.' },
              { text: 'Kfz-Steuer und Versicherung', cat: 'FIX', why: 'Periodenfix.' },
              { text: 'Benzinkosten je 100 km', cat: 'VAR', why: 'Mengenabhängig (k_var).' },
              { text: 'Reifenverschleiß je 100 km', cat: 'VAR', why: 'Mengenabhängig.' }
            ]
          }]
        }
      ]
    },
    lab: {
      title: 'Rechen-Labor · Die Originalaufgaben',
      intro: 'Exakt die Zahlen aus der UHH-Aufgabensammlung. Ergebnisfelder mit Komma oder Punkt eingeben.',
      tasks: [
        {
          id: 'w2t1',
          prompt: '<b>Aufgabe 1 · Promotour-Fuhrpark.</b> Modell A: A₀ = 16.000 €, Modell B: A₀ = 17.000 €, jeweils n = 4 Jahre, i = 10 %, kein Restwert. Steuern/Versicherung: A = 355,80 € + 824,40 €, B = 415,20 € + 930,50 €. Variable Kosten: A = 26 €/100 km, B = 22 €/100 km.',
          given: 'K = k<sub>var</sub>·x + K<sub>Bfix</sub> + (A₀ − L)/n + (A₀ + L)/2 · i',
          fields: [
            { key: 'fixa', label: 'Fixkosten Modell A', ans: 5980.2, unit: '€', traps: [{ v: 6086.3, tol: 0.1, msg: 'Du hast die Versicherungsprämien vertauscht – auf Folie 8 stehen A und B verdreht. Musterlösung: Versicherung A = 824,40 €.' }, { v: 5180.2, tol: 0.1, msg: 'Die kalkulatorischen Zinsen fehlen: (16.000 + 0)/2 · 10 % = 800 €.' }] },
            { key: 'fixb', label: 'Fixkosten Modell B', ans: 6445.7, unit: '€', traps: [{ v: 6339.6, tol: 0.1, msg: 'Versicherungen vertauscht: für Modell B gilt 930,50 € (Musterlösung).' }] },
            { key: 'xkrit', label: 'Kritische Menge x_krit', ans: 116.375, unit: 'Hundert-km', traps: [{ v: 11637.5, tol: 1, msg: 'x_krit ist in Hundert-Kilometern angegeben – die Kilometerleistung beträgt 11.637,5 km. Bitte 116,375 eingeben.' }], hint: '(6.445,70 − 5.980,20)/(26 − 22)' },
            { key: 'kost15', label: 'Kosten Modell A bei 15.000 km', ans: 9880.2, unit: '€' }
          ],
          solution: 'K_A = 5.980,20 €; K_B = 6.445,70 €; x_krit = 650/4 = 116,375 (Hundert-km) = 11.637,5 km → darunter ist A günstiger, darüber B. Bei 15.000 km: A = 9.880,20 € vs. B = 9.745,70 €.'
        },
        {
          id: 'w2t2',
          prompt: '<b>Aufgabe 2 · Sommer-Abfüllanlage.</b> Maschine 1: A₀ = 95.000 €, L = 4.000 €, K_Bfix = 1.000 €, k_var = 4 €; Maschine 2: A₀ = 80.000 €, L = 0 €, K_Bfix = 8.000 €, k_var = 3 €. n = 3 Jahre, i = 6 %, p = 10 €.',
          given: 'Restwert-Waage: AfA = (A₀ − L)/n, Zinsen = (A₀ + L)/2 · i',
          fields: [
            { key: 'afa1', label: 'Kalkulatorische Abschreibung Maschine 1', ans: 30333.33, unit: '€', traps: [{ v: 31666.67, tol: 0.1, msg: 'Restwert vergessen: (95.000 − 4.000)/3 = 30.333,33 €.' }] },
            { key: 'zi1', label: 'Kalkulatorische Zinsen Maschine 1', ans: 2970, unit: '€', traps: [{ v: 2850, tol: 0.1, msg: 'Der Restwert wird im Durchschnittskapital ADDiert: (95.000 + 4.000)/2 = 49.500 € → 2.970 €.' }] },
            { key: 'fix1', label: 'Fixkosten Maschine 1', ans: 34303.33, unit: '€', traps: [{ v: 34183.33, tol: 0.1, msg: 'Klassischer Restwert-Fehler: Zinsen wurden auf (95.000 − 4.000)/2 gerechnet. Richtig: (95.000 + 4.000)/2 · 6 % = 2.970 €.' }] },
            { key: 'fix2', label: 'Fixkosten Maschine 2', ans: 37066.67, unit: '€' },
            { key: 'xkrit', label: 'Kritische Menge', ans: 2763.33, unit: 'Stück', hint: '(37.066,67 − 34.303,33)/(7 − 6)' },
            { key: 'g1', label: 'Periodengewinn Maschine 1 bei 15.000 Stück', ans: 55696.67, unit: '€' },
            { key: 'g2', label: 'Periodengewinn Maschine 2 bei 15.000 Stück', ans: 67933.34, unit: '€' }
          ],
          solution: 'M1: AfA 30.333,33 €, Zinsen 2.970 €, K_fix = 34.303,33 €; M2: AfA 26.666,67 €, Zinsen 2.400 €, K_fix = 37.066,67 €. x_krit = 2.763,33 Stück. Gewinn bei 15.000: M1 = 55.696,67 €, M2 = 67.933,33 €.'
        },
        {
          id: 'w2t3',
          prompt: '<b>Aufgabe 3 · Statische Rentabilität</b> der beiden Abfüllanlagen bei 15.000 Stück (Gewinne aus Aufgabe 2).',
          given: 'R = G / [(A₀ + L)/2] · 100',
          fields: [
            { key: 'rm1', label: 'Rentabilität Maschine 1', ans: 112.52, unit: '%', tol: 0.05 },
            { key: 'rm2', label: 'Rentabilität Maschine 2', ans: 169.83, unit: '%', tol: 0.05 }
          ],
          solution: 'R₁ = 55.696,67 / 49.500 = 112,52 %; R₂ = 67.933,33 / 40.000 = 169,83 %. Maschine 2 ist deutlich rentabler.'
        },
        {
          id: 'w2t4',
          prompt: '<b>Aufgabe 4 · Amortisationsrechnung (Durchschnittsmethode).</b> Maschine 1: A₀ = 220.000 €, Jahresgewinn 29.420 €, n = 8, L = 16.000 €, i = 6 %. Maschine 2: A₀ = 270.000 €, Gewinn 24.260 €, n = 8, L = 18.000 €. Bestimme die Cashflows und Amortisationsdauern.',
          given: 'CF = G + K_Afa + K_Zi,  T* = A₀ / CF',
          fields: [
            { key: 'cf1', label: 'Cashflow Maschine 1', ans: 62000, unit: '€', traps: [{ v: 29420, tol: 0.5, msg: 'Der Gewinn ist keine Zahlungsreihe: AfA (25.500 €) und kalk. Zinsen (7.080 €) sind zahlungsunwirksam und müssen addiert werden.' }] },
            { key: 't1', label: 'Amortisationsdauer Maschine 1', ans: 3.55, unit: 'Jahre', tol: 0.01, traps: [{ v: 7.48, tol: 0.05, msg: 'Du hast durch den Gewinn statt durch den Cashflow geteilt (220.000/29.420). Richtig: 220.000/62.000 = 3,55 Jahre.' }] },
            { key: 'cf2', label: 'Cashflow Maschine 2', ans: 64400, unit: '€' },
            { key: 't2', label: 'Amortisationsdauer Maschine 2', ans: 4.19, unit: 'Jahre', tol: 0.01 }
          ],
          solution: 'CF₁ = 29.420 + 25.500 + 7.080 = 62.000 € → T*₁ = 3,55 Jahre. CF₂ = 24.260 + 31.500 + 8.640 = 64.400 € → T*₂ = 4,19 Jahre. Maschine 1 amortisiert sich schneller.'
        },
        {
          id: 'w2t5',
          prompt: '<b>Kumulationsmethode.</b> Investitionsobjekt 1: Anfangsauszahlung 540 T€, Rückflüsse 110, 96, 90, 130, 120, 95, 100 (T€). Objekt 2: konstante 135 T€.',
          given: 'T* = t_voll + Restbetrag / Zufluss des Folgejahres',
          fields: [
            { key: 'rest', label: 'Offener Restbetrag nach Jahr 4', ans: 114, unit: 'T€', traps: [{ v: 230, tol: 0.5, msg: 'Summe der Rückflüsse nach Jahr 4 ist 426 T€ (110+96+90+130) → Rest 540 − 426 = 114 T€.' }] },
            { key: 't1', label: 'Exakte Amortisationsdauer Objekt 1', ans: 4.95, unit: 'Jahre', tol: 0.01, traps: [{ v: 5, tol: 0.001, msg: 'Nicht aufrunden: 4 + 114/120 = 4,95 Jahre.' }] },
            { key: 't2', label: 'Amortisationsdauer Objekt 2', ans: 4.0, unit: 'Jahre', tol: 0.01 }
          ],
          solution: 'Nach Jahr 4 sind 426 T€ zurückgeflossen, Rest 114 T€. Im Jahr 5 fließen 120 T€ → T* = 4 + 114/120 = 4,95 Jahre. Objekt 2: 540/135 = 4,0 Jahre.'
        }
      ]
    },
    trainer: {
      title: 'Endlos-Trainer · Kostenvergleich',
      intro: 'Zufällige Maschinenkonstellationen – berechne Fixkosten und kritische Menge.',
      gen: function () {
        const a0a = (10 + Math.floor(Math.random() * 12)) * 1000;
        const a0b = a0a + (3 + Math.floor(Math.random() * 8)) * 1000;
        const n = 3 + Math.floor(Math.random() * 4);
        const i = [4, 5, 6, 8, 10][Math.floor(Math.random() * 5)] / 100;
        const ka = 2 + Math.floor(Math.random() * 4);
        const kb = ka - 1;
        const fa = (1 + Math.floor(Math.random() * 5)) * 500;
        const fb = fa + (2 + Math.floor(Math.random() * 6)) * 500;
        const mA = { acquisitionCost: a0a, residualValue: 0, usefulLife: n, interestRate: i, fixedOperatingCosts: fa, variableCostPerUnit: ka };
        const mB = { acquisitionCost: a0b, residualValue: 0, usefulLife: n, interestRate: i, fixedOperatingCosts: fb, variableCostPerUnit: kb };
        const rA = FIN.analyzeStaticMachine(mA), rB = FIN.analyzeStaticMachine(mB);
        const xk = FIN.criticalQuantity(mA, mB);
        return {
          prompt: '<b>Maschine A:</b> A₀ = ' + R(a0a, 0) + ' €, n = ' + n + ' J., i = ' + R(i * 100, 1) + ' %, K_Bfix = ' + R(fa, 0) + ' €, k_var = ' + ka + ' €. <b>Maschine B:</b> A₀ = ' + R(a0b, 0) + ' €, K_Bfix = ' + R(fb, 0) + ' €, k_var = ' + kb + ' €.',
          given: 'Fixkosten = K_Bfix + A₀/n + A₀/2 · i',
          fields: [
            { key: 'fa', label: 'Fixkosten A', ans: rA.totalFixedCosts, unit: '€', tol: 0.02 },
            { key: 'fb', label: 'Fixkosten B', ans: rB.totalFixedCosts, unit: '€', tol: 0.02 },
            { key: 'xk', label: 'Kritische Menge x_krit', ans: xk, unit: 'Stück', tol: 0.02 }
          ],
          solution: 'K_fix,A = ' + R(rA.totalFixedCosts) + ' €, K_fix,B = ' + R(rB.totalFixedCosts) + ' €, x_krit = (' + R(rB.totalFixedCosts) + ' − ' + R(rA.totalFixedCosts) + ')/(' + ka + ' − ' + kb + ') = ' + R(xk) + ' Stück.'
        };
      }
    }
  };

  /* ---------------- WELT 3 ---------------- */
  const W3 = {
    id: 'W3', no: 3, side: 'INV', color: '#a78bfa', icon: '⏳',
    title: 'Dynamische Investitionsrechnung',
    tag: 'Zeitwert-Zeitmaschine & IRR-Laser',
    sources: '3. Dynamische_Verfahren (1).pdf · Aufgaben mit Lösung · Aufgabendatei',
    briefing: [
      { h: 'Werkzeugkiste der Zeitmaschine', p: 'I: Abzinsungsfaktor (1+i)⁻ᵗ · II: Rentenbarwertfaktor Rbf = [1−(1+i)⁻ⁿ]/i (nur bei identischen Zahlungen!) · III: Annuitätenfaktor i/[1−(1+i)⁻ⁿ] zur Verteilung eines Kapitalwerts in gleiche Jahresraten.' },
      { h: 'Vorzeichen-Disziplin', p: 'Die Anfangsauszahlung wird immer negativ angesetzt (−A₀). In der Aufgabendatei fehlt bei Maschine 2 in Aufgabe 1a das Minuszeichen – ein klassischer Klausurfehler.' },
      { h: 'Kapitalwert vs. Interner Zinsfuß', p: 'Der Kapitalwert ist das absolute, der IRR das relative Maß. Bei unterschiedlichen Laufzeiten und impliziter Wiederanlageprämisse können beide Methoden zu gegensätzlichen Rankings führen – im Zweifel entscheidet der Kapitalwert.' },
      { h: 'Drei Sonderfälle des IRR', p: 'Eine Aus-/Einzahlung: i = (CF_t/A₀)^(1/t) − 1. Gleichmäßige Rente: Rbf = A₀/CF, dann Tabelleninterpolation. Ewige Rente: i = CF/A₀. Sonst Sekantenverfahren über den Strahlensatz.' }
    ],
    concept: {
      title: 'Zeitstrahl-Werkstatt',
      intro: 'Abzinsen, aber richtig: Wähle für jede Situation das passende Werkzeug.',
      items: [
        {
          kind: 'sort',
          title: 'Werkzeugkarten zuordnen',
          rounds: [{
            title: 'Welches Werkzeug passt?',
            categories: [{ id: 'DF', label: 'Abzinsungsfaktor (I)' }, { id: 'RBF', label: 'Rentenbarwertfaktor (II)' }, { id: 'ANF', label: 'Annuitätenfaktor (III)' }],
            cards: [
              { text: 'Cashflows 10.000 / 8.000 / 6.000 / 15.000 abzinsen', cat: 'DF', why: 'Ungleiche Zahlungen → jeder Cashflow einzeln abzinsen.' },
              { text: 'Vier Jahre lang konstante 10.000 € abzinsen', cat: 'RBF', why: 'Nominal identische Zahlungen = Rente.' },
              { text: 'Kapitalwert von 8.167,88 € in gleiche Jahresraten umrechnen', cat: 'ANF', why: 'Annuität = KW · Anf(i,n).' },
              { text: 'Barwert einer 20-jährigen Pensionszahlung von jährlich 60.000 €', cat: 'RBF', why: 'Gleichbleibende Rente.' },
              { text: 'Zahlungsreihe −A₀, +9.000, +15.000, +8.000, +16.000 bewerten', cat: 'DF', why: 'Ungleich → Einzelabzinsung.' }
            ]
          }]
        },
        {
          kind: 'quiz',
          title: 'Methodenkonflikt',
          questions: [
            { q: 'Maschine I hat einen höheren IRR, Maschine II den höheren Kapitalwert (bei 10 %). Welche Entscheidung ist theoretisch korrekt?', options: ['Der höhere IRR gewinnt', 'Der höhere Kapitalwert gewinnt', 'Beide sind gleichwertig'], a: 1, why: 'Der Kapitalwert maximiert den Vermögenszuwachs; der IRR unterstellt eine (oft unrealistische) Wiederanlage zum IRR.' },
            { q: 'Bei der Zahlungsreihe (+1.000, −1.500) lautet der IRR …', options: ['−50 %', '+50 %', 'nicht definiert'], a: 1, why: 'Rechnerisch +50 % – aber es handelt sich um eine Kreditaufnahme, deren Kapitalwert bei 10 % negativ ist (−364 €).' },
            { q: 'Wie viele Vorzeichenwechsel hat (−1.000, +2.500, −1.600)?', options: ['einer', 'zwei – die IRR-Methode kann mehrdeutig werden', 'keiner'], a: 1, why: 'Zwei Vorzeichenwechsel → bis zu zwei interne Zinssätze (Descartes-Regel); die IRR-Methode wird irreführend.' },
            { q: 'Der Rentenbarwertfaktor darf angewendet werden, wenn …', options: ['alle Zahlungen gleich hoch sind', 'alle Zahlungen positiv sind', 'der Zins konstant ist'], a: 0, why: 'Rbf setzt nominal identische Zahlungen voraus.' }
          ]
        }
      ]
    },
    lab: {
      title: 'Rechen-Labor · Kapitalwert, Annuität, IRR',
      intro: 'Die zentralen Rechenwege der Klausur.',
      tasks: [
        {
          id: 'w3t1',
          prompt: '<b>Aufgabe 1a.</b> i = 4 %. Maschine 1: A₀ = 27.000 €, CF 10.000/8.000/6.000/15.000. Maschine 2: A₀ = 35.000 €, CF 9.000/15.000/8.000/16.000.',
          given: 'KW = −A₀ + Σ CF<sub>t</sub> · (1+i)<sup>−t</sup>',
          fields: [
            { key: 'kw1', label: 'Kapitalwert Maschine 1', ans: 8167.88, unit: '€', tol: 0.05 },
            { key: 'kw2', label: 'Kapitalwert Maschine 2', ans: 8311.03, unit: '€', tol: 0.05, traps: [{ v: 43689, tol: 5, msg: 'Fehlendes Minuszeichen vor der Anfangsauszahlung: 35.000 € müssen als −A₀ abgezogen werden (Materialfehler auf Folie 8!).' }] }
          ],
          solution: 'KW₁ = 9.615,38 + 7.396,45 + 5.333,98 + 12.822,06 − 27.000 = 8.167,88 €. KW₂ = 8.653,85 + 13.868,34 + 7.111,97 + 13.676,87 − 35.000 = 8.311,03 €. Maschine 2 gewinnt knapp.'
        },
        {
          id: 'w3t2',
          prompt: '<b>Aufgabe 1b.</b> Nun sind alle Zahlungen t₁–t₄ konstant 10.000 €. Nutze den Rentenbarwertfaktor.',
          given: 'Rbf(4 %, 4) = 3,63',
          fields: [
            { key: 'rbf', label: 'Rentenbarwertfaktor', ans: 3.6299, unit: '', tol: 0.005 },
            { key: 'bw', label: 'Barwert der Rente', ans: 36298.95, unit: '€', tol: 2, traps: [{ v: 40000, tol: 1, msg: 'Nicht die Summe der Zahlungen bilden – die Rente muss abgezinst werden: 10.000 · Rbf = 36.298,95 € (Folie: gerundet 36.300 €).' }] },
            { key: 'kw1', label: 'KW Maschine 1', ans: 9298.95, unit: '€', tol: 2 },
            { key: 'kw2', label: 'KW Maschine 2', ans: 1298.95, unit: '€', tol: 2 }
          ],
          solution: 'Rbf = [1 − 1,04⁻⁴]/0,04 = 3,6299 ≈ 3,63 → BW = 36.298,95 € (Folie 36.300 €). KW₁ = 9.298,95 €, KW₂ = 1.298,95 € → jetzt gewinnt klar Maschine 1.'
        },
        {
          id: 'w3t3',
          prompt: '<b>Aufgabe 2 · Annuitäten.</b> Verteile die Kapitalwerte aus Aufgabe 1a (8.167,88 € und 8.311,03 €) auf 4 Jahre bei 4 %.',
          given: 'Ann = KW · i/[1−(1+i)<sup>−n</sup>]',
          fields: [
            { key: 'anf', label: 'Annuitätenfaktor', ans: 0.27549, tol: 0.0005 },
            { key: 'ann1', label: 'Annuität Maschine 1', ans: 2250.17, unit: '€', tol: 0.05 },
            { key: 'ann2', label: 'Annuität Maschine 2', ans: 2289.6, unit: '€', tol: 0.05 }
          ],
          solution: 'Anf = 1/3,6299 = 0,27549. Ann₁ = 2.250,17 €, Ann₂ = 2.289,60 € – die Rangfolge bleibt erhalten, weil beide Laufzeiten gleich sind.'
        },
        {
          id: 'w3t4',
          prompt: '<b>Aufgabe 3 · Profitabilitätsindex</b> bei Kapitalrationierung (20 T€ Budget, i = 6 %, Laufzeit 2 Jahre, alle Angaben in T€): P1 (A₀ 20; 10/70), P2 (20; 70/10), P3 (10; 35/5), P4 (10; 39/1), P5 (10; 5/5).',
          given: 'PI = KW / |A₀|   bzw. alternativ PI = BW / |A₀| (Kriterium &gt; 1)',
          fields: [
            { key: 'kw2', label: 'KW Projekt 2', ans: 54.94, unit: 'T€', tol: 0.02 },
            { key: 'pi4', label: 'PI Projekt 4', ans: 2.77, unit: '', tol: 0.01 },
            { key: 'pi5', label: 'PI Projekt 5', ans: -0.083, unit: '', tol: 0.01, traps: [{ v: 0.917, tol: 0.01, msg: 'Achtung: Bei dieser Definition wird durch |A₀| geteilt, nicht durch den Barwert. PI = KW/A₀ = −0,083.' }] },
            { key: 'best', type: 'choice', label: 'Projekt mit höchstem PI', options: ['Projekt 1', 'Projekt 2', 'Projekt 3', 'Projekt 4'], ans: 'Projekt 4' }
          ],
          solution: 'P1: KW 51,73 (PI 2,59) · P2: KW 54,94 (2,75) · P3: 27,47 (2,75) · P4: 27,68 (2,77) · P5: −0,83 (−0,083). P5 ist absolut nachteilig. Nach PI gewinnt P4, nach absolutem KW (einmalige Durchführung) P2.'
        },
        {
          id: 'w3t5',
          prompt: '<b>Aufgabe 4 · Interner Zinsfuß (Sekantenverfahren).</b> Maschine 1: A₀ = 27.000 €, CF 10.000/8.000/6.000/6.000. Erste Iteration zwischen i₁ = 3 % (KW = +1.071,28 €) und i₂ = 5 % (KW = −100,71 €).',
          given: 'i* = i₁ + KW₁ · (i₂ − i₁)/(KW₁ − KW₂)',
          fields: [
            { key: 'istar', label: 'i* nach der 1. Iteration', ans: 4.827, unit: '%', tol: 0.01 },
            { key: 'kw3', label: 'KW bei i*', ans: -3.29, unit: '€', tol: 0.15 }
          ],
          solution: 'i* = 0,03 + 1.071,28 · 0,02/1.171,99 = 4,827 %. KW(i*) ≈ −3,29 € (Folie: −3,23 € bei gerundetem i*). 2. Iteration zwischen 3 % und 4,827 % → IRR ≈ 4,82 %.'
        },
        {
          id: 'w3t6',
          prompt: '<b>Aufgabe 5 · Methodenvergleich.</b> Bei i = 10 %: KW Maschine II = 10.443,27 € (A₀ = 100.000 €, CF₃ = 147.000 €); IRR Maschine I = 14,49 %, IRR Maschine II = 13,70 %.',
          fields: [
            { key: 'irr', label: 'IRR Maschine II', ans: 13.7, unit: '%', tol: 0.02, hint: '(147.000/100.000)^(1/3) − 1' },
            { key: 'winner', type: 'choice', label: 'Welche Maschine ist nach der Kapitalwertmethode besser?', options: ['Maschine I', 'Maschine II'], ans: 'Maschine II' },
            { key: 'konflikt', type: 'choice', label: 'Warum widersprechen sich die Methoden?', options: ['Rechenfehler', 'Der IRR unterstellt Wiederanlage zum IRR und ist ein relatives Maß', 'Der Kapitalwert ignoriert das Risiko'], ans: 'Der IRR unterstellt Wiederanlage zum IRR und ist ein relatives Maß' }
          ],
          solution: 'Nach dem Kapitalwert gewinnt Maschine II (10.443,27 €), nach dem IRR Maschine I (14,49 % vs. 13,70 %). Ursache: unterschiedliche Kapitaleinsätze/Laufzeiten und die implizite Wiederanlageprämisse des IRR.'
        }
      ]
    },
    trainer: {
      title: 'Endlos-Trainer · Kapitalwert & IRR',
      intro: 'Zufällige Zahlungsreihen – Kapitalwert und interner Zinsfuß.',
      gen: function () {
        const a0 = (10 + Math.floor(Math.random() * 30)) * 1000;
        const i = [3, 4, 5, 6, 8, 10][Math.floor(Math.random() * 6)] / 100;
        const flows = [0, 1, 2, 3].map(() => (2 + Math.floor(Math.random() * 25)) * 1000);
        const kw = FIN.npv(a0, flows, i);
        const irr = FIN.irr(a0, flows);
        return {
          prompt: 'A₀ = ' + R(a0, 0) + ' €, Cashflows: ' + flows.map((f) => R(f, 0)).join(' / ') + ' €, Kalkulationszins i = ' + R(i * 100, 1) + ' %.',
          given: 'KW = −A₀ + Σ CF<sub>t</sub>(1+i)<sup>−t</sup>',
          fields: [
            { key: 'kw', label: 'Kapitalwert', ans: kw, unit: '€', tol: 1 },
            { key: 'vorteil', type: 'choice', label: 'Vorteilhaft?', options: ['Ja', 'Nein'], ans: kw > 0 ? 'Ja' : 'Nein' },
            { key: 'irr', label: 'Interner Zinsfuß (exakt)', ans: irr == null ? 0 : irr * 100, unit: '%', tol: 0.15 }
          ],
          solution: 'KW = ' + R(kw) + ' €, IRR = ' + (irr == null ? 'n. def.' : R(irr * 100) + ' %') + '. Vorteilhaft, wenn KW > 0 ⇔ IRR > i.'
        };
      }
    }
  };

  window.GAMEDATA_PART1 = [W1, W2, W3];
})();
