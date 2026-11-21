/* ============================================================
   src/data3.js – Welt 9: Aktien & Aktienbewertung (Kapitel 5)
   Erweiterungs-Slot: die Vorlesungsinhalte zu Kapitel 5 werden für
   Dezember 2026 / Januar 2027 erwartet. Die hier verwendeten Modelle
   (Dividendendiskontierung, Gordon-Growth, CAPM, KGV, Zweiphasenmodell)
   sind die Standard-Bewertungsmodelle und passen zur Gliederung.
   ============================================================ */
(function () {
  'use strict';
  const R = (x, d) => (x).toLocaleString('de-DE', { minimumFractionDigits: d === undefined ? 2 : d, maximumFractionDigits: d === undefined ? 2 : d });

  const W9 = {
    id: 'W9', no: 9, side: 'INV', color: '#c084fc', icon: '💠',
    title: 'Aktien & Aktienbewertung',
    tag: 'Bewertungs-Terminal & Gordon-Reaktor',
    sources: 'Kapitel 5 (Slot, Folien ab Dez. 2026) · Aktien-Grundlagen aus Finanzierungsteil Kap. 3.2 & 4. Anleihen (Vergleichsabschnitt)',
    briefing: [
      { h: 'Was eine Aktie wert ist', p: 'Der faire Wert einer Aktie ist der Barwert aller künftigen Zahlungen an die Aktionäre: Dividenden plus Verkaufserlös. Genau das ist das Dividendendiskontierungsmodell (DDM) – die Brücke von Kapitel 3 (Abzinsung) zu Kapitel 5.' },
      { h: 'Drei Bewertungswege', p: '1. Einperiodiges Modell / Barwert expliziter Dividenden. 2. Gordon-Growth für konstantes Wachstum: P₀ = D₁/(r − g). 3. Zweiphasenmodell: hohes Wachstum für n Jahre, danach ewiges Wachstum g₂ (Terminal Value am Ende der Detailphase).' },
      { h: 'Der Diskontierungszins kommt aus dem Risiko', p: 'CAPM: r = r_f + β·(r_m − r_f). Höheres Beta → höherer Zins → niedrigerer fairer Wert. Das verbindet Kapitel 5 mit der Portfoliotheorie aus Kapitel 1.' },
      { h: 'Kennzahlen der AG', p: 'Ergebnis je Aktie EPS = (Jahresüberschuss − Vorzugsdividende)/Anzahl Stammaktien · KGV = Kurs/EPS · Dividendenrendite = Dividende/Kurs · Nachhaltiges Wachstum g = Thesaurierungsquote × Eigenkapitalrendite.' }
    ],
    concept: {
      title: 'Bewertungs-Labor & Gordon-Reaktor',
      intro: 'Erst das Gespür für die Treiber, dann die Formel.',
      items: [
        {
          kind: 'sort',
          title: 'Aktienwert-Treiber',
          rounds: [{
            title: 'Was hebt den fairen Aktienwert – was drückt ihn?',
            categories: [{ id: 'UP', label: 'Erhöht P₀' }, { id: 'DOWN', label: 'Senkt P₀' }],
            cards: [
              { text: 'Erwartete Dividende D₁ steigt', cat: 'UP', why: 'P₀ = D₁/(r − g): höherer Zähler, höherer Wert.' },
              { text: 'Risikofreier Zins steigt', cat: 'DOWN', why: 'Über CAPM steigt r – der Nenner wächst, der Wert sinkt.' },
              { text: 'Beta des Unternehmens steigt', cat: 'DOWN', why: 'Höheres systematisches Risiko → höheres r → niedrigerer Wert.' },
              { text: 'Langfristige Wachstumsrate g steigt', cat: 'UP', why: 'Kleinerer Nenner (r − g) → deutlich höherer Wert.' },
              { text: 'Marktrisikoprämie sinkt', cat: 'UP', why: 'r_f + β·(r_m − r_f) sinkt → niedrigerer Diskontierungszins.' },
              { text: 'Gewinnwarnung senkt die künftigen Dividenden', cat: 'DOWN', why: 'Alle künftigen D sinken – der Barwert fällt.' }
            ]
          }]
        },
        {
          kind: 'order',
          title: 'Fundamentale Aktienbewertung',
          prompt: 'Ordne die Schritte der fundamentalen Bewertung (Klick = anhängen).',
          items: [
            { id: 'a', text: 'Dividenden (oder Free Cashflows) prognostizieren' },
            { id: 'b', text: 'Wachstumsphasen festlegen (explizit / ewig)' },
            { id: 'c', text: 'Diskontierungszins über CAPM bestimmen' },
            { id: 'd', text: 'Terminal Value am Ende der Detailphase berechnen' },
            { id: 'e', text: 'Alle Zahlungen auf t₀ abzinsen (= fairer Wert)' },
            { id: 'f', text: 'Mit dem Marktpreis vergleichen und Kauf-/Verkaufsentscheidung ableiten' }
          ],
          solution: 'Prognose → Phasen → Zins → Terminal Value → Abzinsung → Vergleich mit dem Marktpreis.'
        },
        {
          kind: 'quiz',
          title: 'Bewertungs-Check',
          questions: [
            { q: 'Eine Aktie zahlt D₁ = 3 € bei r = 10 % und g = 4 %. Wie hoch ist der faire Wert?', options: ['30 €', '50 €', '75 €'], a: 1, why: 'P₀ = 3/(0,10 − 0,04) = 50 €. Bei g = 6 % wären es 75 €.' },
            { q: 'Was passiert im Gordon-Modell, wenn g gegen r läuft?', options: ['Der Wert geht gegen unendlich – das Modell wird unbrauchbar', 'Der Wert geht gegen null', 'Nichts, das Modell ist stabil'], a: 0, why: 'Der Nenner (r − g) wird beliebig klein; deshalb gilt die Bedingung r > g.' },
            { q: 'Ein KGV von 25 bedeutet …', options: ['Dividendenrendite 25 %', 'Der Markt zahlt das 25-Fache des Jahresgewinns je Aktie', 'Kurs-Gewinn-Verhältnis von 2,5'], a: 1, why: 'KGV = Kurs/EPS – ein Vielfaches, keine Prozentgröße.' },
            { q: 'Bei der Berechnung des EPS für Stammaktien …', options: ['wird die Vorzugsdividende vom Jahresüberschuss abgezogen', 'wird die Vorzugsdividende addiert', 'bleibt sie unberücksichtigt'], a: 0, why: 'Der auf Stammaktien entfallende Gewinn ist um die Vorzugsdividende gekürzt.' },
            { q: 'Steigt der risikofreie Zins bei konstantem Beta, dann …', options: ['steigt der faire Aktienwert', 'sinkt der faire Aktienwert', 'bleibt er unverändert'], a: 1, why: 'r steigt → Diskontierung stärker → Barwert sinkt.' }
          ]
        }
      ]
    },
    lab: {
      title: 'Rechen-Labor · EPS, DDM, Gordon & CAPM',
      intro: 'Die Delizioso AG ist seit dem IPO börsennotiert – jetzt muss der CFO ihren Wert verteidigen.',
      tasks: [
        {
          id: 'w9t1',
          prompt: '<b>Ergebnis je Aktie &amp; KGV.</b> Für 2027 wird ein Jahresüberschuss von 12 Mio € erwartet. Es bestehen 4 Mio Stammaktien (Kurs 60 €) und 1 Mio Vorzugsaktien mit einer Vorzugsdividende von 0,50 € je Aktie. Die geplante Dividende je Stammaktie beträgt 2,00 €.',
          given: 'EPS = (Jahresüberschuss − Vorzugsdividende gesamt) / Anzahl Stammaktien · KGV = Kurs/EPS · Dividendenrendite = D/Kurs',
          fields: [
            { key: 'eps', label: 'Ergebnis je Stammaktie (EPS)', ans: 2.875, unit: '€', tol: 0.005, traps: [{ v: 3, tol: 0.005, msg: 'Die Vorzugsdividende (1 Mio × 0,50 € = 0,5 Mio €) muss vor der Division abgezogen werden: (12 − 0,5)/4 = 2,875 €.' }] },
            { key: 'kgv', label: 'Kurs-Gewinn-Verhältnis', ans: 20.87, unit: '×', tol: 0.02 },
            { key: 'dy', label: 'Dividendenrendite', ans: 3.33, unit: '%', tol: 0.02, traps: [{ v: 2.4, tol: 0.02, msg: 'Dividendenrendite = Dividende/Kurs = 2,00/60 = 3,33 %. (2,4 % wäre Dividende bezogen auf den Buchwert o. Ä.)' }] }
          ],
          solution: 'EPS = (12 − 0,5)/4 = 2,875 €; KGV = 60/2,875 = 20,87; Dividendenrendite = 2,00/60 = 3,33 %.'
        },
        {
          id: 'w9t2',
          prompt: '<b>Dividendendiskontierung (explizit).</b> Erwartete Dividenden: 2,00 € (t₁), 2,50 € (t₂), 3,00 € (t₃). Nach drei Jahren wird ein Verkaufskurs von 75 € erwartet. Kalkulationszins r = 8 %.',
          given: 'P₀ = Σ D_t/(1+r)^t + P_n/(1+r)^n',
          fields: [
            { key: 'pvdiv', label: 'Barwert der drei Dividenden', ans: 6.38, unit: '€', tol: 0.03, traps: [{ v: 7.5, tol: 0.01, msg: 'Nicht die Summe der Dividenden (7,50 €) ansetzen – jede Dividende wird mit ihrem eigenen Abzinsungsfaktor diskontiert.' }] },
            { key: 'pv', label: 'Fairer Aktienwert heute', ans: 65.92, unit: '€', tol: 0.05 }
          ],
          solution: 'BW Dividenden = 2/1,08 + 2,5/1,08² + 3/1,08³ = 1,85 + 2,14 + 2,38 = 6,38 €. Verkaufserlös: 75/1,08³ = 59,54 €. Fairer Wert = 6,38 + 59,54 = 65,92 €.'
        },
        {
          id: 'w9t3',
          prompt: '<b>Gordon-Growth.</b> Die Delizioso AG zahlt in t₁ eine Dividende von 3,00 €; der Diskontierungszins beträgt 10 %.',
          given: 'P₀ = D₁/(r − g)',
          fields: [
            { key: 'p4', label: 'Fairer Wert bei g = 4 %', ans: 50, unit: '€', tol: 0.02 },
            { key: 'p6', label: 'Fairer Wert bei g = 6 %', ans: 75, unit: '€', tol: 0.02 },
            { key: 'impl', label: 'Implizites Wachstum, wenn die Aktie bei 60 € notiert', ans: 5, unit: '%', tol: 0.02, hint: 'g = r − D₁/P₀' }
          ],
          solution: 'P₀ = 3/(0,10 − 0,04) = 50 €; bei g = 6 %: 3/0,04 = 75 €. Bei einem Kurs von 60 € steckt g = 0,10 − 3/60 = 5 % im Preis – der Markt preist also 5 % Wachstum ein.'
        },
        {
          id: 'w9t4',
          prompt: '<b>CAPM + Gordon.</b> Risikofreier Zins 3 %, erwartete Marktrendite 9 %, Beta 1,4. Die erwartete Dividende in t₁ beträgt 4,00 €, das langfristige Wachstum 3 %.',
          given: 'r = r_f + β·(r_m − r_f),  P₀ = D₁/(r − g)',
          fields: [
            { key: 'r', label: 'Eigenkapitalkostensatz (CAPM)', ans: 11.4, unit: '%', tol: 0.02, traps: [{ v: 9, tol: 0.02, msg: 'Die Marktrendite ist nicht der Eigenkapitalkostensatz: r = 3 % + 1,4 · (9 % − 3 %) = 11,4 %.' }] },
            { key: 'p', label: 'Fairer Aktienwert', ans: 47.62, unit: '€', tol: 0.05, traps: [{ v: 66.67, tol: 0.05, msg: 'Du hast mit r = 9 % gerechnet (4/0,06). Richtig ist r = 11,4 % → 4/(0,114 − 0,03) = 47,62 €.' }] },
            { key: 'sens', type: 'choice', label: 'Beta steigt auf 1,8 – was passiert?', options: ['Der faire Wert steigt', 'Der faire Wert sinkt', 'Der faire Wert bleibt gleich'], ans: 'Der faire Wert sinkt' }
          ],
          solution: 'r = 3 % + 1,4 · 6 % = 11,4 %. P₀ = 4/(0,114 − 0,03) = 47,62 €. Höheres Beta → höherer Zins → niedrigerer Wert.'
        },
        {
          id: 'w9t5',
          prompt: '<b>Zweiphasenmodell.</b> Dividende in t₁ = 2,00 €. In den Jahren 1–3 wächst sie mit 15 %, danach ewig mit 3 %. Diskontierungszins 9 %.',
          given: 'D_t+1 = D_t·(1+g₁) für t ≤ 3;  TV₃ = D₄/(r − g₂);  P₀ = Σ D_t/(1+r)^t + TV₃/(1+r)³',
          fields: [
            { key: 'd3', label: 'Dividende in t₃', ans: 2.645, unit: '€', tol: 0.005 },
            { key: 'tv', label: 'Terminal Value in t₃', ans: 45.41, unit: '€', tol: 0.05, traps: [{ v: 29.39, tol: 0.1, msg: 'Der Terminal Value wird mit der Dividende des Folgejahres D₄ gerechnet: D₄ = 2,645 · 1,03 = 2,724 € → TV₃ = 2,724/(0,09 − 0,03) = 45,41 €.' }] },
            { key: 'p0', label: 'Fairer Aktienwert heute', ans: 40.86, unit: '€', tol: 0.1 }
          ],
          solution: 'D₁ 2,00 → D₂ 2,30 → D₃ 2,645 → D₄ 2,724. TV₃ = 2,724/0,06 = 45,41 €. P₀ = 2/1,09 + 2,3/1,09² + (2,645 + 45,41)/1,09³ = 1,83 + 1,94 + 37,09 = 40,86 €.'
        },
        {
          id: 'w9t6',
          prompt: '<b>Nachhaltiges Wachstum.</b> Die Delizioso AG thesauriert 60 % des Gewinns und erzielt eine Eigenkapitalrendite von 12 %. Das KGV liegt bei 20, der Kurs bei 60 €, der Gewinn je Aktie bei 3,00 €.',
          fields: [
            { key: 'g', label: 'Nachhaltige Wachstumsrate', ans: 7.2, unit: '%', tol: 0.02, hint: 'g = b · ROE' },
            { key: 'fair', label: 'Fairer Wert bei 9 % Eigenkapitalkosten (Gordon, D₁ = 1,20 €)', ans: 66.67, unit: '€', tol: 0.05 },
            { key: 'verdict', type: 'choice', label: 'Bewertung gegenüber dem Kurs von 60 €', options: ['Die Aktie ist unterbewertet', 'Die Aktie ist überbewertet', 'Die Aktie ist fair bewertet'], ans: 'Die Aktie ist unterbewertet' }
          ],
          solution: 'g = 0,6 · 12 % = 7,2 %. P₀ = 1,20/(0,09 − 0,072) = 66,67 € > 60 € → rechnerisch unterbewertet (unter den Annahmen des Modells).'
        }
      ]
    },
    trainer: {
      title: 'Endlos-Trainer · Bewertungs-Mix',
      intro: 'KGV, Gordon und CAPM mit Zufallszahlen.',
      gen: function () {
        const kind = Math.floor(Math.random() * 3);
        if (kind === 0) {
          const ni = (5 + Math.floor(Math.random() * 40)) * 1e6;
          const shares = (1 + Math.floor(Math.random() * 9)) * 1e6;
          const pref = Math.floor(Math.random() * 3) * 0.5 * 1e6;
          const price = 20 + Math.floor(Math.random() * 80);
          const eps = FIN.eps(ni, pref, shares);
          return {
            prompt: 'Jahresüberschuss ' + R(ni / 1e6, 1) + ' Mio €, Vorzugsdividende gesamt ' + R(pref / 1e6, 1) + ' Mio €, ' + R(shares / 1e6, 1) + ' Mio Stammaktien, Kurs ' + price + ' €.',
            given: 'EPS = (JÜ − Vorzugsdividende)/Aktienzahl · KGV = Kurs/EPS',
            fields: [
              { key: 'eps', label: 'Ergebnis je Aktie', ans: eps, unit: '€', tol: 0.005 },
              { key: 'kgv', label: 'KGV', ans: price / eps, unit: '×', tol: 0.02 }
            ],
            solution: 'EPS = (' + R(ni / 1e6, 1) + ' − ' + R(pref / 1e6, 1) + ')/' + R(shares / 1e6, 1) + ' = ' + R(eps, 4) + ' €; KGV = ' + price + '/' + R(eps, 3) + ' = ' + R(price / eps, 2) + '.'
          };
        }
        if (kind === 1) {
          const d1 = 1 + Math.floor(Math.random() * 60) / 10;
          const r = (6 + Math.floor(Math.random() * 10)) / 100;
          const g = (1 + Math.floor(Math.random() * 5)) / 100;
          const p = FIN.gordon(d1, r, g);
          return {
            prompt: 'Erwartete Dividende D₁ = ' + R(d1, 2) + ' €, Diskontierungszins r = ' + R(r * 100, 1) + ' %, langfristiges Wachstum g = ' + R(g * 100, 1) + ' %.',
            given: 'P₀ = D₁/(r − g)',
            fields: [
              { key: 'p', label: 'Fairer Aktienwert', ans: p, unit: '€', tol: 0.05 }
            ],
            solution: 'P₀ = ' + R(d1, 2) + '/(' + R((r - g) * 100, 1) + ' %) = ' + R(p, 2) + ' €.'
          };
        }
        const rf = 1 + Math.floor(Math.random() * 4);
        const rm = 6 + Math.floor(Math.random() * 6);
        const beta = (5 + Math.floor(Math.random() * 15)) / 10;
        const r = FIN.capm(rf, beta, rm);
        const d1 = 2 + Math.floor(Math.random() * 40) / 10;
        const g = 1 + Math.floor(Math.random() * 3);
        const p = FIN.gordon(d1, r / 100, g / 100);
        return {
          prompt: 'r_f = ' + rf + ' %, r_m = ' + rm + ' %, β = ' + R(beta, 1) + '. Erwartete Dividende D₁ = ' + R(d1, 2) + ' €, Wachstum g = ' + g + ' %.',
          given: 'r = r_f + β·(r_m − r_f) · P₀ = D₁/(r − g)',
          fields: [
            { key: 'r', label: 'Eigenkapitalkostensatz', ans: r, unit: '%', tol: 0.02 },
            { key: 'p', label: 'Fairer Aktienwert', ans: p, unit: '€', tol: 0.05 }
          ],
          solution: 'r = ' + rf + ' + ' + R(beta, 1) + '·(' + rm + ' − ' + rf + ') = ' + R(r, 2) + ' %; P₀ = ' + R(d1, 2) + '/(' + R(r, 2) + ' − ' + g + ') = ' + R(p, 2) + ' €.'
        };
      }
    }
  };

  window.GAMEDATA_PART3 = [W9];
})();
